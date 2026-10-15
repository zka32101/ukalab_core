# 匿名集計（peer stats）配備手順書（dev から prod まで）

対象: ukalab_core v0.74.0 の送信側一式（`firebase/firestore.rules`、`functions/`、`firebase/firebase.json`）。
仕様の正本は `docs/peer_stats.md`。この手順書はその「配備チェックリスト」を、実行できる粒度に展開したもの。
**この手順書の作業はすべて人が行う。自動化・CI からの配備はしない。**

## 0. 前提（リポジトリの実際の内容）

| 項目 | 値 | 出典 |
|---|---|---|
| プロジェクト別名 | `default`=`ukalab-dev` / `dev`=`ukalab-dev` / `prod`=`ukalab-prod` | `firebase/.firebaserc` |
| Firestore | `(default)`、asia-northeast1（変更不可） | `firebase/README.md` |
| Functions のソース | `functions/`（`firebase.json` の `source: "../functions"`）、codebase 名 `peer-stats` | `firebase/firebase.json` |
| predeploy | `npm --prefix "$RESOURCE_DIR" ci` と `npm --prefix "$RESOURCE_DIR" run build` | `firebase/firebase.json` |
| Node | 22（`engines.node`） | `functions/package.json` |
| 依存 | firebase-admin ^13、firebase-functions ^6 | `functions/package.json` |
| リージョン | `asia-northeast1` | `functions/src/index.ts` |
| 関数 | `aggregatePeerStats`（スケジュール `0 5 * * *`、`Asia/Tokyo`、timeout 540s、512MiB）、`erasePeerStats`（callable、`enforceAppCheck: true`、要ログイン） | `functions/src/index.ts` |
| ルール | `peer_summaries/{examId}` は read のみ（要ログイン）、`peer_devices/{examId}/devices/{installId}` は create/update のみ（update は前回 `updatedAt` から 20 時間以上） | `firebase/firestore.rules` |

共通ルール（`firebase/README.md`）:
- `firebase deploy` は必ず `--only` と `--project` を付ける。**`--force` は付けない**（共有プロジェクトで他アプリの関数などを消す事故を防ぐ）。
- 必ず dev で確認してから prod へ。
- コマンドは `firebase/` ディレクトリで実行する（`firebase.json` がそこにあるため）。

順序の理由: ルールと App Check が先（無防備な書き込み口を作らない）、次に Functions、次にアプリ、ポリシー・ストア申告はアプリ公開前に。

## 1. Firebase プロジェクトの用意

`ukalab-dev` と `ukalab-prod` は 2026-10-03 に作成済みで、Firestore（東京）とルールの配備も済み（`firebase/README.md`）。新規に作る場合や、状態を確認する場合は次を行う。

1. https://console.firebase.google.com/ で `ukalab-dev` / `ukalab-prod` を開く（所有アカウントは `firebase/README.md` 参照）。
2. Firestore が `(default)`・asia-northeast1 で存在することを確認する（場所は後から変更できない）。
3. Authentication →「始める」→ ログイン方法で**匿名**を有効にする（peer stats の書き込みは `signedIn()` が必須）。コンソールの「始める」からなら課金なしで進められる。
4. **課金プランを Blaze（従量課金）にする**。Cloud Functions のデプロイに必要。課金の有効化は人が行う。まず dev、prod は dev 確認後。
5. Functions のデプロイで必要になる API（Cloud Functions、Cloud Build、Artifact Registry、Cloud Scheduler、Eventarc、Cloud Run 等）は、初回の `firebase deploy` が有効化を案内する。権限エラーが出たら案内に従う。

## 2. App Check を有効化する（ルール・Functions の適用より前に準備）

peer stats は uid を使わない匿名の書き込みなので、なりすまし・水増し対策は App Check が前提（`docs/peer_stats.md`）。

