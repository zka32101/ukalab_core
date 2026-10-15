# 匿名集計「他にも頑張っている人がいる」（peer stats）

決定事項: `docs/DECISIONS.md` の「他にも頑張っている人がいる」機能。匿名の集計値だけ。個人情報は集めない。
採用は案1（今日の学習人数）・案2（同じ試験日の仲間）・案3（累計問題数と1人あたり中央値）・案5（連続日数の上位 %）。**100 人を超えるまで表示しない**。案6〜8は対象外。

v0.73.0 まで: モデル/ロジック・取得インターフェース・読むだけの Firestore 実装・カード UI・文言。
v0.74.0（送信・集計の実装）: 送信側（`PeerStatsSender` ほか）、Cloud Functions（`functions/`）、Firestore ルール、ルールテスト、プライバシー下書き。
**配備（Firebase への適用・Functions のデプロイ・本番への書き込み）とアプリへの組み込みはまだ行っていない**。手順は末尾「配備チェックリスト」。
確定事項は `docs/DECISIONS.md` の「匿名集計 PeerStats の送信・集計」（2026-10-15）。

## コード構成

| ファイル | 内容 |
|---|---|
| `lib/peer/peer_stats.dart`（純 Dart） | `PeerStatsSnapshot`（匿名の集計値）、`PeerStatsPolicy`（閾値・中央値・上位 %）、`PeerStatsView`（画面に出す値。閾値未満の項目は null） |
| `lib/peer/peer_stats_source.dart`（純 Dart） | `PeerStatsSource`（取得）、`PeerStatsSink` / `PeerContribution`（送信の形）、`PeerStatsSettings`（送信のオン/オフ） |
| `lib/peer/peer_stats_strings.dart` | `PeerStatsStrings`（ja・en）。`ExamCountdownStrings` と同じ流儀で `UkalabStrings` は変えない |
| `lib/peer/peer_stats_sender.dart`（純 Dart） | `PeerStatsSender`（送信条件の判定と送信）、`PeerStatsGate`（保護者ゲートの抽象）、`InstallIdStore` / `InstallId`、`PeerSentDateStore`、`PeerStatsEraser`、`PeerDevicePayload`（書く値の形） |
| `lib/ui/peer_stats/firestore_peer_stats_sink.dart` | `FirestorePeerStatsSink`（`PeerStatsSink` の Firestore 実装）、`PeerDeviceWriter`（書き込みの抽象。テストでフェイクに差し替え） |
| `lib/ui/peer_stats/peer_stats_prefs.dart` | `SharedPrefsInstallIdStore`、`SharedPrefsPeerSentDateStore`、`ParentalPeerStatsGate`（kit の `requireParentalGate` を再利用） |
| `functions/` | Cloud Functions（TypeScript・firebase-functions v2）: `aggregatePeerStats`（毎日 JST 5:00）、`erasePeerStats`（callable） |
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
  day: "2026-10-14",        // 日本時間の暦日（最終送信日）
  streakDays: 12,           // 0〜3650
  totalQuestions: 340,      // 延べ回答数。0〜1,000,000
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

## セキュリティルール（`firebase/firestore.rules` に追加済み・**未配備**）

`peer_summaries/{examId}` は read のみ（ログイン済み）・write 禁止。`peer_devices/{examId}/devices/{installId}` は create / update のみ、get・list・delete は禁止。
当初案からの変更点:
- フィールドは `day`（日本時間の暦日）・`streakDays`・`totalQuestions`・`examDate?`・`updatedAt` のみ。`studiedToday` は廃止（「今日学習した人」は `day` で判定でき、送る値を減らせる）。
- `update` は **前回の `updatedAt` から 20 時間以上** 空いていることを要求（**採用**）。理由: ①クライアントの「日次 1 回」が壊れた・改造された場合の連打や書き込み課金の抑止、②installId の使い回しによる水増しの速度制限。24 時間でなく 20 時間にしたのは、毎日同じ時刻に学ぶ人の時刻のぶれ・端末時計のずれで翌日分が拒否されないようにするため。副作用: 夜遅くと翌日の早朝（20 時間未満）に 2 回学ぶと翌日分の送信は拒否される → 端末は失敗を握りつぶして次の学習後に再送する（その日の「今日学習した人」から漏れることがある）。許容する。
- `updatedAt == request.time`（サーバ時刻のみ）、`installId` は `^[0-9a-f-]{36}$`、`examId` は `examIds()` 内、値域: streakDays 0〜3650、totalQuestions 0〜1,000,000。

テスト:
- `firebase/emulator_test/peer_rules.test.mjs`（Firestore エミュレータ。CI の `firestore-rules-emulator` ジョブ。**ローカルでも 19 件すべて期待どおりを確認済み**）。
- `firebase/test_rules.py`（Rules 検証 API。gcloud ログインが必要。peer のケースを追加済み。`request.time` とタイムスタンプを ISO 文字列で渡しているため、API 側の解釈は配備前に `python test_rules.py ukalab-dev` で確認すること。実行は人が行う）。

