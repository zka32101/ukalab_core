# 課金・広告 ローカル引継ぎ資料

状態: 引継ぎ用の調査メモ（2026-10-16 時点。公開物ではありません）
目的: 課金（アプリ内購入）と広告の本実装を、ローカル環境で進めるための現状・未決事項・手順の整理。
位置づけ: 調査のみ。コード・ストア設定は何も変更していません。法的助言ではありません（法域の話は「確認したい問い」として書いています）。

## 0. 読み方

| 印 | 意味 |
|---|---|
| 【確認済】 | 指定したリポジトリのファイルを実際に読んで確認した事実。パスを併記 |
| 【推定】 | 他アプリの構成や一般的な仕様からの推測。実装前に必ず確認 |
| 【TODO】 | 調査時点で不明。決めるか、ローカルで確かめる |

調査した版（各リポジトリの先頭コミット7桁）:

| 対象 | リポジトリ | 版 |
|---|---|---|
| 漢検 | `ukalab_kanken` | 6652692 |
| G検定 | `ukalab-g-kentei`（ハイフン版。転送先は `ukalab_g_kentei`） | 202f8d9 |
| 生成AIパスポート | `ukalab_seisei_ai_passport` | 2c17c1e |
| 簿記3級 | `ukalab_boki` | 33ed793 |
| 危険物乙4 | `ukalab_otsu4` | ec20ce4 |
| ITパスポート | `ukalab_it_passport` | f8eec29 |
| 情報セキュリティマネジメント | `ukalab_infosecmanage` | 2b6d02f |
| 共通（本リポジトリ） | `ukalab_core` v0.75.0 | c1ea5c0 |
| 共通基盤 | `app_common_kit` v3.11.0 | 797dd99 |

注: 他のブランチ・PR で調査後に変わっている可能性があります。ローカルで最新の `main` を取り直してから作業してください。

## 1. 現状（何がコードにあるか）

### 1.1 共通部品（`app_common_kit` v3.11.0）

すべて【確認済】。パスは `app_common_kit` 内。

| 部品 | パス | 内容 |
|---|---|---|
| 権利管理の抽象 | `lib/entitlement/entitlement_service.dart` | `EntitlementService`（`purchase` / `offers` / `purchaseOffer` / `restore` / `logIn` / `logOut`）。`BeforePurchase` フックで購入前の確認（保護者ゲートなど）を差し込める |
| 状態 | `lib/entitlement/entitlement_state.dart` | `EntitlementIds`（既定の権利名は `noads` と `premium`）、`EntitlementState`（`hasNoAds` / `hasPremium` / `premiumExpiresAt`、`adsHidden` は noads または premium で true）、`PurchaseOutcome`（success / cancelled / blockedByGate / failed） |
| 偽実装 | `lib/entitlement/fake_entitlement_service.dart` | `FakeEntitlementService`。テスト・プレビュー用。`availableOffers` と `grantOnPurchase` で購入結果を模擬、`restorable` で復元を模擬 |
| RevenueCat 実装 | `lib/entitlement/revenuecat_entitlement_service.dart` | `RevenueCatEntitlementService.init(publicSdkKey:, ...)`。コメントに「公開SDKキーは引数で渡す（コミットしない）」「期間パス（30日/90日）は非更新型、買い切りは非消耗型」 |
| Riverpod 配線 | `lib/entitlement/entitlement_provider.dart` | `entitlementServiceProvider`（既定は未実装で例外。`ProviderScope.overrides` で差し込む）、`entitlementStateProvider`、`adsHiddenProvider` |
| 購入欄 UI | `lib/entitlement/purchase_section.dart` | `PurchaseSection`（商品一覧と価格ボタン、購入の復元ボタン） |
| 広告ゲート | `lib/ads/ad_gate.dart` | `AdGate.init(config:, adsHidden:, ...)`。noads / premium の間は SDK を初期化しない。インタースティシャルの契機は `sessionEnd` と `mockExamResult` のみ、バナーの場所は `home` / `result` / `weakDrill` のみ（`lib/ads/ad_rules.dart`） |
| 広告ルール | `lib/ads/ad_rules.dart` | 最短3分間隔・1日5回（暫定）。`AdUnitIds.assertNoTestIdsInRelease` が、リリースビルドで Google のテスト広告ID（接頭辞 `ca-app-pub-3940256099942544/`）を使うと `StateError` を投げる。`AdConfig` に `childDirected` / `maxAdContentRating` / `nonPersonalizedAds` |
| 広告バックエンド | `lib/ads/google_ads_backend.dart` | `google_mobile_ads` 実装。初期化時に UMP の同意情報更新と `loadAndShowConsentFormIfRequired` を実行、`canRequestAds` が false なら広告を出さない。児童向けタグと under-age-of-consent は `childDirected` に連動 |
| 同意管理 | `lib/consent/consent.dart` | `ConsentController`（analytics / crashReports / personalizedAds）、`adConfigWithConsent`。コメントに「同意が必要な範囲は法域で違う。専門家の確認を経て決める」 |
| 保護者ゲート | `lib/parental_gate.dart` | `requireParentalGate` / `parentalGateBeforePurchase(navigatorKey)`（kit README） |
| 依存 | `pubspec.yaml` | `purchases_flutter: ">=9.0.0 <11.0.0"`、`google_mobile_ads: ">=5.3.1 <10.0.0"` |

README（`app_common_kit/README.md`）の「機能3: 権利管理」「機能4: 広告ゲート」に使用例あり。例の `entitlement.purchase('noads_480')` は書き方の例で、実在の商品IDではありません。

`ukalab_core`（本リポジトリ）の課金関連:

| 部品 | パス | 内容 |
|---|---|---|
| プレミアム機能一覧 | `lib/policy/premium_features.dart` | `PremiumFeature`: `weakDrill`（弱点集中ドリルと原因別集計）、`examEveMode`（試験直前モード）、`tenMinutePlan`、`historyExport`（CSV/PDF）、`mockExamHistory`（成長グラフ）、`customMockExam`、`readingReadAloud`。`canUsePremiumFeature(feature, isPremium:)` は premium なら true（noads のみは false） |
| 無料枠 | `lib/policy/free_tier.dart` | `FreeTierLimits.standard`（暫定。模擬試験は月1回、苦手分析は3分野、復習は1日10問、自動生成問題は1日10問）。コメントに「premium でない人（noads のみを含む）が対象」「値は暫定」 |
| 回数制限 | `lib/policy/usage_quota.dart` | `UsageQuota`（本書では中身を未確認。`FreeTierLimits` から使用） |
| README | `README.md` 「無料枠とプレミアムの線引き」「まだ入っていないもの」 | 「課金・広告の組み込み」は未実装と明記 |