1. コンソール → Build →「App Check」→「アプリ」で、Android アプリと iOS アプリをそれぞれ登録する。
   - Android: **Play Integrity** プロバイダ。Play Console 側で Play Integrity API をアプリに紐づけ、SHA-256 フィンガープリント（アップロード鍵と Play アプリ署名鍵の両方）を Firebase のアプリ設定に登録する。
   - iOS: **App Attest**（対応端末）、フォールバックとして **DeviceCheck**。Apple Developer 側で App Attest の Capability を有効にする。
2. アプリ側に `firebase_app_check` を組み込み、起動時に `FirebaseAppCheck.instance.activate(...)` を呼ぶ（別 PR、アプリごと）。開発中はデバッグプロバイダを使い、デバッグトークンをコンソールに登録する。**デバッグトークンは秘密情報。リポジトリに入れない。**
3. この時点では「適用（Enforce）」にしない。まず「メトリクス」で、アプリからの要求が App Check 付きで届いていること（検証済みの割合）を確認する。

## 3. firebase-tools の導入とログイン

```bash
node --version                 # 22 系（functions/package.json の engines に合わせる）
npm install -g firebase-tools
firebase --version
firebase login                 # ブラウザで所有アカウントにログイン
firebase projects:list         # ukalab-dev / ukalab-prod が見えること
```

プロジェクトの切り替え（`firebase/.firebaserc` の別名を使う）:

```bash
cd firebase
firebase use dev               # = ukalab-dev
firebase use                   # 現在のプロジェクトを確認
```

以降のコマンドは、事故防止のため `--project` を明示する（`firebase use` の状態に頼らない）。

## 4. 配備前のテスト（dev）

### 4.1 Functions のユニットテスト・型検査・ビルド

```bash
cd functions
npm ci
npm run typecheck
npm test                       # jest。EXAM_IDS と firestore.rules の examIds() の一致検査を含む
npm run build                  # tsc（lib/ に出力。deploy 時にも predeploy で実行される）
```

### 4.2 ルールのエミュレータテスト

CI の `firestore-rules-emulator` ジョブと同じ内容を `firebase/emulator_test/peer_rules.test.mjs` で確認する（ローカルで 19 件すべて期待どおり確認済みと `docs/peer_stats.md` にある）。
実行方法は `firebase/emulator_test/` 内のファイルと `.github/` のワークフローに従う（エミュレータには Java が必要）。**CI の `firestore-rules-emulator` が緑であることを配備の条件にする。**

### 4.3 Rules 検証 API でのテスト

```bash
cd firebase
gcloud auth login              # 未ログインの場合
python test_rules.py ukalab-dev
```

`docs/peer_stats.md` の注意: peer のケースは `request.time` とタイムスタンプを ISO 文字列で渡しているため、API 側の解釈は配備前にこのコマンドで確認すること。失敗した場合は配備を止めて原因を調べる。

## 5. ルールの配備（dev、その後 prod）

```bash
cd firebase
firebase deploy --only firestore:rules --project ukalab-dev
```

確認:
- コンソール → Firestore → ルール に peer_summaries / peer_devices のルールが載っている。
- 既存のルール（`users/{uid}/exams/...`、`feedback`、`exams/kanji_kentei`）が消えていない。

dev で問題がなければ prod:

```bash
firebase deploy --only firestore:rules --project ukalab-prod
```

## 6. Functions の配備（codebase `peer-stats`）

`firebase.json` の functions は配列形式で codebase 名 `peer-stats` を持つ。**codebase を指定して他のコードベースの関数に触れない**。

```bash
cd firebase
firebase deploy --only functions:peer-stats --project ukalab-dev
```

- predeploy で `npm ci` と `npm run build` が走る。
- 初回は API の有効化確認や、Artifact Registry のクリーンアップポリシー設定を求められることがある。案内に従う（`--force` で回避しない）。
- デプロイ後、コンソール → Functions に `aggregatePeerStats`（スケジュール）と `erasePeerStats`（callable）が asia-northeast1 に出ること。

### 6.1 スケジューラ（日本時間 5:00）の確認

`aggregatePeerStats` は `0 5 * * *`・`Asia/Tokyo` で毎日実行される。

