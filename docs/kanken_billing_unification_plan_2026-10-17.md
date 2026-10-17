# 漢検(うかラボ 漢字検定)の課金・広告を他のうかラボに合わせる計画(2026-10-17)

状態: **調査だけ。コードもストア設定も変えていない。** 運営者の確認が済んでから、別PRで実装する。
前提の決定: `docs/registration_decisions_2026-10-16.md`(D3 買い切り2種 / D8 うかラボに合わせる・子ども向け設定は維持 / D9 ビルド時注入 / D10 RevenueCat 1プロジェクト / applicationId は変更しない)。
調べた版: `ukalab_kanken` main(`pubspec.yaml` は `1.0.2+4`)、Play Console のアプリ「うかラボ漢字検定」。

## 1. 現状(確認したこと)

| 項目 | 現状 | 根拠 |
|---|---|---|
| 課金の部品 | kit の `EntitlementService` を使わず、独自の静的クラス `PurchasesService`(中身は kit の `RevenueCatEntitlementService`)。画面は `hasAdsRemovedProvider` / `hasPremiumProvider`(StreamProvider)で読む | `lib/services/purchases_service.dart`、`lib/providers/purchases_provider.dart` |
| 商品ID(コード) | 広告なし: `premium-monthly` / `premium-yearly`(月額¥300・年額¥2,400)。プレミアム: `premium-plus-monthly` / `premium-plus-yearly`(月額¥480は仮) | `purchases_service.dart`、`purchase_tiers.dart` |
| 権利ID | `ad_free`(広告なし)/ `premium`。RevenueCat 側のIDは作成後に変更できないため `ad_free` のまま | `purchases_service.dart` のコメント |
| RevenueCat キー | **公開SDKキーがコードに直書き**(`_apiKey`)。D9・`local_handover_registration.md` の方針(コミットしない)と食い違う | `purchases_service.dart` |
| Play Console の商品 | 定期購入が**2つだけ**(`premium_monthly` / `premium_yearly`。最終更新 2026-10-03)。`premium-plus-*`(プレミアム)は**未作成**。アプリ内アイテム(買い切り)は未確認 | Play Console「定期購入」(アンダースコアの表記。コードはハイフン。RevenueCat 側の対応づけで吸収されている可能性があるが未確認) |
| 広告 | `AdService`(静的)。リリースの本番形式ユニットIDがコミット済み(バナー・インタースティシャル。リワードはダミー)。子ども向け設定(`childDirected` / 最大G / 非パーソナライズ)は常に有効。バナーはホームのみ、インタースティシャルは演習終了時 | `lib/services/ad_service.dart`、`home_screen.dart`、`weak_kanji_mode_screen.dart` |
| 広告の起動失敗 | `AdGate.init` を try/catch で握りつぶし、広告なしで続行する(他のアプリと同じ考え方) | `ad_service.dart` |
| プレミアム機能 | 準1級・1級を `premiumOnlyLevels` で制限。共通の `PremiumFeature`(10分プラン・試験直前・書き出し)は kit の `isPremiumFor` で適用済み | `home_screen.dart`、`exam_prep_entry.dart` |
| 購入前の保護者確認 | ペイウォール画面側で実施済み | `paywall_screen.dart` |
| kit の `entitlementServiceProvider` / `adGateProvider` | **override していない**(静的クラスで持っている)。kit 標準の `PurchaseSection` も使っていない | `lib/main.dart` |

## 2. 他のうかラボとのずれ(決定との差)

1. 課金モデル: 漢検はサブスク2段(広告なし/プレミアム × 月・年)。決定は「買い切り2種(noads ¥480 / premium ¥1,500)」。
2. 商品ID・権利ID: `premium-*` / `ad_free` と、`<app>_noads` / `<app>_premium` / `noads` / `premium` が違う。
3. 公開SDKキー・広告ユニットID: コードに直書き(決定は注入式)。
4. 無料枠(D6): 模擬試験の月1回・復習の1日10問は未適用。
5. 構成: kit の標準の権利サービス・広告ゲートに乗っていない(静的クラス)。

## 3. 計画(案。運営者が選ぶ点は §4)

実装は、次の順に別PRで出す。いずれもマージは指示があったときだけ。

| 順 | PR | 内容 | リスク |
|---|---|---|---|
| 1 | 広告・キーの注入式 | `_apiKey` と広告ユニットIDを `--dart-define`(`RC_GOOGLE_KEY` / `AD_*`)に変更。`build-aab.yml`(あれば)を Secrets 注入に。リリースで未指定なら、広告なし・仮の購入なしで起動 | 小。子ども向け設定は触らない |
| 2 | 権利サービスを kit 標準に | `PurchasesService` を、kit の `EntitlementService` を `entitlementServiceProvider` で渡す形に変更。`adGateProvider` も override。`hasAdsRemovedProvider` / `hasPremiumProvider` は、kit の `entitlementStateProvider` から作る(画面側は変えない) | 中。購入・復元の実機確認が必須 |
| 3 | 商品・権利IDを合わせる | §4-1 の選択に従う。保護者ゲート付きのペイウォールは**残す**(kit の `PurchaseSection` は、保護者ゲートを購入前のフックで差し込む作りで、標準では付かないため) | 大。Play・RevenueCat の画面操作が先に要る |
| 4 | 無料枠(D6) | 模擬試験の月1回、「今日の復習」の1日10問(他の6アプリと同じ形) | 小〜中 |

## 4. 運営者に決めてほしいこと

1. **商品の形**(PR 3 の前に必須)
   - 案A(推奨): 買い切り2種に合わせる。Play に管理対象のアプリ内アイテム `<app>_noads`(¥480)・`<app>_premium`(¥1,500)を作る。プレミアム=広告なし+追加機能+準1級・1級。**漢検はまだ公開していないので、既存の購入者がいない**(2つの定期購入は無効にするか、使わずに残す)。
   - 案B: サブスクのまま、構成だけ kit 標準に寄せる(月額¥300・年額¥2,400。プレミアムの `premium-plus-*` は Play に未作成なので作る)。決定 D3 の「買い切り」とはずれる。
   - `<app>` の綴りは、applicationId と無関係に決められる(例: `kanji`。他の6本は `g_kentei` など)。
2. **RevenueCat の構成**(D10 は1プロジェクト)。今の漢検のアプリが、他のアプリと同じプロジェクトにあるのか、別プロジェクトなのか、運営者が RevenueCat の画面で確認する。権利ID `ad_free` は変えられないので、案Aなら、新しい商品を `noads` / `premium` に紐付ける(漢検の `ad_free` は使わなくなる)。
3. **子ども向けの扱い**(D8 で維持と決定済み)。広告つきの子ども向けアプリは、Play の「ファミリー向けポリシー」と、アプリのターゲット年齢の申告に関わる。申告の内容(対象年齢に小学生が含まれるか)と、広告SDKの扱いが一致しているかは、**Play Console の画面で、運営者が確認する**(私は確認していない)。

## 5. 実機で確認すること(実装後)

- リリースビルドで起動できる(広告ID・キーが未指定でも落ちない)。
- 購入 → 広告が消える → 機能が解放される。購入の復元。キャンセル・失敗の表示。保護者ゲート。
- 広告の場所・頻度(ホームのバナー、演習終了時のインタースティシャル。最短3分・1日5回)と、子ども向け設定(最大G・非パーソナライズ)。
- 準1級・1級は、premium のときだけ開ける。
