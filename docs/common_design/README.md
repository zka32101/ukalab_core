# 共通設計(うかラボ全アプリ共通)

新しい資格アプリが増えても同じ方針で作れるように、最近決まった事項を記録する。決定のたびに追記する(運用は [decision_log.md](decision_log.md))。

状態: 2026-10-23 時点。事実は各リポジトリの `main` を読んで確認した。確認できないものは「要確認」と書く。

## 索引

| 文書 | 内容 |
|---|---|
| [decision_log.md](decision_log.md) | 決定ログの運用ルール・雛形・これまでの記録(CD-004 bike 価格、CD-005 bike 編入方針を含む) |
| [new_app_checklist.md](new_app_checklist.md) | 新資格アプリ追加チェックリスト(タグ固定・プレミアム・キャラ・cross_promo・CI・ストア表記・OPSEC・既存アプリ編入) |
| [experience_premium_pattern.md](experience_premium_pattern.md) | 体験型プレミアム教材の標準パターン(ストーリー型) |
| [ai_draft_content.md](ai_draft_content.md) | AI下書きコンテンツの扱い |
| [expert_review_workflow.md](expert_review_workflow.md) | 専門確認ワークフローと休眠中の新形式問題 |
| [pricing_policy.md](pricing_policy.md) | プレミアム・価格方針(暫定の明記) |
| [pr_rules.md](pr_rules.md) | PR・運用ルール |
| [experiments.md](experiments.md) | 検討中・試行(確定扱いにしない) |

## 既存文書との関係(重複は参照のみ)

- 日付別の決定: [../DECISIONS.md](../DECISIONS.md)
- 登録・課金の決定 D1〜D10: [../registration_decisions_2026-10-16.md](../registration_decisions_2026-10-16.md)
- 漢検の課金統一計画: [../kanken_billing_unification_plan_2026-10-17.md](../kanken_billing_unification_plan_2026-10-17.md)
- 資格専用キャラ: [../qualification_mascot_spec.md](../qualification_mascot_spec.md) / [candidates](../qualification_mascot_candidates.md) / [image_briefs](../qualification_mascot_image_briefs.md)
- 専門家レビュー依頼: [../expert_review_requests.md](../expert_review_requests.md) / [引継ぎ](../expert_review_session_handover.md)
- 問題の質の観点: [../question_quality_viewpoints.md](../question_quality_viewpoints.md)
- UI 部品の使い方(`StoryModeWidget` ほか): [../ui.md](../ui.md)
- 開発プレイブック(テスト・リリース・セキュリティ): `shared_core` リポジトリの `docs/DEV_PLAYBOOK.md`(別リポジトリ)