1. Google Cloud コンソール → Cloud Scheduler（リージョン asia-northeast1）に `firebase-schedule-aggregatePeerStats-...` 形式のジョブが作られ、スケジュールが `0 5 * * *`、タイムゾーンが `Asia/Tokyo`（日本標準時）であること。
2. dev で手動実行して動作確認する（`gcloud scheduler jobs run <ジョブ名> --location asia-northeast1 --project ukalab-dev`、または Cloud Scheduler 画面の「強制実行」）。
3. Functions のログに `peer stats aggregated {...}` が出ること。
4. Firestore に `peer_summaries/{examId}` が書かれ、`asOf` が前日（JST）になっていること。
   - テストデータが 100 人以下の場合、項目は書かれない（`docs/peer_stats.md`「100 人以下の項目は書かない」）。**これは正常な挙動**。表示の動作確認には 101 人以上の端末データが要る。dev で確認するときは、テスト用の端末ドキュメントを Admin SDK／コンソールで用意し、確認後に削除する（本番には入れない）。
5. 実際に 5:00 JST に自動実行されたことを、翌日のログで確認する。

## 7. App Check の適用（Enforce）

アプリ側の App Check 対応版が配布され、メトリクスで検証済みの割合が十分に高いことを確認してから行う。**適用前に未対応の旧版が書けなくなる点に注意**（`docs/peer_stats.md`）。

1. コンソール → App Check → API で **Cloud Firestore** を「適用」にする。
2. 同じく **Cloud Functions** を適用にする。`erasePeerStats` はコード側で `enforceAppCheck: true` のため、App Check なしの呼び出しは拒否される。
3. まず dev で適用し、App Check 付きのアプリから書き込み・削除ができ、App Check なしの要求が拒否されることを確認する。
4. prod は dev 確認後、アプリの対応版が行き渡ってから適用する。

注意: Firestore に App Check を適用すると、同じプロジェクトを使う他の資格アプリ（`users/{uid}/exams/...` や `feedback`）の通信にも影響する。**全アプリが App Check 対応版になってから適用する**こと。

## 8. 削除 callable（`erasePeerStats`）の試験

入力は `{installId, examId?}`。`installId` は `^[0-9a-f-]{36}$` に合う UUID、`examId` は `functions/src/exams.ts` の `EXAM_IDS` 内。省略すると全資格から削除する。ログイン済み（匿名で可）かつ App Check 必須。

dev での手順:
1. テスト用の installId（UUID）で `peer_devices/{examId}/devices/{installId}` を 1 件作る（アプリの送信、またはコンソール／Admin SDK）。
2. App Check 付きのテストクライアントから callable を呼ぶ（例: Flutter の `cloud_functions` で `FirebaseFunctions.instanceFor(region: 'asia-northeast1').httpsCallable('erasePeerStats').call({'installId': ..., 'examId': ...})`）。アプリ側の `PeerStatsEraser` 実装は別 PR。
3. 期待結果: 戻り値 `{deleted: ...}` が削除件数を示し、該当ドキュメントが消える。
4. 異常系の確認:
   - 未ログイン → `unauthenticated`
   - installId の形式不正 → `invalid-argument`
   - 範囲外の examId → `invalid-argument`
   - App Check なし（適用後）→ 拒否
5. 削除対象が存在しない installId でもエラーにならないこと（`deleted` が 0 相当）。

## 9. ロールバック