【確認済】`ukalab_core` 自体に `PremiumFeature` を使う画面は無く、判定は各アプリ側が `canUsePremiumFeature` を呼ぶ形。

### 1.2 アプリ別の状態（要約）

| アプリ | 権利管理 | 広告 | 画面（購入・復元） | 商品ID（コード上） |
|---|---|---|---|---|
| 簿記3級 | 本物 RevenueCat（Android かつ `RC_GOOGLE_KEY` 指定時）／それ以外は Fake | **未配線**（`AdGate` を使っていない） | 設定タブに `PurchaseSection`（購入と復元） | `boki3_noads` / `boki3_premium` |
| G検定 | 同上 | **配線済み**（AdGate）。Android リリースのみ本番形式のユニットID | 設定タブに自前の購入欄と復元ボタン | `g_kentei_noads` / `g_kentei_premium` |
| ITパスポート | 同上 | 配線済み。**全ビルドがテストID** | 【推定】G検定と同構成（設定画面は未読） | `it_passport_noads` / `it_passport_premium` |
| 情報セキュリティマネジメント | 同上 | 配線済み。**全ビルドがテストID** | 【推定】G検定と同構成（設定画面は未読） | `info_security_noads` / `info_security_premium` |
| 生成AIパスポート | 同上 | **未配線** | 【TODO】設定画面は未読 | `seisei_ai_passport_noads` / `seisei_ai_passport_premium` |
| 危険物乙4 | **Fake のみ**（RevenueCat への切替コードも無い） | **未配線** | 【TODO】設定画面は未読 | `otsu4_noads` / `otsu4_premium` |
| 漢検 | **独自ラッパー `PurchasesService`**（RevenueCat。SDKキーがコードに直書き） | 配線済み（`AdService`、児童向け設定）。リリースのみ本番形式のユニットID | 専用ペイウォール `paywall_screen.dart`（保護者ゲート付き、復元ボタン） | `premium-monthly` / `premium-yearly`、`premium-plus-monthly` / `premium-plus-yearly` |

根拠（すべて【確認済】）:

- 簿記: `ukalab_boki/lib/main.dart`（`_rcGoogleKey`、`_useRevenueCat`、`FakeEntitlementService` の `availableOffers`、`entitlementServiceProvider.overrideWithValue`、`PurchaseSection` を設定タブへ）。`AdGate` の呼び出しは `main.dart` に無い。
- G検定: `ukalab-g-kentei/lib/main.dart`（`_adUnitIds()`、`AdGate.init`、`adGateProvider.overrideWithValue`）、`lib/screens/settings_screen.dart`（購入・復元）。
- ITパス: `ukalab_it_passport/lib/main.dart`。情セマネ: `ukalab_infosecmanage/lib/main.dart`。
- 生成AI: `ukalab_seisei_ai_passport/lib/main.dart`（`AdGate` なし）。`docs/release_prep_log.md` §6 に「広告SDK（AdMob）: 未配線」。
- 乙4: `ukalab_otsu4/lib/main.dart`（`FakeEntitlementService` 直接生成。`AdGate` なし）。
- 漢検: `ukalab_kanken/lib/main.dart`、`lib/services/purchases_service.dart`、`lib/services/purchase_tiers.dart`、`lib/services/ad_service.dart`、`lib/screens/paywall_screen.dart`。

#### 依存の固定（pubspec）

- 簿記・G検定・漢検・乙4: `app_common_kit` は `ref: v3.11.0`、`ukalab_core` は `ref: v0.75.0`（各 `pubspec.yaml`）。
- ITパス・情セマネ・生成AI: `pubspec.yaml` は本調査で未読【TODO】。
- 簿記の `pubspec.yaml` は `purchases_flutter` と `google_mobile_ads` を直接も宣言している。`ukalab_boki/docs/common_kit_notes.md` を pubspec のコメントが参照しているが、調査時点の `docs/` にそのファイルは無い。
- 漢検は `purchases_flutter: ^10.13.2`、`google_mobile_ads: ^5.0.0` を直接宣言（`ukalab_kanken/pubspec.yaml`）。kit の許容範囲（上記）と重なる範囲。

### 1.3 商品ID・価格（コード上と文書上）

コード上（6アプリ共通の型）【確認済】: 各アプリの `main.dart` の `FakeEntitlementService`。

| 項目 | 値 | 出典 |
|---|---|---|
| noads の表示名・価格 | 「広告非表示」 ¥480 | 各アプリ `lib/main.dart`（Fake の `availableOffers`） |
| premium の表示名・価格 | 「プレミアム（広告非表示＋追加機能）」 ¥1,500 | 同上 |
| 付与される権利 | noads → `hasNoAds`、premium → `hasPremium` | 同上（`grantOnPurchase`） |

コメントに「価格（仮サービス側）は競合調査を踏まえた暫定値で、運営者確認が必要（決定14）」とある（各 `main.dart`）。決定14 の本文は本調査の範囲外【TODO】。

文書上の価格【確認済】:

- `ukalab-g-kentei/PRELAUNCH_CHECKLIST.md`: 「noads ¥480、premium ¥600/90日・¥1,000/30日・¥1,500買い切り」を運営者が最終確認する、とある（決定14）。つまり **期間パス（90日 ¥600、30日 ¥1,000）の案がある**が、コード上の Fake は買い切り2商品のみ。
- `ukalab_it_passport/PRELAUNCH_CHECKLIST.md`: 「noads ¥480・premium ¥1,500」の最終確認、商品ID `it_passport_noads` / `it_passport_premium`。
- 漢検（`ukalab_kanken/README.md`）: 「サブスク定額・広告ゼロ（¥300/月、単一級課金）」。`lib/services/purchases_service.dart` のコメントに、月額¥300・年額¥2,400（広告なし）、プレミアム（準1級・1級＋広告なし）は「価格は仮に月額¥480」。**漢検だけ他の6アプリと課金モデルが違う**（サブスク＋広告なしの二段階、買い切りではない）。漢検の README は「広告ゼロ」とも書くが、コードは広告を配信する構成（`ad_service.dart`）で、方針が食い違っている【確認済】。
- 乙4・生成AI・情セマネ・簿記: 上記以外の価格文書は未発見【TODO】。

