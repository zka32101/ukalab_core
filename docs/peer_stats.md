# 匿名集計「他にも頑張っている人がいる」（peer stats）

決定事項: `docs/DECISIONS.md` の「他にも頑張っている人がいる」機能。匿名の集計値だけ。個人情報は集めない。
採用は案1（今日の学習人数）・案2（同じ試験日の仲間）・案3（累計問題数と1人あたり中央値）・案5（連続日数の上位 %）。**100 人を超えるまで表示しない**。案6〜8は対象外。

この PR は「モデル/ロジック・取得インターフェース・読むだけの Firestore 実装・カード UI・文言」まで。**送信側の実装、ルールの適用、本番への書き込み、アプリへの組み込みは別 PR**。

## コード構成

| ファイル | 内容 |
|---|---|
| `lib/peer/peer_stats.dart`（純 Dart） | `PeerStatsSnapshot`（匿名の集計値）、`PeerStatsPolicy`（閾値・中央値・上位 %）、`PeerStatsView`（画面に出す値。閾値未満の項目は null） |
| `lib/peer/peer_stats_source.dart`（純 Dart） | `PeerStatsSource`（取得）、`PeerStatsSink` / `PeerContribution`（送信の形）、`PeerStatsSettings`（送信のオン/オフ） |
| `lib/peer/peer_stats_strings.dart` | `PeerStatsStrings`（ja・en）。`ExamCountdownStrings` と同じ流儀で `UkalabStrings` は変えない |
| `lib/ui/peer_stats/firestore_peer_stats_source.dart` | `PeerStatsSource` の Firestore 実装（`peer_summaries/{examId}` を読むだけ。失敗は null） |
| `lib/ui/peer_stats/peer_stats_card.dart` | `PeerStatsCard`。表示する項目が無ければ何も描画しない |

表示ルール（`PeerStatsPolicy`）:
- 閾値は項目ごとの母数が **100 を超える**（101 以上）こと。100 ちょうどは出さない。
  - 案1: `activeToday` / 案2: その試験日の人数 / 案3: `participants` / 案5: 連続日数分布の合計。
- 案5は上位 50% 以内のときだけ出す（下位の人を落ち込ませない）。同順位は「自分以上の人の割合」を切り上げ（最小 1%）。
- 中央値は偶数個なら中央 2 つの平均（切り捨て）。サーバ側の集計でも同じ定義を使う。

## Firestore のコレクション構造

```
peer_devices/{examId}/devices/{installId}   # 端末 → 書く（匿名の値のみ。1 端末 1 ドキュメントを日次で上書き）
peer_summaries/{examId}                     # サーバ → 書く、端末 → 読む（集計結果）
```

`peer_devices/.../{installId}`（端末が書く。**uid は使わない**）:
```
{
  day: "2026-10-14",        // 端末のローカル日付（最終送信日）
  studiedToday: true,
  streakDays: 12,           // 0〜3650
  totalQuestions: 340,      // 0〜1,000,000
  examDate: "2026-12-06",   // 任意。未設定は欠落
  updatedAt: <serverTimestamp>
}
```
`installId` はアプリ初回起動時に作る**ランダムな UUID**（端末ローカルのみ。Firebase Auth の uid・広告 ID・端末固有 ID とは無関係で、他データと結び付けない）。アプリを消すと別人として数えられるが、集計用途では許容する。

`peer_summaries/{examId}`（サーバだけが書く。`PeerStatsSnapshot.toJson` の形）:
```
{ asOf, activeToday, participants, totalQuestions, medianQuestions,
  streakCounts: {"1": 300, "2": 120, ...},   // 連続日数 → 人数（上限 365 に丸める）
  examDateCounts: {"2026-12-06": 240, ...} } // 人数が 100 以下の日付は書かない
```
サーバ側でも**人数が 100 以下の区分（試験日・連続日数の細かい区分）は要約に含めない**（多重の防御。端末側の閾値判定が壊れても漏れない）。

## セキュリティルール案（適用しない。`firebase/firestore.rules` は変更していない）

```
// 集計の要約: ログイン済み（匿名認証で可）なら読める。書けるのはサーバ（Admin SDK）のみ。
match /peer_summaries/{examId} {
  allow read: if signedIn() && examId in examIds();
  allow write: if false;
}

// 端末の匿名の値: 作成・更新のみ。読み取り・削除は不可（他人の値を読めない）。
match /peer_devices/{examId}/devices/{installId} {
  allow get, list, delete: if false;
  allow create, update: if signedIn()
    && examId in examIds()
    && installId.matches('^[0-9a-f-]{36}$')
    && request.resource.data.keys().hasOnly(['day','studiedToday','streakDays','totalQuestions','examDate','updatedAt'])
    && request.resource.data.keys().hasAll(['day','studiedToday','streakDays','totalQuestions','updatedAt'])
    && request.resource.data.day is string && request.resource.data.day.matches('^\\d{4}-\\d{2}-\\d{2}$')
    && request.resource.data.studiedToday is bool
    && request.resource.data.streakDays is int
    && request.resource.data.streakDays >= 0 && request.resource.data.streakDays <= 3650
    && request.resource.data.totalQuestions is int
    && request.resource.data.totalQuestions >= 0 && request.resource.data.totalQuestions <= 1000000
    && request.resource.data.updatedAt == request.time
    && (!('examDate' in request.resource.data)
        || request.resource.data.examDate.matches('^\\d{4}-\\d{2}-\\d{2}$'));
}
```
- 日次 1 回の制限はクライアント側（`day` が今日なら送らない）で行う。ルールでは `resource.data.updatedAt` から 20 時間以上空いていることを `update` の条件に足せる（検討）。
- なりすまし・水増し対策は **Firebase App Check（必須で併用）** と、ルールの範囲チェック。installId を偽装した水増しは完全には防げない（匿名・認証なしの集計の限界）。集計は「雰囲気を伝える」用途に留め、順位や報酬には使わない。
- 配備前に `firebase/test_rules.py` にケース（拒否: 読み取り・範囲外・余計なキー・他の examId。許可: 正常な create/update）を足す。