| 状況 | 対応 |
|---|---|
| ルールに問題 | 直前のルールを `firebase/firestore.rules`（git の前の版）に戻して `firebase deploy --only firestore:rules --project <proj>`。コンソールのルール画面の履歴からも復元できる |
| 集計が壊れた・暴走 | Cloud Scheduler のジョブを**一時停止**（コンソール）。アプリは要約を読むだけなので、止めても影響は古い要約が出続けるだけ（`docs/peer_stats.md` 「障害時」） |
| Functions を撤去 | `firebase functions:delete aggregatePeerStats --region asia-northeast1 --project <proj>`（`erasePeerStats` も同様）。**他の codebase の関数を消さないよう、関数名とプロジェクトを必ず確認する。`--force` は付けない** |
| 誤った要約が書かれた | `peer_summaries/{examId}` を削除、または修正版を配備して次回実行を待つ（要約は毎回全置換） |
| 送信を止めたい | アプリ側の `kPeerStatsSettingsVisible` を false にした版を出す。サーバ側はルールで create/update を止めたい場合のみ、`peer_devices` の allow を false にしたルールを配備 |
| 端末データの一括消去 | 運用上必要な場合のみ、Admin SDK で `peer_devices/{examId}/devices` を削除。60 日超の古いデータは日次ジョブが自動削除する |

## 10. 配備後の運用確認

- Functions のログ `peer stats aggregated {...}` が毎日出ている。
- `peer_summaries/{examId}.asOf` が更新されている。
- 資格を追加したときは、`firestore.rules` の `examIds()` と `functions/src/exams.ts` の `EXAM_IDS` の**両方**に足し、ルール → Functions の順に配備する。
- コスト: 走査の読み取りは参加者数 / 日。数万人を超えたら BigQuery（案C）を検討。

## 11. ストア申告・ポリシーのチェックリスト（送信を有効にする版を出す前に済ませる）

下書きは `docs/peer_stats_privacy_draft.md`。公開は人の確認後。**送信を有効にしない版（読むだけ）ではデータ収集は増えない。**

- [ ] プライバシーポリシーに追記した: 匿名の学習状況（連続日数・累計問題数・試験日）を集計して他の利用者の表示に使う／ランダムな ID を使い個人を特定しない／設定でいつでもやめられる／100 人を超えるまで表示しない
- [ ] 上記ポリシーを公開し、URL がストア掲載情報と一致している
- [ ] App Store Connect の App Privacy: 「使用状況データ（製品の操作）」と「識別子（デバイス ID）」を、「ユーザーに関連付けられない」「トラッキングに使用しない」で申告（installId を uid・メール・購入情報と結び付けない前提）。リリース担当が最終確認
- [ ] 子ども向けカテゴリのアプリ（`Audience.kids`）は、第三者提供・分析の制約が厳しいため個別に確認した。送信は保護者ゲート通過時のみ
- [ ] Google Play の Data safety: 「アプリのアクティビティ」「デバイスまたはその他の ID」を収集、送信時に暗号化、ユーザーが削除をリクエスト可能、と申告
- [ ] 削除手段（アプリ内の「参加をやめる」と `erasePeerStats`）が実際に動くことを dev で確認した
- [ ] 名前・メール・Firebase Auth の uid・広告 ID・位置情報を送っていないことを再確認した
- [ ] 実機で、100 人を超えるまで表示されないことを確認した

## 12. 総合チェックリスト（上から順に）

- [ ] Firebase プロジェクト（dev / prod）、匿名認証、Blaze を確認した
- [ ] App Check を登録し（Play Integrity / App Attest・DeviceCheck）、メトリクスで検証済みを確認した
- [ ] firebase-tools を導入し `firebase login` した
- [ ] `functions` の typecheck / test / build が通った
- [ ] CI の `firestore-rules-emulator` が緑
- [ ] `python firebase/test_rules.py ukalab-dev` が通った
- [ ] ルールを dev に配備して確認した
- [ ] Functions（`functions:peer-stats`）を dev に配備し、スケジューラの手動実行で `peer_summaries` を確認した
- [ ] `erasePeerStats` の正常系・異常系を確認した
- [ ] App Check を dev で適用して確認した
- [ ] prod へ: ルール → Functions → App Check 適用（全アプリの対応版が行き渡ってから）
- [ ] アプリ側の組み込み（別 PR。`PeerStatsSender`、`PeerStatsEraser`、`kPeerStatsSettingsVisible`）
- [ ] ポリシー・ストア申告を公開（アプリ公開より前）
- [ ] 翌日以降、5:00 JST の自動実行をログで確認した
