# プレミアム・価格方針

## 暫定である旨

- 価格 **noads ¥480 / premium ¥1,500**(買い切り)、および無料枠(模擬試験 月1回・苦手分析 3分野・復習 1日10問・自動生成 1日10問)は**暫定**。公開後の実測で見直す。
- **勝手に変更しない**。変更はユーザーの指示があったときだけ。
- 注: [../registration_decisions_2026-10-16.md](../registration_decisions_2026-10-16.md) は D2 を「確定」と書いている。「暫定」との表現の違いは PR 本文に列挙した。ユーザーの今回の指示(暫定)を優先して本書は暫定と書く。

## 漢検は別扱い

- 子ども向けのため、広告は `childDirected` などの設定(最大G・非パーソナライズ・保護者ゲート)を**常に維持**する(D8)。
- 権利ID(entitlement ID)は現状 `ad_free` / `premium`(RevenueCat では作成後に変更できない)。他の6本は `noads` / `premium`。統一計画は [../kanken_billing_unification_plan_2026-10-17.md](../kanken_billing_unification_plan_2026-10-17.md)。
- 商品ID・課金モデル(サブスク2段 → 買い切り2種にするか)は運営者の選択待ち(案A/B)。
- 端末内保存(SharedPreferences)の名前空間も他アプリと別。他アプリとキーを共有・移行しない。具体的なキー名は要確認。
- applicationId は `com.yourwish.ukarulab.kanji` のまま変えない(Play 登録済みのため)。
- 漢検のコイン配線は別扱い(DECISIONS.md)。

## 共通の考え方

- 買い切り2種。期間パスは採らない(D3)。
- コインは現金購入なし。衣装は通常 200 コイン(DECISIONS.md)。