- なりすまし・水増し対策は **Firebase App Check（必須で併用）** と、ルールの範囲チェック。installId を偽装した水増しは完全には防げない（匿名・認証なしの集計の限界）。集計は「雰囲気を伝える」用途に留め、順位や報酬には使わない。

## 集計方法（案A で確定・実装済み・**未デプロイ**）

- `functions/src/index.ts` の `aggregatePeerStats` が毎日 **日本時間 5:00**（Cloud Scheduler、`Asia/Tokyo`）に実行。`peer_devices/{examId}/devices` を走査し、`peer_summaries/{examId}` に `PeerStatsSnapshot.toJson` と互換の形で **全置換** で書く（`functions/src/aggregate.ts` が純粋ロジック）。
- 日付: 実行日（JST）の前日を `asOf` とし、`activeToday` は `day >= asOf` の人数（5:00 までに学習した当日分も 1 人として数える。各端末の `day` は最後の送信日だけなので二重には数えない）。
- `participants` / `totalQuestions`（合計）/ `medianQuestions`（偶数個は中央 2 つの平均を切り捨て）は有効な端末の全件。
- **100 人以下の項目は書かない**（表示側の `PeerStatsPolicy.minVisible` と同じ。`activeToday` は 100 以下なら省略、参加者ベースの 3 項目は `participants` が 100 以下なら省略、`examDateCounts` は 100 人以下の日付と過去の日付を省略）。書かれない項目は `fromJson` で 0 / 空になり、表示側でも非表示になる。
- `streakCounts`: 連続日数 1 以上、365 に丸め。**100 人以下の細かい区分は書かない代わりに、連続日数の高い側から隣の区分とまとめて 101 人以上の区分だけを作る**（キー = まとめた中で最小の連続日数）。合計は保たれ、表示側の「自分以上の割合」は区分の境界ではやや控えめ（実際より下位）に出る（過大に出ることはない）。全体で 100 人以下なら空。
- 古い端末: `day` が実行日から **60 日以上前** は集計から外し、同じジョブで**物理削除**。値が不正なドキュメントも削除。未来すぎる日付（実行日+2 日以降）は集計から外す。
- 削除: callable `erasePeerStats`（`{installId, examId?}`、`examId` 省略で全資格）。**App Check 必須（`enforceAppCheck: true`）かつログイン済み**。installId は推測不能なランダム UUID で、端末だけが知る。アプリ側は `PeerStatsEraser` を実装して呼ぶ（core は `cloud_functions` に依存しないため、実装はアプリ側）。
- 案B（共有カウンタ）は採らない。案C（BigQuery）は参加者が数万人を超えたら検討。走査の読み取りは参加者数（1 日 1 回）。`EXAM_IDS`（`functions/src/exams.ts`）は `firestore.rules` の `examIds()` と同じで、テストで一致を検査している。**資格を足したら両方に足す**。

## 送信側（実装済み）

- **既定はオフ（オプトイン）**。`PeerStatsSettings`（アプリ側の `SharedPrefsPeerStatsSettings`、`kPeerStatsSettingsVisible` フラグ）。参加しなくても集計の表示は見られる（読むだけ）。
- **年少者（`Audience.kids`）**: 設定で「参加する」をオンにするとき `gate.request()`（保護者ゲート）を通し、通らなければオンにしない。送信のたびには `gate.isAllowed()`（ダイアログなし）で確認する。オフにしたら `gate.revoke()`。成人向けは `NoPeerStatsGate`。
- **保護者ゲートの再利用**: `app_common_kit` v3.11.0 に `requireParentalGate`（`package:app_common_kit/parental_gate.dart`）が**既にある**ので、`ParentalPeerStatsGate(contextProvider: () => navigatorKey.currentContext)` でそのまま使う。core は kit に依存済みなので新しい依存は無い。
- **送信条件**（`PeerStatsSender.maybeSend`）: ①オプトインON ②ゲート通過済み ③当日（日本時間）未送信（試験ごと）。学習を 1 件記録した後に呼ぶ（起動時には呼ばない）。失敗は握りつぶし、送信日を記録しないので次回また試す。
- 値: `streakDays` = kit の `loadCurrentStreak()`（前日まで続いていれば数え、2 日以上空いたら 0）、`totalQuestions` = 延べ回答数、`examDate`（任意）。日付はすべて日本時間の暦日。※kit の連続日数は端末のローカル日付で数えるため、日本時間以外の端末では日付の切れ目がずれる（日本向けアプリのため許容）。
- 書く内容は `day / streakDays / totalQuestions / examDate? / updatedAt` のみ。installId は `SharedPrefsInstallIdStore`（端末ローカル。アプリ削除で消える）。

### アプリ側の組み込み例（別 PR・フラグ有効化時）

```dart
final sender = PeerStatsSender(
  settings: SharedPrefsPeerStatsSettings(),            // 既存（既定OFF）
  gate: ParentalPeerStatsGate(contextProvider: () => navigatorKey.currentContext), // 成人向けは const NoPeerStatsGate()
  sink: FirestorePeerStatsSink(installIdStore: SharedPrefsInstallIdStore()),
  sentDates: SharedPrefsPeerSentDateStore(),
);
// 学習を記録した後
await sender.maybeSend(examId: 'fe', streakDays: await loadCurrentStreak(), totalQuestions: total, examDate: examDate);
```