RevenueCat 側の設定（コメントや文書から読み取れるもの）【確認済】:

- 権利ID: kit 既定は `noads` / `premium`。**漢検だけ**は RevenueCat 側の識別子が変更不可のため `ad_free`（広告なし）と `premium` を使い、kit の既定を上書き（`purchases_service.dart` の `EntitlementIds`）。
- 6アプリのコメント: 「RevenueCat 側は entitlement ID を 'noads' / 'premium'、商品を現行オファリングに登録する」。

### 1.4 広告ユニットID・AdMob アプリID（どこにあるか）

実IDの値は本書に転記しません（ユニットIDは秘密情報ではありませんが、kit は「本番IDは引数で渡す（コミットしない）」方針。後述の決定事項）。テストIDは Google の公開サンプルです。

| アプリ | ユニットID（コード） | AdMob アプリID | 状態 |
|---|---|---|---|
| G検定 | `lib/main.dart` の `_adUnitIds()`。Web は空、iOS は Google のテストID、Android は `kReleaseMode` のとき**本番形式のユニット3つ（コミット済み）**、それ以外はテストID | Android: `android/app/src/main/AndroidManifest.xml` の `com.google.android.gms.ads.APPLICATION_ID` に**本番形式のID（コミット済み）**。iOS: `ios/Runner/Info.plist` の `GADApplicationIdentifier` は Google のテストアプリID | Android は登録済み。`PRELAUNCH_CHECKLIST.md` に「Android は 2026-10-13 に AdMob へ登録し、リリースのみ本番ユニット。残り: iOS のアプリ・ユニット登録、Play 公開後にストア情報を紐付けて審査を通す（それまで広告配信は制限される）」。一方 `docs/release_prep_log.md` §6 は「テスト広告ユニットIDを使用中」と書いていて**古い** |
| ITパス | `lib/main.dart` の `_adUnitIds()`。**Android も全ビルドでテストID**（コメント「本番の広告ユニットは未発行」）、iOS もテストID | Android: `AndroidManifest.xml` は Google のテストアプリID（`ca-app-pub-3940256099942544~3347511713`）。iOS: `Info.plist` はテストアプリID（`~1458002511`） | 未発行。`PRELAUNCH_CHECKLIST.md` に「AdMob のアプリID・広告ユニットIDを発行して差し替え」 |
| 情セマネ | ITパスと同じ構成（`lib/main.dart`） | Android: `AndroidManifest.xml` はテストアプリID。iOS: 【TODO】未読 | 未発行 |
| 漢検 | `lib/services/ad_service.dart`。`kReleaseMode` のとき本番形式のバナー・インタースティシャル（コミット済み）。リワードは「未使用のダミーの本番形式ID」。それ以外はテストID | `AndroidManifest.xml` に**本番形式のアプリID（コミット済み）** | Android のみ。iOS ディレクトリは調査時点のルート一覧に無し |
| 簿記・生成AI・乙4 | 広告未配線のため無し | 【TODO】`AndroidManifest.xml` に AdMob アプリIDがあるか未確認（`google_mobile_ads` を配線するとアプリIDが無いと起動時にクラッシュするのが一般的。【推定】） | 未着手 |

重要な落とし穴（コードから読み取れる。実機では未検証）:

- `AdGate.init` は最初に `assertNoTestIdsInRelease` を実行し、**リリースビルドでテストIDが残っていると `StateError`**（`app_common_kit/lib/ads/ad_gate.dart`）。ITパス・情セマネは Android も全ビルドがテストIDで、`main.dart` で `AdGate.init` を try/catch せずに呼ぶため、**リリースビルドは起動時に落ちる可能性が高い**。G検定も iOS のリリースビルドは同様（iOS 側に `kReleaseMode` の分岐が無い）。一方、漢検は `try/catch` で握りつぶして広告なしで続行する。
- G検定・漢検は、本番形式のユニットIDが Android のリリースだけに入っている。デバッグ・profile はテストIDなので、開発中に実広告をタップして不正クリック扱いになることは避けている（`lib/main.dart` のコメント）。

### 1.5 プレミアム機能のゲート（どこで止めているか）

共通の線引き（`lib/policy/premium_features.dart`）: 問題・解説・模擬試験・基本の苦手特訓、原因ラベルの記録・比較表示・更新ログ・引き継ぎは無料。

| アプリ | ゲート箇所【確認済】 | 備考 |
|---|---|---|
| G検定 | `lib/screens/premium_practice_cards.dart`: 弱点ドリル（`PremiumFeature.weakDrill`）、試験直前モード（試験日が近いときだけ表示。判定は `weakDrill` を流用）、`WeakSummaryCard`（`canShowWeakSummary`）。`lib/screens/mock_exam_screen.dart`: カスタム模擬試験と成長グラフ（`PremiumFeature.mockExamHistory`）。広告: 模擬試験の結果後にインタースティシャル（`mockExamResult`）、結果画面にバナー（`BannerPlacement.result`） | 未購入のタップは SnackBar で案内するだけ（「設定から購入できます」） |
| 簿記3級 | `lib/purchase/weak_drill_card.dart`（弱点ドリル）。`lib/company_mode/company_scenario_list_page.dart`: 会社経営モードの5シナリオのうち、`freeCompanyScenarioIds`（`cafe_donguri`・`zakka_kotori`）以外の3本がプレミアム限定 | 他の `PremiumFeature`（試験直前・カスタム模擬・成長グラフ・読み上げなど）を簿記が使っているかは【TODO】。`lib/purchase/weak_summary_section.dart` も未読 |
| 漢検 | `lib/screens/paywall_screen.dart` の文言: プレミアム＝準1級・1級の問題＋広告なし、広告なし＝広告の非表示。`purchases_service.dart` に `hasPremium()` / `hasAdsRemoved()` | 準1級・1級を実際に止めている画面は未確認【TODO】 |
| ITパス・情セマネ・生成AI・乙4 | 【TODO】画面側の呼び出しは未読。G検定と同構成の可能性【推定】。`docs/release_prep_log.md`（生成AI）には「カスタム模擬試験、成長グラフ、解説読み物の読み上げ、広告非表示」がプレミアムとして書かれている | ローカルで `canUsePremiumFeature` / `entitlementStateProvider` を各アプリで検索して一覧化することを推奨 |

