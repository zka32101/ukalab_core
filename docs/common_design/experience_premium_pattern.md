# 体験型プレミアム教材の標準パターン

選択式問題とは別に、架空の場面で判断して学ぶ「ストーリー型」の教材を、各資格に1本ずつ置く。

## 型

- **部品**: core の `StoryModeWidget` / `StoryScenarioSpec` / `StoryChapterSpec` / `StoryChoiceSpec`(`lib/ui/ui_kit/story_mode.dart`。使い方は [../ui.md](../ui.md) の「ストーリー型の共通エンジン(決定38)」)。
- **流れ**: 場面の提示 → 判断(選択) → 解説(推奨かどうかと理由) → 結果・振り返り。点数で責めない。
- **データ**: シナリオは JSONL(`assets/experience/*.jsonl`。簿記は `assets/exam/boki3.company_scenarios.jsonl`)。アプリ側でモデル化して `StoryScenarioSpec` に変換する。
- **無料/プレミアム**: シナリオ一覧の**最初の2本は無料、残りはプレミアム**。判定は `entitlementStateProvider` の `hasPremium`。鍵のかかったシナリオには**鍵アイコン**を出し、タップすると案内の SnackBar を出す(it_passport: `it_staff_story_screen.dart` / `kItStaffPremiumNotice`)。購入導線は `onLockedTap` 方式に揃えるのが望ましい(要確認: 全アプリで揃っているか)。
- **関連用語**: 各章・選択に `termId` を持たせ、用語カードへリンクする(用語は `assets/terms/*.jsonl`、決定50)。存在しない `termId` は検証テストで落とす。
- **ステータス**: 専門確認前は [ai_draft_content.md](ai_draft_content.md) に従う。

## 実装済みの例(2026-10-23 時点、ローカルの作業コピーで確認)

| 資格 | 名称 | データ |
|---|---|---|
| 日商簿記3級 | 会社経営モード | `boki3.company_scenarios.jsonl`(無料枠は最初の2つ、残りは premium=`registration_decisions` D4) |
| ITパスポート | 会社のIT担当1年目 | `it_staff_story_it_passport.jsonl` |
| 情報セキュリティマネジメント | インシデント対応30分 | `incident_30min_info_security.jsonl` |
| 危険物乙4 | 現場の1日(職場別) | `field_day_workplaces_hazmat4.jsonl` |
| G検定 | AIプロジェクト経営モード | `story_mode_g_kentei.jsonl`(G検定は他にも体験型教材多数) |

生成AIパスポート・漢検での有無は要確認。

## 新資格で作るとき

1. 架空の会社・人物にする(実在の企業・人物・試験問題を使わない)。
2. 1シナリオは数章。各章で「推奨の判断」と「理由」を必ず持つ。
3. 最初の2本を無料にし、残りを premium にする。
4. `contentStatus: ai-draft` で入れ、専門確認後に外す。
