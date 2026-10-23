# PR・運用ルール

- **小さな PR** にする(1つの目的ごと)。docs だけの PR はコード・pubspec バージョン・タグに触れない。
- **マージは、CI が全て成功したあと、ユーザーの明示的な「マージ」の指示があるときだけ**([../DECISIONS.md](../DECISIONS.md))。AI は自分でマージしない。
- **タグ(vX.Y.Z)は明示指示があるときだけ**付ける。
- **force-push 禁止**。履歴は追加コミットで直す。
- 専門確認が必要な変更は、人の確認後にマージするドラフト PR にする([expert_review_workflow.md](expert_review_workflow.md))。
- 事実を新たに作らない。不確かな点は PR 本文に明記する。
- コミット・PR に個人名・Drive URL・実キーを書かない([new_app_checklist.md](new_app_checklist.md) の OPSEC)。
- 集計・レビューは最新の `origin/main` で行う(ローカルの作業コピーは古いことがある)。