### 1.6 購入の復元・ペイウォール

| アプリ | 復元 | ペイウォール |
|---|---|---|
| 簿記 | `PurchaseSection` に復元ボタン（kit `purchase_section.dart`） | 専用画面なし。設定タブの購入欄 |
| G検定 | `settings_screen.dart` の「購入を復元」（`restore()`） | 専用画面なし。設定タブの購入欄 |
| 漢検 | `paywall_screen.dart` の「購入を復元する」 | 専用画面あり（二段階、年額に「おすすめ」表示、購入前に `requireParentalGate`） |
| その他 | 【TODO】 | 【TODO】 |

### 1.7 署名・ビルド・秘密情報の状態

| アプリ | applicationId（Android） | release 署名の読み込み | `.gitignore` |
|---|---|---|---|
| G検定 | `com.yourwish.ukalab.g_kentei`（`android/app/build.gradle.kts`） | `android/key.properties` または環境変数 `UPLOAD_STORE_FILE` ほか。無ければ debug 署名 | `android/key.properties`、`*.jks`、`*.keystore`、`android/app/google-services.json`。**`GoogleService-Info.plist` は書かれていない**（iOS ディレクトリあり） |
| ITパス | `com.yourwish.ukalab.it_passport` | 同上 | 【TODO】未読 |
| 情セマネ | `com.yourwish.ukalab.infosecmanage` | 同上 | 【TODO】未読 |
| 生成AI | `com.yourwish.ukalab.seisei_ai_passport` | 同上（R8 有効、`proguard-rules.pro`） | `android/key.properties`、`*.jks`、`*.keystore`、`android/app/google-services.json` |
| 簿記 | `com.yourwish.ukalab.boki3` | 同上（R8 有効） | `google-services.json`、`GoogleService-Info.plist`、`firebase_options.dart`、`.env`、`android/keystore/`、`*.jks`、`*.keystore` |
| 漢検 | `com.yourwish.ukarulab.kanji`（綴りが他と異なる。`build.gradle`） | `android/key.properties`。無ければ debug 署名 | `google-services.json`、`GoogleService-Info.plist`、`android/key.properties`、`*.jks` などが書かれているが、**`android/app/google-services.json` と `lib/firebase_options.dart` がリポジトリ内に存在**（ルート一覧で確認。中身は未確認・転記しない） |
| 乙4 | `android/` が調査時点のルート一覧に無い | — | `google-services.json`、`GoogleService-Info.plist`、`firebase_options.dart`、`.env`、`*.jks`、`pubspec.lock` など |

G検定・生成AIの `docs/release_prep_log.md` §4: release keystore（`upload`）を生成して保管（保管場所は書かれていない。紛失すると同じアプリを更新できなくなる）、`.github/workflows/build-aab.yml`（`workflow_dispatch`）に `UPLOAD_KEYSTORE_BASE64` などの Secrets 名。

漢検の `lib/services/purchases_service.dart` には **RevenueCat の公開SDKキーらしき値が直書き**されている（値は本書に転記しない）。公開SDKキーはクライアントに含める前提のキーだが、kit の方針（「コミットしない」）と食い違う。後述の決定事項。

### 1.8 `shared_core` との関係

`shared_core`（小学コレシリーズ共通パッケージ）の `CLAUDE.md`（Phase 4.22）に `PurchaseService` / `SubscriptionConfig` / `SharedCoreInitializer` と `purchases_flutter: ^8.3.0` の記述がある【確認済・同ファイル】。ただし本調査で pubspec を読んだ簿記・G検定・漢検・乙4のいずれも `shared_core` に依存していない。**うかラボ側の課金・広告の標準は `app_common_kit`（`EntitlementService` と `AdGate`）で、`shared_core` の `PurchaseService` は別系統**。混ぜないこと。

## 2. 未実装・要決定リスト

### 2.1 実装の抜け（コード側）

1. 本物の購入サービスへの切替が **Android のみ**: 各 `main.dart` の `_useRevenueCat` は `Platform.isAndroid && _rcGoogleKey.isNotEmpty`。iOS 用の SDK キー（例: `RC_APPLE_KEY`）の読み込みが無い【確認済】。
2. 乙4は RevenueCat への切替自体が無い（Fake 直書き）。
3. 簿記・生成AI・乙4は広告が未配線（`AdGate.init`、`adGateProvider` の override、バナー・インタースティシャルの呼び出し、AdMob アプリID）。
4. ITパス・情セマネ・G検定(iOS) はテストID／本番ID未発行でリリースビルドが落ちる可能性（1.4）。
5. 同意（UMP）: `GoogleAdsBackend` は UMP を呼ぶが、AdMob 側で同意メッセージを作る必要がある【推定。AdMob の管理画面の操作】。`ConsentController`（kit）は G検定の `main.dart` では使われていない【確認済】。
6. iOS の ATT: G検定・ITパスの `Info.plist` に `NSUserTrackingUsageDescription` が無い【確認済】。kit のコメントは「ATT 文言は UMP の同意フォーム側で扱う」。ATT を出すか、出す場合の文言・タイミングは未決。
7. 復元ボタンが無いアプリがないか、ペイウォール相当の画面がアプリごとに違う（簿記は `PurchaseSection`、G検定は自前、漢検は専用画面）。統一するか。
8. 漢検は kit 標準(`PurchaseSection` + 既定の権利ID) ではなく独自ラッパー。統一するかは未決。

### 2.2 方針の決定が必要なもの

