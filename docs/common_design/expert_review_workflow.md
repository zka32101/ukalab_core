# 専門確認ワークフロー

## 流れ

1. AI下書きを入れる(`ai-draft`。[ai_draft_content.md](ai_draft_content.md))。
2. 確認用チェックリスト・優先リストを作る。各アプリの `docs/expert_review/*`(例: boki の `new_types_checklist.md` と `review_priority.csv`、otsu4 の `multi_angle_checklist.md`、infosecmanage の `docs/content_review_checklist.md`)。
3. 運営者が専門家へ渡す。依頼文・観点・回答表・反映方法は [../expert_review_requests.md](../expert_review_requests.md)。専門家に氏名・所属は求めない。
4. **人の確認後にマージ**: 確認が必要な変更は**ドラフト PR**で出す。人の確認が済むまでマージしない。
5. 返送された判定を別 PR で反映(`contentVer` 更新)。OK のみ `ai-draft` を外す。
6. 事実を新たに作らない。専門確認が必要な点は PR 本文に明記する([../DECISIONS.md](../DECISIONS.md) のレビュー運用)。

## 休眠中の新形式問題

○×(trueFalse)・空欄補充(cloze)・説明から用語(reverseLookup)の問題は、データを入れてあるが、各アプリの `kNewQuestionTypesEnabled = false`(コンパイル時定数)で**出題していない**。

| アプリ | 休眠中の件数(確認した記載) |
|---|---|
| G検定 | 48 問(要確認: ローカルの記載から) |
| 簿記3級 | 36 問(○×16・空欄補充12・逆引き8。`docs/expert_review/new_types_checklist.md`) |
| 危険物乙4 | 36 問(要確認) |

### 有効化の前の条件

- 当該問題の専門確認が済んでいる(`ai-draft` を外せる状態)。
- 模擬試験など全画面で新形式が動く。**簿記の模擬試験は新形式未対応**(`lib/mock_exam/mock_exam_page.dart` で新タイプの判定が常に false。確認済み)。他アプリの模擬試験は `kMockExamAllowedTypes` が従来の4タイプで、新タイプを出さない設計。
- 有効化は別 PR・ユーザーの明示指示で行う。
