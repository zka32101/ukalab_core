# 登録作業の方針決定と、アプリ別の値(2026-10-16)

状態: 運営者が選択肢から決めた内容の記録。`docs/local_handover_registration.md` と `docs/local_handover_monetization.md` §2.2 の D1〜D10 に対応する。
値は各リポジトリの `main` を実際に読んで確認した(推測なし)。実キーは書かない。広告IDは「本番形式/テスト」の区別だけ記す。

## 1. 決定事項

| # | 決めたこと | 結果 |
|---|---|---|
| D1 | 初回リリースの範囲 | **課金・広告とも含める** |
| D2 | 価格 | **noads ¥480 / premium ¥1,500 で確定**(買い切り) |
| D3 | 課金モデル(漢検を除く6本) | **買い切り2種**(コードの現状)。期間パスは採らない |
| D4 | 簿記の無料範囲 | **コードの現状を正**(会社経営モードは最初の2つ無料・残り3つは premium)。README の古い記述を直す |
| D5 | premium の中身 | **共通の7機能にそろえる**(`PremiumFeature` 全7)。簿記の会社経営モード残り3つ、漢検の上位級は今のまま追加 |
| D6 | 無料枠 | **適用する。標準値**(模試 月1回・苦手分析 3分野・復習 1日10問・自動生成 1日10問)。公開後の実測で見直す |
| D7 | 広告の置き方 | **kit の既定のまま**(最短3分・1日5回、結果画面とホーム) |
| D8 | 漢検の位置づけ | **うかラボシリーズにあわせる**。課金・商品ID・権利IDは他の6本に合わせる。**子ども向けの広告設定(最大G・非パーソナライズ・保護者ゲート)は維持** |
| D9 | 本番の広告ユニットID | **ビルド時に注入**(`--dart-define` / CI Secrets)。コミット済みのG検定・漢検は注入式に移す |
| D10 | RevenueCat 構成 | **1プロジェクトに7アプリ**。entitlement は `noads` / `premium` に統一 |
| 補足 | iOS | **今は Android のみ**。Apple 側の登録、`RC_APPLE_KEY`、ATT 文言は後回し |

## 2. アプリごとの値(Android)

| アプリ | applicationId | AdMob アプリID(マニフェスト) | 広告の配線 | 商品ID | 備考 |
|---|---|---|---|---|---|
| G検定 | `com.yourwish.ukalab.g_kentei` | 本番形式(登録済み) | 配線済み。リリースのみ本番形式ユニット3つ(コミット済み→D9で注入式へ) | `g_kentei_noads` / `g_kentei_premium` | |
| ITパスポート | `com.yourwish.ukalab.it_passport` | **テストID** | 配線済み。全ビルドがテストID | `it_passport_noads` / `it_passport_premium` | AdMob の登録とユニット発行が要る |
| 情報セキュリティマネジメント | `com.yourwish.ukalab.infosecmanage` | **テストID** | 同上 | `info_security_noads` / `info_security_premium` | 同上 |
| 生成AIパスポート | `com.yourwish.ukalab.seisei_ai_passport` | 本番形式(マニフェストに既にある) | **未配線** | `seisei_ai_passport_noads` / `seisei_ai_passport_premium` | AdGate の配線が要る |
| 簿記3級 | `com.yourwish.ukalab.boki3` | **テストID** | **未配線** | `boki3_noads` / `boki3_premium` | AdMob の登録と配線が要る |
| 危険物乙4 | **未生成**(`android/` が無い) | なし | 未配線 | `otsu4_noads` / `otsu4_premium` | Android プラットフォームの生成から。RevenueCat への切替コードは追加済み |
| 漢検(うかラボ 漢字検定) | `com.yourwish.ukarulab.kanji` | 本番形式 | 独自の `AdService`(子ども向け設定あり) | 現状 `premium-*`。**D8により、他と同じ `<app>_noads` / `<app>_premium` の型へ合わせる。`<app>` の綴りは未決(applicationId の判断と一緒に決める)** | 綴り `ukarulab` は他と異なり旧ブランド名を含む。**公開前に変更するか要判断**(applicationId は未公開の間しか変えられない) |

iOS バンドルID(参考。今は使わない): G検定 `com.yourwish.ukalabGKentei` / ITパス `com.yourwish.ukalabItPassport` / 情セマネ `com.yourwish.ukalabInfosecmanage`。他4本は `ios/` が無く未確定。

## 3. 決定から出る作業

運営者が画面で行う:
1. Play Console で7アプリのアプリ内アイテム(`<app>_noads` ¥480 / `<app>_premium` ¥1,500、管理対象外アイテム)を登録(日本語訳を先に入れる)。
2. RevenueCat で1プロジェクトを作り、Play を接続、商品・entitlement(`noads` / `premium`)・Offering・公開SDKキー(Google)を発行。
3. AdMob でITパス・情セマネ・簿記のアプリとユニットを登録・発行。UMP の同意メッセージを作る。
4. 発行したキー・IDを、`--dart-define` / CI Secrets に入れる(**リポジトリには書かない**)。

コードの変更(1アプリ1 PR。すべて別PRで、マージは指示があったときだけ):
- 広告ユニットID・RevenueCat キーを `--dart-define` 読み込みにする(G検定・漢検は、コミット済みの値を外す)。
- 生成AI・簿記・乙4に AdGate を配線する。乙4は `android/` を生成する。
- 漢検の課金を kit 標準(`noads` / `premium`、`PurchaseSection`)に合わせる。子ども向け設定と保護者ゲートは維持。
- `FreeTierLimits.standard` を7アプリに適用する(模試・苦手分析・復習・自動生成)。
- `PremiumFeature` の適用を共通の7機能にそろえる(乙4に模試成長グラフと弱点ドリルを追加。カスタム模試は現状どのアプリも未使用)。
- 簿記 README の無料範囲の記述を直す。

## 4. 実機確認の記録(結果は確認のたびに追記)

| 日付 | アプリ | 項目 | 結果 | メモ |
|---|---|---|---|---|
| | | リリースビルドで起動できる | 未実施 | |
| | | 購入 → 広告が消える(noads) | 未実施 | |
| | | 購入 → 機能が解放される(premium) | 未実施 | |
| | | 購入の復元 | 未実施 | |
| | | キャンセル・失敗時の表示 | 未実施 | |
| | | 広告の場所・頻度(最短3分・1日5回) | 未実施 | |
| | 漢検 | 保護者ゲート・子ども向け設定 | 未実施 | |

注意: RevenueCat の初期化失敗時は Fake に落とさない(無料購入になるため)。広告SDKのネイティブ側の設定不備は Dart の try/catch で防げないので、実機で確認する。