| # | 決めること | 材料 |
|---|---|---|
| D1 | **初回リリースに課金・広告を含めるか**（含めない場合、ストア文面から課金・広告の文を外したまま） | `docs/store_listing_drafts.md`（PR #116 のブランチ `docs/store-listing-drafts`）§2.4・§11 Q5 |
| D2 | **価格**。コードは noads ¥480 / premium ¥1,500。G検定の文書には期間パス（90日 ¥600、30日 ¥1,000）の案も併記。決定14 の本文は未確認 | 1.3 |
| D3 | **サブスクか買い切りか**。漢検はサブスク（月額¥300/年額¥2,400）、他6本は買い切り＋期間パス案。Play で期間パス（30日/90日）をどの商品タイプで作るか【TODO。kit のコメントは「非更新型」だが、Play 側の商品タイプとの対応は要確認】 | 1.3 |
| D4 | **簿記の無料範囲の矛盾**。`ukalab_boki/README.md` の「会社経営モード Phase 3」には「課金導線は未実装のため全 5 シナリオ無料」、「未決・要確認」6 と `docs/company_mode_v1_design.md`「有料化の実装（2026-10-10、Phase 4）」には「最初の 2 つ無料・残り 3 つはプレミアム限定」。コード（`company_scenario_list_page.dart`）は**後者を実装済み**。README の古い記述を直すか、方針を改めて決めるか | 1.5 |
| D5 | **premium の中身**（どの `PremiumFeature` をどのアプリで有効にするか）。`PremiumFeature` に会社経営モードは含まれず、簿記はアプリ側で `hasPremium` を直接見ている | 1.5 |
| D6 | 無料枠（`FreeTierLimits`: 模擬試験 月1回など）を実際に適用するか。簿記の `docs/company_mode_v1_design.md` は「模擬試験の回数制限・復習の日次制限など、他の無料枠も未適用」と書く。G検定の `mock_exam_screen.dart` には回数制限の呼び出しが見当たらない | 1.1 |
| D7 | **広告の置き方**（頻度・場所）を kit の既定（3分・1日5回、結果画面とホーム）のままにするか。広告を入れること自体が「過去問だけ解いても…」のブランドや学習体験に合うか | `docs/marketing_concept.md` |
| D8 | **漢検の位置づけ**。README は小1〜小6対象、`ad_service.dart` は「児童向けアプリのため」常に子供向けタグ・最大G・非パーソナライズを強制。他6アプリは成人向け（`UkalabCrossPromoSection` のコメント「うかラボは大人向けなので保護者ゲートは不要」）。漢検は広告・課金・Firebase の扱いが最も厳しくなる。初回に含めるか、サブスク方針を維持するか | `ukalab_core/README.md` の相互紹介の節 |
| D9 | **本番の広告ユニットIDをリポジトリに置くか、ビルド時に注入するか**。現状 G検定・漢検はコミット済み、kit は「コミットしない」。IDは秘密ではないが、リポジトリが公開でも問題ないかの判断が要る | 1.4 |
| D10 | RevenueCat のプロジェクト構成（アプリごとに別プロジェクトか、1プロジェクトに複数アプリか）、権利IDの統一（`noads` か漢検の `ad_free` か） | 1.3 |
| D11 | **画像・テキストの AI 利用申告**（課金・広告とは別だが、ストア審査で一緒に聞かれる） | `docs/DECISIONS.md`、`docs/store_listing_drafts.md` §8 |

### 2.3 同意・プライバシーまわりの確認したい問い（法的助言ではありません）

専門家（弁護士・各ストアの規約）に確認する前提の質問リストです。

- EEA・英国・スイス向けに配信するか。配信するなら UMP（同意管理）の設定は必須か。日本のみ配信なら、どこまで不要か。
- 広告 SDK による端末情報の外部送信について、日本の法令や業界の指針に基づく通知・公表（プライバシーポリシーへの記載、アプリ内表示）が必要か。
- 米国向けに配信する場合の州法（カリフォルニアなど）、子ども向けの法令（COPPA 等）。成人向けと明示しても、漢検は対象年齢が小学生であり、どの扱いになるか。
- 広告のパーソナライズに同意しない場合の非パーソナライズ広告のみの運用でよいか（kit の `ConsentController.nonPersonalizedAds` と UMP の関係）。
- iOS で ATT を出すか。出さずに非パーソナライズ・ATT 非対応で配信する選択肢があるか。
- 購入履歴・購入者IDを RevenueCat に送ることのプライバシーポリシー上の記載（匿名ID）。
- 年齢区分（Play の対象年齢・コンテンツレーティング、App Store の年齢制限）を広告・課金の有無でどう答えるか。
- 子ども向けアプリ（漢検）で、保護者ゲートの強度（kit README は「簡易な確認で、年齢確認・本人確認ではない」）が足りるか。

## 3. ストア側の準備チェックリスト

UI の名称・上限文字数は変わりうるため、実際の画面で確認してください。「記憶」は未検証の一般知識です。

### 3.1 Google Play Console

アプリごとに:

- [ ] アプリを作成し、パッケージ名（1.7 の applicationId）を一致させる（後から変えられない）
- [ ] 内部テストトラックに署名済み AAB をアップロード（課金の動作確認は、ストアに上がったビルドが必要になることが多い【推定】）
- [ ] 収益化 > アプリ内アイテム（買い切り）に商品を作成: ID はコードの商品ID（1.2・1.3）と**完全一致**
  - [ ] 名前・説明・価格・状態（有効）
  - [ ] **ja-JP の翻訳（下記 3.1.1）**
- [ ] 期間パス（30日/90日）を作る場合は、商品タイプを決めてから作成（D3）
- [ ] 漢検: 定期購入（`premium-monthly` / `premium-yearly` / `premium-plus-monthly` / `premium-plus-yearly`）と基本プラン・特典。`purchases_service.dart` のコメントに「商品IDは変更不可」
- [ ] ライセンステスター（テスト用アカウントの登録）とテスト用の購入手順
- [ ] Data safety の更新（3.4）、プライバシーポリシーURL（`docs/release_prep_log.md` §6 に「Play Console 提出必須」）
- [ ] 広告を含むか（「広告を含む」）の申告、コンテンツレーティング、対象年齢、データ削除の案内
- [ ] AI 生成コンテンツの申告（3.5）
- [ ] RevenueCat と接続するためのサービスアカウントの権限設定（RevenueCat の手順に従う）【推定】

#### 3.1.1 ja-JP の翻訳（デフォルト言語を ja-JP に切り替える前に必須）

オーナーが `boki3_noads` / `boki3_premium` で遭遇した要件です。アプリのデフォルト言語を ja-JP に切り替える前に、**すべてのアプリ内アイテムに ja-JP の翻訳（名前・説明）を追加する必要がある**（Play Console の要件。他のアプリの商品にも同様に適用されると考えられる【推定】）。

手順の目安: 商品の編集画面で ja-JP の翻訳を追加 → すべての商品に追加 → 保存 → デフォルト言語を変更。文字数の上限は画面で確認（記憶では名前 55 字・説明 80 字程度）。

コピーペースト用の例（商品の中身は、コードで確認できた範囲だけで書いています）:

