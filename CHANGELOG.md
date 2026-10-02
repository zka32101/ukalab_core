# Changelog

破壊的変更は major を上げ、移行手順を記載する。タグは不変（付け替えない）。

## [0.1.0] - 2026-10-02

土台（純Dart。UI・Firebase・課金・広告はまだ載せていない）。

### Added
- `ExamConfig` / `LevelConfig` / `SubjectConfig` / `PassRule`: 試験定義（JSON）。不正な定義は `FormatException`
- `Question`: 問題モデル（選択式）。出典区分 `original` / `statute` / `licensed`、配点、無効フラグ
- `validateQuestions` / `parseQuestionsJsonl`: 配信前の品質ゲート（出典必須、ID重複、選択肢数、正解の一意性、statute→lawVersion、licensed→license、試験定義との整合）
- `scoreMockExam`: 模擬試験の採点と合否判定（総合の合格ライン、科目別の足切り、「あと◯点」、足切りで不合格の判別）
- `Srs`: 間隔反復（Leitner 6段階）
- `PracticeSession`: 演習1回分（seed による再現可能な出題順、優先問題、解答記録）
- `bin/validate_content`: 問題データ検証 CLI（問題があれば終了コード1）
- GitHub Actions CI（analyze・test・サンプルデータ検証）