## 集計方法の案

- **案A（推奨）: 日次の Cloud Function（Cloud Scheduler、毎日 日本時間 5:00 頃）**
  `peer_devices/{examId}/devices` を走査し、`day` が当日の件数（activeToday）、全件数（participants）、`totalQuestions` の合計と中央値、`streakDays` の度数分布、`examDate` ごとの人数を数え、`peer_summaries/{examId}` に 1 ドキュメントで書く。端末は要約 1 ドキュメントを読むだけ（読み取り 1 回）。
  中央値は全件の並べ替えが要るため、Firestore の `count()` / `sum()` 集計クエリだけでは出せない。**参加者が数万人を超えるまでは走査で足りる**（走査の読み取り = 参加者数。1 日 1 回）。
  古い端末（`day` が 60 日より前）は参加者から外す。
- 案B: 端末が共有カウンタを加算する方式 → 中央値が出せず、改ざんの影響が大きいので**採らない**。
- 案C（規模が大きくなったら）: Firestore → BigQuery（Firebase Extension）に流し、BigQuery の定期クエリで集計して要約を書く。

## 送信側（アプリが日次カウントを送る）の提案

送信の実装は別 PR。この PR は `PeerStatsSink` / `PeerStatsSettings` のインターフェースだけ。

- **デフォルトは「オフ」を推奨**。理由: 子ども・学習者のデータを扱う、既存の同意管理（kit の `ConsentController`: 未回答は「同意なし」）と整合する、Apple の申告を最小にできる。
- 初回に、ホームのカード付近か設定で 1 回だけ説明つきで案内する（「匿名の学習人数に参加する」。送る内容を列挙: 連続日数・累計問題数・試験日・今日学習したか）。「参加しない」を選んでも**集計の表示は見られる**（見るだけは送信しない）。
- いつでも設定でオフにできる。オフにしたら以降は送らない。さらに `peer_devices` の自分のドキュメントを消せるようにするのが望ましいが、ルールが read/delete 禁止なので、削除は Cloud Function（installId 指定）で対応するか、`delete` を自分の installId 限定で許す設計を別途判断する。
- 端末ごと、1 日 1 回まで（学習後または次回起動時に、`day` が今日でないとき）。失敗は黙って次回に回す。
- 代替案: デフォルト「オン」＋初回に明示する方式は、参加数が早く 100 人を超える利点があるが、同意・申告の面で重くなる。**ここは判断が必要**。

## プライバシー・ストア申告への影響

送る値は、ランダムな installId・連続日数・累計問題数・試験日・当日学習の有無・日付だけ。名前・メール・Firebase Auth の uid・広告 ID・位置情報は送らない。ただし installId は端末を継続的に区別できるため、**Apple の「データの収集」では「識別子（デバイス ID など）」「使用状況データ（製品の操作）」に該当しうる**。

- App Store Connect の App Privacy: 送信を有効にして配備する版から、「使用状況データ（製品の操作）」と「識別子（デバイス ID）」を **「ユーザーに関連付けられない」「トラッキングに使用しない」** として申告する想定（installId を uid・メール・購入情報と結び付けない前提）。実際の申告は配備前にリリース担当が確認する。子ども向けカテゴリのアプリは、第三者への提供・分析の制約が厳しいため、特に要確認。
- Google Play の Data safety: 「アプリのアクティビティ」「デバイスまたはその他の ID」を収集、暗号化して送信、ユーザーが削除をリクエスト可能、と申告する想定。
- プライバシーポリシー: 「匿名の学習状況（連続日数・累計問題数・試験日）を集計して他の利用者の表示に使うこと」「ランダムな ID を使い個人を特定しないこと」「設定でいつでもやめられること」「集計は 100 人を超えるまで表示しないこと」を追記する。
- 送信を有効にしない版（この PR のみを取り込んだ版）では、データ収集は増えない（読むだけ・Firestore の要約 1 ドキュメントの取得）。
- 個人の特定を避ける設計: 100 人以下の区分は要約に含めない／端末の値は読めない／要約は人数・合計・中央値・度数分布だけ／installId は他データと結び付けない。