`boki3_noads`（根拠: 6アプリ共通の Fake の定義。kit の `EntitlementState.adsHidden`）

- 名前: `広告非表示`
- 説明: `アプリ内の広告を表示しなくなります。買い切り（1回のお支払い）です。`

`boki3_premium`（根拠: 簿記の `weak_drill_card.dart`、`company_scenario_list_page.dart`、Fake の表示名「プレミアム（広告非表示＋追加機能）」）

- 名前: `プレミアム`
- 説明: `広告を非表示にし、弱点ドリルと会社経営モードの全シナリオが使えます。買い切りです。`

注意:

- 買い切りかどうかは、kit README（「noads（広告なし・買い切り）」「premium（期間付き／買い切り）」）と G検定の `PRELAUNCH_CHECKLIST.md`（「¥1,500買い切り」）から。簿記の premium が期間パス併用になる場合は説明を変更。
- premium の「追加機能」は簿記で上記2つしか確認できていません。試験直前モード・カスタム模擬試験・成長グラフ・読み上げ等を簿記で有効にした場合は説明に足してください【TODO】。
- 他のアプリの例（中身は未確認の項目を除く）:
  - G検定 `g_kentei_noads`: 同じ文面でよい。`g_kentei_premium`: 「広告を非表示にし、弱点ドリル・試験直前モード・カスタム模擬試験・模擬試験の成長グラフが使えます。」（根拠: `premium_practice_cards.dart`、`mock_exam_screen.dart`。`docs/release_prep_log.md` §5 には解説読み物の読み上げも書かれているが、ゲート箇所は未確認【TODO】）
  - 他のアプリ: 中身が確認できていないため **TODO**（`<アプリごとの機能名>`）。

### 3.2 App Store Connect（iOS 版を出すアプリのみ）

iOS ディレクトリを調査時点で確認できたのは G検定とITパス（`ios/Runner/Info.plist`）。簿記・漢検・乙4・生成AI（ルート一覧）には見当たらない。情セマネは未確認。

- [ ] 契約・税・銀行情報（有料アプリ／アプリ内課金の契約）が有効【推定】
- [ ] アプリを作成し、Bundle ID を `PRODUCT_BUNDLE_IDENTIFIER` と一致させる【TODO。xcodeproj は未確認】
- [ ] アプリ内課金: 買い切りは非消耗型（Non-Consumable）【推定】。参照名・商品ID・価格・ja の表示名と説明・審査用スクリーンショット
- [ ] サブスクを使う場合（漢検）は、サブスクリプショングループ・期間・ローカライズ
- [ ] RevenueCat の iOS 用アプリ設定（キー、必要な App Store Connect 側の鍵）【推定】
- [ ] 「購入の復元」を画面内に置く（Apple のレビューで求められるのが一般的【推定】）
- [ ] サンドボックステスター（テスト用 Apple ID）での購入・復元の確認
- [ ] App Privacy（3.4）、年齢レーティング、プライバシーポリシーURL
- [ ] 広告を入れる場合: `GADApplicationIdentifier` を本番のIDへ、`SKAdNetworkItems` の更新、ATT の方針（2.1-6）
- [ ] 審査メモに、課金のテスト手順・ログイン不要である旨など

### 3.3 テスト用の準備（共通）

- [ ] Play: ライセンステスター。Apple: サンドボックステスター。RevenueCat: テスト用のユーザーと購入の確認画面
- [ ] 広告: AdMob の「テストデバイス」の登録（開発中に本番IDを使う場合のみ）
- [ ] 広告ユニットを作成した直後は配信まで時間がかかることがある（漢検の `ad_service.dart` のコメント）。ストア公開前は広告配信が制限される（G検定 `PRELAUNCH_CHECKLIST.md`）

### 3.4 Data safety（Play）／App Privacy（Apple）の更新

現在の申告の前提となる記録（`docs/release_prep_log.md` §6、G検定・生成AI）: 学習進捗はすべて端末内（`shared_preferences`）のみ、クラッシュ・分析 SDK は未使用、購入（RevenueCat）・Firebase は Fake／未配線で外部送信なし、「配線する場合は事前にデータセーフティの申告内容を更新すること」。

広告・課金を入れると変わる点（申告の正確な項目は各ストアの最新の質問に従う。以下は確認すべき観点）:

- 広告 SDK: 広告ID（Advertising ID）、端末・OS・IPアドレスなどの端末情報、同意状態。Play の「広告を含む」申告
- 課金: 購入履歴・購入状態、RevenueCat に送られるアプリ内ユーザーID（匿名ID）【推定】
- 相互紹介（`UkalabCrossPromo` が Firebase Remote Config を使う）によって、広告・課金を入れる前から Firebase との通信がある。`ukalab_core/README.md` の相互紹介の節に「Play の Data Safety を更新する（Firebase 利用に伴う収集の申告）」。G検定の `release_prep_log.md` §6 の「外部送信なし」と食い違わないか確認【TODO】
- 簿記の `README.md`「既知の技術的負債」: `app_common_kit` が Firebase などを依存に含むため、使っていなくても SDK が同梱される。申告は「同梱される SDK」を基準に確認
- 漢検は Firebase Auth / Firestore / Analytics / Crashlytics / Cloud Functions を使っており（`pubspec.yaml`）、申告の範囲がさらに広い
- 広告のパーソナライズ可否と UMP の結果によって、申告で「任意」か「必須」かが変わる可能性【推定】

### 3.5 AI コンテンツ申告の参照先

- `docs/store_listing_drafts.md` の第8章（PR #116 のブランチ `docs/store-listing-drafts`）: アプリ別の AI 利用の記録と確認事項
- `docs/DECISIONS.md` の「2026-10」: AI生成素材（Leonardo.Ai）はリリース前に利用規約・商用利用・ストアの AI コンテンツ申告を確認する、とある
- `docs/marketing_concept.md`: 「問題の一部が AI 下書きのアプリは、ストアの AI 利用申告と整合させる」

## 4. 実装の進め方（推奨と選択肢）

### 4.1 ライブラリの選択肢

