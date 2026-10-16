# ローカルセッション向け引継ぎ: ストア・広告・課金の登録作業

状態: 2026-10-16 時点。このクラウドセッションは管理画面（AdMob / RevenueCat / App Store Connect / Play Console / Firebase / GitHub Secrets）を操作できないため、登録作業はローカル（本人の端末・アカウント）で行う。
関連: `docs/local_handover_monetization.md`（現状調査）、`docs/store_listing_drafts.md`（ストア文面）、`docs/expert_review_session_handover.md`（専門家レビュー）。

## 0. 守ること

- 本人特定につながる情報（氏名・連絡先・Drive の URL・端末名）をリポジトリ・PR・ストア文面に書かない。書き出すファイルのメタデータも消す。
- 実キー（RevenueCat 公開 SDK キー、署名鍵、keystore、`google-services.json` の実体など）は**コミットしない**。ビルド時に `--dart-define` か CI の Secrets で渡す。
- 課金・契約・審査提出・公開は、本人が画面で確認してから実行する（自動実行しない）。
- マージは「マージ」の指示があったときだけ。タグは指示があったときだけ。
- 試験名・団体名・商標の扱い、公式をうたう表現、合格保証は書かない（`docs/store_listing_drafts.md` の規則に従う）。

## 1. アプリごとの識別子（コードから確認できたもの）

| アプリ | Android applicationId | iOS バンドルID | 備考 |
|---|---|---|---|
| G検定 | `com.yourwish.ukalab.g_kentei` | `com.yourwish.ukalabGKentei` | Android の AdMob は本番形式ID登録済み |
| ITパスポート | `com.yourwish.ukalab.it_passport` | `com.yourwish.ukalabItPassport` | 広告IDはテスト用のまま |
| 情報セキュリティマネジメント | `com.yourwish.ukalab.infosecmanage` | `com.yourwish.ukalabInfosecmanage` | 広告IDはテスト用のまま。iOS は新IDで要登録 |
| 生成AIパスポート | `com.yourwish.ukalab.seisei_ai_passport` | 【要確認】`ios/Runner.xcodeproj/project.pbxproj` | 広告は未配線 |
| 簿記3級 | `com.yourwish.ukalab.boki3` | 【要確認】同上 | 広告は未配線 |
| 危険物乙4 | 【要確認】`android/` が無い | 【要確認】`ios/` が無い | まずプラットフォーム生成の方針を決める |
| 漢検（うかラボ 漢字検定） | `com.yourwish.ukarulab.kanji` | 【要確認】 | 綴りが他と異なり、旧ブランド名を含む。公開前に変更するか判断（変更できるのは未公開の間だけ） |

注: 「要確認」はローカルで該当ファイルを開いて確かめる。値を推測で登録しない。

## 2. 商品ID・価格・権利（コード上の現状）

6アプリ共通（漢検を除く）:

| 項目 | 値 |
|---|---|
| noads の商品ID | `<app>_noads`（例: `boki3_noads`, `g_kentei_noads`, `it_passport_noads`, `info_security_noads`, `seisei_ai_passport_noads`, `otsu4_noads`） |
| premium の商品ID | `<app>_premium`（同様） |
| 価格（コード上の仮値） | noads ¥480 / premium ¥1,500（買い切り） |
| RevenueCat の entitlement ID | `noads` / `premium` |
| 期間パス案 | 90日 ¥600、30日 ¥1,000（G検定の PRELAUNCH_CHECKLIST にある案。**未決**。Play での商品タイプは要確認） |

漢検は別系統: `premium-monthly` / `premium-yearly`（月額¥300 / 年額¥2,400）、`premium-plus-*`、entitlement は `ad_free` と `premium`。

価格・商品構成は未決（引継ぎ資料 D2/D3/D5）。**決めてから**ストア側に登録する。

## 3. 登録の順序（推奨）

1. 方針を決める（`local_handover_monetization.md` §2.2 の D1〜D10。特に D1 初回リリースに課金・広告を含めるか、D2 価格、D3 サブスクか買い切りか、D8 漢検の位置づけ）。
2. Apple Developer / Google Play Console にアプリを登録（バンドルID・applicationId は §1）。
3. RevenueCat: プロジェクト作成（構成は D10）→ ストア接続 → 商品登録 → entitlement `noads` / `premium` → Offering → 公開 SDK キー（Google / Apple）を発行。
4. AdMob: アプリ登録 → アプリID → 広告ユニット（バナー / インタースティシャル）。iOS は ATT・UMP 同意メッセージも設定。
5. 値の反映:
   - RevenueCat キー: ビルド時に `--dart-define=RC_GOOGLE_KEY=...` / `--dart-define=RC_APPLE_KEY=...`（CI は Secrets）。
   - AdMob アプリID: `AndroidManifest.xml`（`com.google.android.gms.ads.APPLICATION_ID`）と iOS `Info.plist`（`GADApplicationIdentifier`）。
   - 広告ユニットID: 各アプリの `_adUnitIds()`（本番IDをコミットするか注入するかは D9）。
6. Play Console: アプリ内アイテムの全言語訳（ja-JP）を先に入れる。デフォルト言語を ja-JP に変える前に必須。
7. ストアのAIコンテンツ申告・データセーフティ・年齢レーティング（`docs/store_listing_drafts.md` §8）。
8. 実機確認（下の §5）。

## 4. 既にコードに入っているもの（2026-10-16 マージ済み）

- 各アプリで、リリースビルドにテスト広告IDが残っていても起動を止めない処理（ITパス・情セマネ）。
- iOS 用 `RC_APPLE_KEY` の読み込み（ITパス・情セマネ・生成AI・簿記・乙4）。乙4は RevenueCat への切替自体を新規追加。
- 新しい問題形式（○×・空欄補充・説明から用語）の受け皿。フラグ `kNewQuestionTypesEnabled` は false。
- 注意: RevenueCat の初期化失敗時は、あえて何も捕まえていない（Fake に落ちると無料購入になるため）。
- 注意: 広告SDKのネイティブ側の設定不備（AdMob アプリID未設定など）は Dart の try/catch では防げない。実機で確認する。

## 5. 実機での確認項目

- 起動できること（リリースビルド、広告IDがテスト用でも落ちない）。
- 購入 → 広告が消える（noads）→ 機能が解放される（premium）。購入の復元。
- サンドボックス / テスターで購入できること。キャンセル・失敗時の表示。
- 広告が出る場所（結果画面・ホームのバナー、模擬試験結果のインタースティシャル）と頻度（最短3分・1日5回）。
- 漢検: 保護者ゲート、児童向け設定（子供向けタグ・最大G・非パーソナライズ）。

## 6. ローカルセッションに渡す依頼文（貼り付け用）

```
あなたはうかラボシリーズの登録作業の補助担当です。docs/local_handover_registration.md と docs/local_handover_monetization.md を読み、
次を順に支援してください。操作は私が画面で行い、あなたは手順の提示・値の確認・コード反映のPR作成を担当します。

- 登録に必要な値の一覧（アプリごと）を、コードを実際に開いて確認し、「要確認」を埋めた表にする。推測で値を書かない。
- 方針の未決事項（D1〜D10）を、私に選択肢で質問して決めさせる。
- 決まった値をコードへ反映するPR（広告アプリID・ユニットID・設定）を作る。実キーは書かない。
- 実機確認の結果を記録する。

守ること: 個人を特定する情報を書かない／実キーをコミットしない／課金や審査提出は私が確認してから／マージとタグは私の指示があったときだけ。
```
