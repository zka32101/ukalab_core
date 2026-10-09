# Changelog

破壊的変更は major を上げ、移行手順を記載する。タグは不変（付け替えない）。

## [0.17.0] - 2026-10-09

試験直前モード（企画: 追加差別化機能 §1・§3）。追加のみで、既存 API に破壊的変更はない。

### Added
- `nextExamDate` / `examEveStatus`: 今日以降で最も近い試験日と、試験直前モード
  （既定は試験日の3日前から。`examEveWindowDays`）の判定。時刻は無視して日付で数える
- `buildExamEveSet`: 直近の誤答・頻出・計算式のいずれかに当たる問題を、優先度の高い順に
  出題する。優先度 = 直近の誤答 4 ＋ 頻出 2 ＋ 計算式 1 ＋ 章の弱点スコア。出す理由
  （`ExamEveReason`）も返す。無効な問題は出さない
- `Question.tags` と `QuestionTag`（`frequent` 頻出・`formula` 計算式）: 出題の絞り込み用タグ（任意）
- `PremiumFeature` / `canUsePremiumFeature`: premium でだけ使える機能（弱点集中ドリル・
  試験直前モード・今日の10分プラン・学習履歴の書き出し）の一覧と判定

## [0.16.0] - 2026-10-09

弱点集中ドリルの最小版（企画: 追加差別化機能 §2）。追加のみで、既存 API に破壊的変更はない。
スコアの重みは暫定で、公開後の実測で調整する（`WeakScoreConfig`）。

### Added
- `computeWeakTopics`: 解答記録から弱い論点（章または章＋細目）を弱い順に並べる。
  スコア = Σ(解答の重み×弱さ) ÷ (Σ解答の重み＋底上げ)。解答の重みは新しいほど大きい
  （半減期14日）。弱さは誤答＝原因ラベルの重み、遅い正解＝0.5、速い正解＝0。
  `byChapter` で章単位に集計（表示用）。記録に論点が無い旧データは問題データから補う
- `WeakTopic`: 論点・スコア・解答数・誤答数・原因の内訳・最も多い原因（`dominantCause`）と
  処方（`prescription`）
- `WeakPrescription` / `prescriptionFor`: 原因別の処方（知識不足＝解説と用語カード／
  ひっかけ＝比較表示を先に／計算ミス＝計算ステップ／読み違い＝問題文に印）
- `buildWeakDrill`: 弱い論点の上位から、やさしい問題 → 難しい問題の順に出題を組む
  （既定10問・上位3論点。無効な問題は出さない）

## [0.15.0] - 2026-10-09

追加の差別化機能（誤答の原因ラベル・違いの比較表示・弱点集中ドリル）の土台。追加のみで、
既存 API・既存の保存データに破壊的変更はない（追加項目はすべて省略可能）。

### Added
- `WrongCause`: 間違えた理由（知識不足 / ひっかけ / 計算ミス / 読み違い）。
- `ProgressRecord`: 論点タグ（`topicId` 章・`subtopicId` 細目）、回答時間 `ms`、原因ラベル `cause` を
  任意項目として追加。旧データ（追加項目なし）も読める。型が合わない追加項目は捨て、必須項目は復元する。
- `Question.subtopicId`: 論点タグの細目（任意）。章は従来の `topicId`（必須）。
- `Question.compareWith`: 比較対象の用語ID（`Term.termId`）。違いの比較表示の元データ。
- `validateCompareTargets`: 比較対象IDの存在・重複・空の検査。`validate_content` に組み込み済み
  （`--terms` で渡した用語を基準にする）。

## [0.12.0] - 2026-10-05

簿記3級の補助簿（商品有高帳・現金出納帳など）記入向け。追加のみで、既存 API に破壊的変更はない。

### Added
- `QuestionType.ledger`: 補助簿記入問題タイプ（行×列グループ×項目のセル単位の数値入力）。
  `LedgerColumnGroup`（受入・払出・残高）・`LedgerField`（数量・単価・金額。数量・単価を
  使わない帳簿は金額のみ使う）・`LedgerCell`（記入行・列グループ・項目・値）・
  `LedgerRowMeta`（記入行の日付・摘要）・`LedgerAnswer`（`rows`＝記入行の固定情報、
  `givenCells`＝問題文で与える値、`blankCells`＝採点対象の正解セル）
