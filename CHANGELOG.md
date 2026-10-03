# Changelog

破壊的変更は major を上げ、移行手順を記載する。タグは不変（付け替えない）。

## [0.4.0] - 2026-10-03

危険物乙4（法令15問・物理化学10問・性質消火10問のように科目ごとに固定数を出題する試験）向け。追加のみで、v0.3 の API に破壊的変更はない。

### Added
- `LevelConfig.subjectQuestionCounts`: 科目別の出題数配分（`Map<String, int>`、subjectId → 問数）。省略すると従来どおり全体から `questionCount` 問を抽出する。指定する場合は値の合計が `questionCount` と一致すること、キーが `subjects` に存在することを検証する
- `pickMockExamQuestions`: 模擬試験の出題を選ぶ関数。`subjectQuestionCounts` があれば科目ごとにその数だけ、無ければ全体からランダムに抽出する（無効=disabledの問題は除く。科目の問題が不足する場合は例外にせずあるだけ返す）

## [0.3.0] - 2026-10-02

簿記3級（仕訳）向け。追加のみで、v0.2 の API に破壊的変更はない。

### Added
- `QuestionType.journal`: 仕訳問題タイプ。`JournalSide`（debit/credit）・`JournalLine`（side・account・amount）・`JournalAnswer`（複合仕訳＝行の配列）
- `judgeJournal`: 仕訳の正解とユーザー入力を比較し、行ごとに `correct` / `wrongAccount`（科目違い）/ `wrongAmount`（金額違い）/ `sideSwapped`（貸借逆）/ `missing`（不足）/ `extra`（余分）を判定。入力中の貸借合計一致（`balanced`）も返す
- `validateQuestions`: journal型の検証を追加（行が空でない、金額1以上、勘定科目が空でない、借方合計＝貸方合計）。choice型の検証（選択肢数・正解の一意性など）は従来どおり type が choice の問題にのみ適用
- `scoreMockExam`: journal型の問題を採点できるよう `answers` の値の型を `int?` から `Object?` に広げた（choice型は `int`、journal型は `List<JournalLine>` を渡す）。既存の `Map<String, int?>` の呼び出しはそのまま動く

### Notes
- `PracticeSession`（演習セッション）はまだ choice 型専用（`answer(int choiceIndex)`）。journal型の演習は、アプリ側で `judgeJournal` を直接呼ぶか、対応は次回以降

## [0.2.0] - 2026-10-02

### Added
- `UsageQuota` / `QuotaPeriod` / `KeyValueStore`: 期間（日・月）ごとの回数制限。日付・月が変わると自動でリセット。保存先は注入（コアは純Dartのまま）
- `FreeTierLimits`: 無料版の線引き（暫定）。模擬試験は月1回、苦手分析は上位3分野、復習は1日10問、自動生成問題は1日10問。プレミアムは無制限。noads のみの人は無料と同じ扱い

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