| 案 | 内容 | 長所 | 短所・注意 |
|---|---|---|---|
| A. kit 標準を使う（RevenueCat + `google_mobile_ads`） | `RevenueCatEntitlementService` と `AdGate` をそのまま使う。6アプリは既にこの形に配線済み（広告は一部） | 実装済み。`FakeEntitlementService` でテストできる。復元・購入欄の UI あり。期間パスの期限管理は RevenueCat の権利に任せられる | RevenueCat の利用条件・費用は本調査の範囲外【TODO】。iOS 用のキー読み込みが未実装。サービスの外部依存が増える（Data safety） |
| B. 公式 `in_app_purchase` で自前実装 | `EntitlementService` を実装するクラスを作る（kit の抽象はそのまま使える） | 外部サービス不要 | レシート検証・復元・期間パスの期限管理・iOS/Android の差異を自前で持つ。サーバー検証をしないと改ざんに弱い。テストと保守が重い |
| C. 併用（Android だけ先に A、iOS は後） | 現状のコードがこの形（`Platform.isAndroid` ガード） | 段階的 | iOS の方針が決まるまで二重管理 |

`shared_core` の `PurchaseService`（`purchases_flutter ^8.3.0`）はうかラボのアプリでは使われていません（1.8）。案 A の `purchases_flutter` も別バージョン範囲です。

広告は `google_mobile_ads` が前提で、kit が UMP も呼びます。代替（別の広告ネットワーク）は本調査では検討していません。

### 4.2 アプリ別の作業リスト（ファイル単位）

共通（全アプリ）:

- `pubspec.yaml`: `app_common_kit` / `ukalab_core` のタグ固定を維持（kit は `v3.11.0`、core は `v0.75.0` に揃っていることを確認）
- `lib/main.dart`: 本物の購入サービスの初期化条件、iOS キーの追加、`AdGate.init`、`ProviderScope.overrides`
- `android/app/src/main/AndroidManifest.xml`: AdMob アプリID
- `ios/Runner/Info.plist`: `GADApplicationIdentifier`、`SKAdNetworkItems`、ATT 文言（方針次第）
- 設定画面（購入・復元）と、ゲート箇所の文言（「設定から購入できます」）

| アプリ | 触るファイル（優先順） |
|---|---|
| 簿記 | `lib/main.dart`（`AdGate` 追加、`_adUnitIds`）、`android/app/src/main/AndroidManifest.xml`（AdMob アプリID。現状の有無は未確認）、結果画面などへのバナー・インタースティシャル呼び出し（`lib/mock_exam/mock_exam_page.dart`、`lib/practice/practice_page.dart` など）、`README.md` の会社経営モードの記述修正（D4）、iOS を出すなら `ios/` の生成 |
| G検定 | `lib/main.dart`（iOS のリリース用ユニットIDの分岐、iOS の RevenueCat キー）、`ios/Runner/Info.plist`（本番アプリID）、`.gitignore`（`GoogleService-Info.plist` の追加）、`docs/release_prep_log.md` §6 の更新（古い記述） |
| ITパス | `lib/main.dart`（本番ユニットID、`kReleaseMode` の分岐）、`android/app/src/main/AndroidManifest.xml`（テストアプリID→本番）、`ios/Runner/Info.plist`、アプリアイコン（`PRELAUNCH_CHECKLIST.md`: G検定の複製のまま）、`ios/Runner/Info.plist` の `CFBundleDisplayName` が「Ukalab G Kentei」のまま |
| 情セマネ | ITパスと同様（`lib/main.dart`、`AndroidManifest.xml`、iOS は存在を確認してから） |
| 生成AI | `lib/main.dart`（`AdGate` 追加、`adGateProvider` の override、`google_mobile_ads` が `pubspec.yaml` にあるか確認）、`AndroidManifest.xml`、購入欄の有無を設定画面で確認 |
| 乙4 | `lib/main.dart`（RevenueCat への切替、`AdGate`）、`android/` `ios/` の生成（調査時点で無い）、`pubspec.yaml`、設定画面の購入欄の有無 |
| 漢検 | `lib/services/purchases_service.dart`（SDKキーの扱い、kit 標準へ寄せるか）、`lib/services/ad_service.dart`（ユニットIDの扱い、リワードのダミーID）、`android/app/google-services.json` と `lib/firebase_options.dart` の扱い、`README.md`（「広告ゼロ」との食い違い）、iOS を出すなら `ios/` の生成 |

### 4.3 テスト方針

- **Fake を残す**: `FakeEntitlementService`（kit）はテストとプレビューで使い続ける。`entitlementServiceProvider.overrideWithValue(...)` で差し込むので、画面のテストは本物の SDK を呼ばない（G検定・簿記の既存パターン）。
- ゲートの判定は `ProviderScope.overrides` で `EntitlementState(hasPremium: true)` などを渡して確認（簿記の `company_scenario_list_*` のテスト群の方式。1テスト1ファイルに分ける既知の制約が README にある）。
- 広告は `AdGate.init(backend: ...)` の差し替え（kit のテスト用口。Web は `NoAdsBackend`）で、契機とバナー位置のテストを書く。
- 本物の課金・広告は実機または内部テストで手動確認（下記 5 の落とし穴参照）。

### 4.4 CI と秘密情報

- 【確認済】既存の方式: RevenueCat のキーは `--dart-define=RC_GOOGLE_KEY=<値>`（`lib/main.dart` のコメント。未指定なら Fake で動く）。署名鍵は `android/key.properties` または環境変数 `UPLOAD_STORE_FILE` / `UPLOAD_STORE_PASSWORD` / `UPLOAD_KEY_ALIAS` / `UPLOAD_KEY_PASSWORD`（各 `build.gradle.kts`）。AAB のビルドは `.github/workflows/build-aab.yml`（G検定・生成AIで言及。他は未確認）。
- 方針: SDKキー・署名鍵・サービスアカウントは**コミットしない**。ローカルは `--dart-define-from-file` による別ファイル（`.gitignore` に追加）か、環境変数、Gradle の `local.properties` / `key.properties`、CI は Secrets 経由。ユニットIDも同様にするかは D9。
- 【推定】`--dart-define` の値はビルド成果物に含まれるため、「秘密」ではなく「コミットしない」ための手段。真の秘密（サービスアカウントの JSON など）はビルドに含めない。
- `google-services.json`: G検定・生成AI・簿記・乙4・漢検の `.gitignore` に記載あり。**漢検はファイルがリポジトリに存在**。`GoogleService-Info.plist` は G検定の `.gitignore` に無い。
- 互換チェック: `app_common_kit` の `compat` ワークフロー（`.github/workflows/compat.yml`）が、5アプリ（乙4・G検定・簿記・生成AI・漢検）に差し込んで検査する（kit README）。ITパス・情セマネは対象外。
- kit を更新したときのタグ追従: `templates/kit-update.yml`（kit README）。