- `judgeLedger`: 補助簿問題の正解とユーザー入力を、記入行×列グループ×項目の組み合わせで
  対応づけて比較し、セルごとに `correct` / `wrongValue`（値違い）/ `missing`（未入力）/
  `extra`（余分な入力）を判定
- `validateQuestions`: ledger型の検証を追加（`blankCells` が空でない、値1以上、セルが
  `rows` に存在する `rowIndex` を参照している、`givenCells`・`blankCells` 内でセル位置の
  重複がない）
- `scoreMockExam`: ledger型の問題を採点できるよう対応（`answers` に `List<LedgerCell>` を渡す）
- `PracticeSession.answerLedger`: 補助簿（type: ledger）の現在の問題に答え、`AnswerRecord`
  に記録する（`judgeLedger` の完全一致で正誤判定）

設計の詳細・対象範囲（移動平均法を優先し、複数ロットが並存する一般の先入先出法は
Phase 2.5として先送り）は `ukalab-boki3` の `docs/question_types_v1_design.md` を参照。

## [0.10.0] - 2026-10-04

簿記3級の精算表・財務諸表の穴埋め向け。追加のみで、既存 API に破壊的変更はない。

### Added
- `QuestionType.worksheet`: 表埋め問題タイプ（精算表・財務諸表などのセル単位の金額入力）。
  `WorksheetColumn`（残高試算表・修正記入・損益計算書・貸借対照表の借方/貸方、計8列）・
  `WorksheetCell`（勘定科目・列・金額）・`WorksheetAnswer`（`givenCells`＝問題文で与える値、
  `blankCells`＝採点対象の正解セル）
- `judgeWorksheet`: 表埋め問題の正解とユーザー入力を、勘定科目×列の組み合わせで対応づけて
  比較し、セルごとに `correct` / `wrongAmount`（金額違い）/ `missing`（未入力）/
  `extra`（余分な入力）を判定
- `validateQuestions`: worksheet型の検証を追加（`blankCells` が空でない、金額1以上、
  勘定科目が空でない、`givenCells`・`blankCells` 内でセル位置の重複がない）
- `scoreMockExam`: worksheet型の問題を採点できるよう対応（`answers` に `List<WorksheetCell>` を渡す）
- `PracticeSession.answerWorksheet`: 表埋め（type: worksheet）の現在の問題に
  `List<WorksheetCell>` で答える。正誤判定は `judgeWorksheet` の完全一致
  （`WorksheetJudgeResult.isCorrect`）。type不一致・セッション終了後は `StateError`

### Notes
- 財務諸表（貸借対照表・損益計算書）は精算表と列構成・科目の表示名が異なる場合がある
  （例: 「売上」→ 損益計算書では「売上高」）。今回は `WorksheetColumn` を共用する設計とし、
  差異が問題になった場合は専用の列挙値を別途検討する

## [0.9.1] - 2026-10-04

`PracticeSession`（演習セッション）の journal 型対応。追加のみで、既存 API に破壊的変更はない。

### Added
- `PracticeSession.answerJournal`: 仕訳（type: journal）の現在の問題に、ユーザーが入力した `List<JournalLine>` で答える。正誤判定は `judgeJournal` の完全一致（`JournalJudgeResult.isCorrect`）。type が journal 以外の問題や、セッション終了後に呼ぶと `StateError`
- `AnswerRecord`: `choiceIndex`・`journalLines` をどちらも省略可能にし、choice型は `choiceIndex`、journal型は `journalLines` を持つようにした
- `PracticeSession.answer`（choice用）に、type が choice 以外の問題へ呼んだ場合の `StateError` を追加（従来は無条件で `answerIndex` と比較していた）

## [0.5.0] - 2026-10-03

専門用語の解説（決定50「専門用語の解説（全アプリ共通）」）向け。追加のみで、v0.4 の API に破壊的変更はない。

### Added
- `Term`: 専門用語の解説カード（termId・term・headline・definition・analogy・commonMistake・relatedTermIds・relatedQuestionIds・diagramId・出典）
- `parseTermsJsonl`: JSON Lines（1行1用語）を読む。読めない行は issue に入れて続行する
- `validateTerms`: 配信前の品質ゲート。①〜③（headline・definition）が空でないか、関連用語・関連問題のリンク切れ、見出し語（表記）の重複、出典の有無、試験定義との整合を検査する

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
