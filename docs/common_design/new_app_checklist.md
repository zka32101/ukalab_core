# 新資格アプリ追加チェックリスト

アプリ側リポジトリは ExamConfig・問題データ・テーマ・ストア設定だけを持つ(README 参照)。以下は参照実装として ITパスポート(`ukalab_it_passport`)を見て確認した内容。

## 1. 依存(タグ固定)

- [ ] `pubspec.yaml` の `ukalab_core` は git の `ref: vX.Y.Z` で**タグ固定**。`main` は参照しない。
- [ ] `app_common_kit` は core 経由のバージョンに合わせる(core が kit のタグを固定している)。
- [ ] 2026-10-23 時点のアプリの固定タグはまちまち(例: it_passport v0.83.0、boki/otsu4/infosecmanage/seisei v0.82.2、g-kentei v0.75.0。ローカルの作業コピーの値で、要確認)。追従は kit-update ワークフローまたは別 PR。

## 2. プレミアム

- [ ] 権利IDは `noads` / `premium`(RevenueCat 側。作成後に変更できない)。商品IDは `<app>_noads` / `<app>_premium`(買い切り2種)。
- [ ] `PremiumFeature`(core `lib/policy/premium_features.dart`)の機能を `isPremium` で出し分ける。2026-10-23 時点の定義: weakDrill / examEveMode / tenMinutePlan / historyExport / mockExamHistory / customMockExam / readingReadAloud / qualificationCharacter(`registration_decisions` D5 は「共通の7機能」と書くが、その後 `qualificationCharacter` が追加された。矛盾ではなく更新)。
- [ ] 無料枠(D6)を適用する: 模擬試験 月1回・苦手分析 3分野・復習 1日10問・自動生成 1日10問(暫定。[pricing_policy.md](pricing_policy.md))。
- [ ] 設定などに `PremiumBenefitsCard`(`lib/ui/premium/premium_benefits_card.dart`)を置き、プレミアムでできることを一覧にする。
- [ ] 鍵のかかった入口は `onLockedTap` を渡して**購入導線**につなぐ(未指定だと案内だけが出る)。

## 3. キャラ(資格専用キャラ)

- [ ] `CharacterPack` に `requiresPremium: true` と `appIds: {'<資格id>'}` を設定(資格id は `UkalabCert` の綴り)。
- [ ] アプリの `ProviderScope` で `characterAppIdProvider.overrideWithValue('<資格id>')` と、`characterPremiumProvider.overrideWith((ref) => ref.watch(entitlementStateProvider).hasPremium)` を渡す(it_passport では `lib/data/character_wiring.dart`)。
- [ ] 画像は `assets/mascot/<キャラid>/` と、小物は `items/`(`<キャラid>_<小物名>.webp`)。形式・枚数は [../qualification_mascot_image_briefs.md](../qualification_mascot_image_briefs.md)。空ディレクトリは pubspec に登録しない(ビルドが壊れる)。
- [ ] 画像のメタデータを除去(OPSEC)。

## 4. cross_promo・Firebase

- [ ] Firebase 設定(`google-services.json`)は**リポジトリに置かない**。CI の Secret `GOOGLE_SERVICES_JSON_BASE64` から注入する(`build-aab.yml` / `release-android.yml` で確認)。
- [ ] 実キー(RevenueCat・広告ユニットID・API キー)をコミットしない。ビルド時注入(`--dart-define` / CI Secrets。D9)。

## 5. CI

- [ ] `web-e2e` ジョブの `runs-on` は **`ubuntu-24.04` 固定**。Playwright が ubuntu 26.04 の chromium に未対応のため。対応後に `ubuntu-latest` へ戻す(ci.yml にコメントあり)。
- [ ] 2026-10-23 時点、ローカルの `ukalab-g-kentei/.github/workflows/ci.yml` は `ubuntu-latest` のまま(古い作業コピーの可能性。要確認)。

## 6. ストア表記

- [ ] 「非公式」を明記。「公式」「本試験相当」「合格保証」は使わない。試験の主催団体・出版社の教材ではない旨を記す。
- [ ] 下書き: [../store_listing_drafts.md](../store_listing_drafts.md)。

## 7. OPSEC

- [ ] 個人名・メールアドレス・Drive URL・フォルダID を書かない(コード・docs・コミット・画像)。
- [ ] 画像(PNG/WebP)のメタデータ除去。作成者名・パス・アカウント情報なし。

## 8. 漢検は別扱い

[pricing_policy.md](pricing_policy.md) 参照(子ども向け設定・権利ID・prefs 名前空間)。