## 5. よくある落とし穴

- **applicationId / Bundle ID の不一致**: Play Console のパッケージ名と `applicationId` は一致させる（1.7）。漢検は綴りが他と異なる（`ukarulab`）。変更すると別アプリになる。
- **商品IDの不一致**: コードの `productId`、Play/Apple の商品ID、RevenueCat の商品・Offering・Entitlement ID の3箇所を揃える。Entitlement ID は kit 既定が `noads` / `premium`（漢検は `ad_free` / `premium`）。RevenueCat の識別子は作成後に変更できない（漢検のコメント）。
- **Offering に商品を載せ忘れる**: `offers()` は `current` の Offering を返す。空だと購入欄が出ない（kit の `PurchaseSection` は何も出さない、G検定の設定画面も `SizedBox.shrink`）。
- **署名**: release 署名の設定が無いと debug 署名になる（各 `build.gradle.kts`）。Play にアップロードする AAB は upload 鍵で署名。鍵の紛失は更新不能（`release_prep_log.md` §4）。Play App Signing の有効化は要確認【TODO】。
- **R8 / ProGuard**: 簿記・生成AIは R8 有効で `proguard-rules.pro` あり（`WorkManager` / Firebase でクラッシュした履歴）。広告・課金の SDK を足したときに release だけ落ちないか、release ビルドで必ず起動確認する。
- **内部テストトラック**: 課金のテストは、アップロード済みのビルド・ライセンステスターのアカウントが必要になることが多い【推定】。テストアカウントでは実課金されない設定になっているか確認。
- **広告IDの取り違え**: リリースにテストIDが残ると `StateError`（1.4）。逆に、デバッグで本番IDを使うと不正クリック扱いになる。`kReleaseMode` で分岐する現在の方式を維持。
- **広告配信の制限**: 新規ユニットは配信開始まで時間がかかる、ストア公開・アプリ審査前は配信が制限される。
- **UMP / ATT**: 同意メッセージを AdMob 側で作成・公開していないと、`canRequestAds` が false のまま広告が出ない【推定】。iOS は ATT の文言と UMP の整合。
- **サンドボックス**: Apple のサンドボックスアカウントでの購入は、実機のサインイン設定が必要【推定】。復元の動作確認も同じアカウントで。
- **復元**: 端末を変えた人・再インストールの人のため、復元ボタンを必ず見える場所に置く（簿記・G検定・漢検は設定または専用画面にあり）。
- **iOS のコメントと実態のずれ**: `ios/Runner/Info.plist` の `CFBundleDisplayName` が別アプリ名のまま（ITパス）。ストア審査前に確認。
- **README・ログの古い記述**: G検定の `docs/release_prep_log.md` §6（テストIDと書かれている）、簿記 `README.md` の会社経営モード、漢検 `README.md`（広告ゼロ）。実装後に直す。

## 6. 参照（リポジトリ内パスのみ）

`ukalab_core`:

- `docs/DECISIONS.md`
- `docs/marketing_concept.md`
- `docs/store_listing_drafts.md`（PR #116 のブランチ `docs/store-listing-drafts`。第8章 AI 申告、第11章 オーナー確認事項。Q5 が広告・課金を初回リリースに含めるかと価格）
- `lib/policy/premium_features.dart`、`lib/policy/free_tier.dart`、`lib/policy/usage_quota.dart`
- `README.md`（「無料枠とプレミアムの線引き」「相互紹介」「まだ入っていないもの」）

`app_common_kit`:

- `README.md`（機能3: 権利管理、機能4: 広告ゲート、同意管理、保護者ゲート、互換チェック）
- `lib/entitlement/`（6ファイル）、`lib/ads/`（6ファイル）、`lib/consent/consent.dart`、`lib/parental_gate.dart`
- `CHANGELOG.md`

アプリ:

- `ukalab_boki`: `lib/main.dart`、`lib/purchase/weak_drill_card.dart`、`lib/company_mode/company_scenario_list_page.dart`、`docs/company_mode_v1_design.md`、`README.md`、`android/app/build.gradle.kts`
- `ukalab-g-kentei`: `lib/main.dart`、`lib/screens/settings_screen.dart`、`lib/screens/premium_practice_cards.dart`、`lib/screens/mock_exam_screen.dart`、`PRELAUNCH_CHECKLIST.md`、`docs/release_prep_log.md`、`ios/Runner/Info.plist`、`android/app/src/main/AndroidManifest.xml`
- `ukalab_it_passport`: `lib/main.dart`、`PRELAUNCH_CHECKLIST.md`、`android/app/src/main/AndroidManifest.xml`、`ios/Runner/Info.plist`
- `ukalab_infosecmanage`: `lib/main.dart`、`android/app/src/main/AndroidManifest.xml`
- `ukalab_seisei_ai_passport`: `lib/main.dart`、`docs/release_prep_log.md`
- `ukalab_otsu4`: `lib/main.dart`、`pubspec.yaml`、`.gitignore`
- `ukalab_kanken`: `lib/main.dart`、`lib/services/purchases_service.dart`、`lib/services/purchase_tiers.dart`、`lib/services/ad_service.dart`、`lib/screens/paywall_screen.dart`、`android/app/build.gradle`、`android/app/src/main/AndroidManifest.xml`、`PRODUCTION_CHECKLIST.md`

別系統（うかラボでは使っていない）:

- `shared_core`: `CLAUDE.md`（Phase 4.22 の `PurchaseService`）

## 付録. 調査の限界

- GitHub の検索機能が使えず、ファイルは一覧と個別取得で確認しました。画面側の呼び出し箇所（バナー・インタースティシャル・復元ボタン・各ゲート）の網羅確認はしていません。ローカルでは `entitlementStateProvider`、`canUsePremiumFeature`、`adGateProvider`、`maybeShowInterstitial`、`banner(` を各アプリで検索して一覧化してください。
- ITパス・情セマネ・生成AI・乙4の設定画面、`pubspec.yaml`（ITパス・情セマネ・生成AI）、`.gitignore`（ITパス・情セマネ）は未読です。
- 実機・ストアコンソールでの動作確認は一切していません。
- 価格の根拠「決定14」の本文は未確認です。