## プライバシー・ストア申告への影響

送る値は、ランダムな installId・連続日数・累計問題数・試験日・当日学習の有無・日付だけ。名前・メール・Firebase Auth の uid・広告 ID・位置情報は送らない。ただし installId は端末を継続的に区別できるため、**Apple の「データの収集」では「識別子（デバイス ID など）」「使用状況データ（製品の操作）」に該当しうる**。

- App Store Connect の App Privacy: 送信を有効にして配備する版から、「使用状況データ（製品の操作）」と「識別子（デバイス ID）」を **「ユーザーに関連付けられない」「トラッキングに使用しない」** として申告する想定（installId を uid・メール・購入情報と結び付けない前提）。実際の申告は配備前にリリース担当が確認する。子ども向けカテゴリのアプリは、第三者への提供・分析の制約が厳しいため、特に要確認。
- Google Play の Data safety: 「アプリのアクティビティ」「デバイスまたはその他の ID」を収集、暗号化して送信、ユーザーが削除をリクエスト可能、と申告する想定。
- プライバシーポリシー: 「匿名の学習状況（連続日数・累計問題数・試験日）を集計して他の利用者の表示に使うこと」「ランダムな ID を使い個人を特定しないこと」「設定でいつでもやめられること」「集計は 100 人を超えるまで表示しないこと」を追記する。
- 送信を有効にしない版（この PR のみを取り込んだ版）では、データ収集は増えない（読むだけ・Firestore の要約 1 ドキュメントの取得）。
- 個人の特定を避ける設計: 100 人以下の区分は要約に含めない／端末の値は読めない／要約は人数・合計・中央値・度数分布だけ／installId は他データと結び付けない。

## 未決事項（確定済み）

| 項目 | 結論 |
|---|---|
| 送信の既定 | オフ（オプトイン） |
| 年少者 | 保護者ゲート通過時のみ送信可 |
| 集計 | 案A（日次 Cloud Function、JST 5:00） |
| 削除 | callable（installId 指定）＋ 60 日超の物理削除 |
| 申告・ポリシー | 下書き（`docs/peer_stats_privacy_draft.md`）。公開は人の確認後 |
| 値 | 延べ回答数、連続日数は日本時間の暦日 |

## 運用

- 集計が止まっていないか: Cloud Functions のログ（`peer stats aggregated {...}`）と `peer_summaries/{examId}.asOf` を確認。止まっても表示は前回の要約のまま（古い `asOf` は UI 側で扱わない。必要なら別途判断）。
- 資格の追加: `firestore.rules` の `examIds()` と `functions/src/exams.ts` の `EXAM_IDS` の両方に足し、ルール → Functions の順に配備。
- 削除依頼（利用者から）: アプリの「参加をやめる」でオフ → `erasePeerStats` を呼ぶ。アプリ削除のみの場合は 60 日で自動的に外れて削除される。
- コスト: 走査の読み取り = 参加者数 / 日。数万人を超えたら案C を検討。
- 障害時: Functions を無効化しても、アプリは要約を読むだけなので影響しない（古い要約が出続ける）。

## 配備チェックリスト（**この PR では何も配備しない**。上から順に、人が行う）

Functions は Blaze（従量課金）が必要。まず `ukalab-dev` で確認してから `ukalab-prod`。`firebase deploy` は必ず `--only` と `--project` を付け、`--force` は付けない。

1. Firebase プロジェクトを用意（`ukalab-dev` / `ukalab-prod`。Authentication の匿名ログイン有効、Blaze 課金）
2. **App Check を有効化**（Play Integrity / App Attest・DeviceCheck）。アプリに App Check を組み込み、Firestore と Functions を「適用（enforce）」にする。※適用前に未対応の旧版が書けなくなる点に注意
3. ルールのテスト: CI の `firestore-rules-emulator` が通っていること。`python firebase/test_rules.py ukalab-dev`
4. ルールを適用: `firebase deploy --only firestore:rules --project ukalab-dev`（その後 prod）
5. Functions をデプロイ: `firebase deploy --only functions:peer-stats --project ukalab-dev`（その後 prod）。スケジューラの初回実行を `gcloud scheduler jobs run` などで確認し、`peer_summaries` が書かれることを確認（dev で）
6. アプリ側: `kPeerStatsSettingsVisible` を true にし、`PeerStatsSender` を組み込む（別 PR。年少者向けアプリは `ParentalPeerStatsGate`）。削除の `PeerStatsEraser` もアプリ側で実装
7. プライバシーポリシーとストア申告を更新・公開（`docs/peer_stats_privacy_draft.md` を人が確認してから）。**6 の版を出す前に済ませる**
8. 100 人を超えるまで表示されないことを実機で確認

順序の理由: ルールと App Check が先（無防備な書き込み口を作らない）→ Functions → アプリ → ポリシー・申告は公開前に。

