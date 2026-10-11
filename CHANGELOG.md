# Changelog

破壊的変更は major を上げ、移行手順を記載する。タグは不変（付け替えない）。

## [0.37.0] - 2026-10-10

バックアップの部品が非同期の保存先を読めるようにする。追加のみ。

### Added
- `DataPart.export` が `FutureOr<Object?>` を返せる。`encodeLearningDataBackupAsync`（非同期の部品も扱える書き出し）。`DataManagementSection` の「書き出す」はこちらを使う
- 既存の `encodeLearningDataBackup`（同期）は変わらない。非同期の部品があれば `StateError`

## [0.36.0] - 2026-10-10

バックアップの読み込みで、共通化前の旧形式を読めるようにする。追加のみ。

### Changed
- `restoreLearningDataBackup` / `DataManagementSection` の読み込み: `parts` を持たない旧形式（`version` と並んで項目がトップレベルに並ぶ形）も、項目を部品のidとして読む。共通化前に書き出したバックアップを、そのまま読み込める

## [0.35.0] - 2026-10-10

学習データのバックアップ・リセットを共通化する。追加のみ。

### Added
- `package:ukalab_core/ui.dart`: `DataPart`（バックアップ・リセット対象の学習データ1つ分。id・export・restore・reset）、`encodeLearningDataBackup` / `restoreLearningDataBackup` / `resetLearningData`、`DataManagementSection`（設定画面の「データの管理」: 書き出す・読み込む・リセット）。バックアップに無い部品は触らないので、後から部品を足しても古いバックアップを読める

## [0.34.0] - 2026-10-10

`app_common_kit` を v1.9.0 → v1.10.0 に追従する。

### Changed
- `app_common_kit` が追加した `KitSectionHeader`・`MinutesBadge`・`PremiumLockTrailing`・`CountdownProgressBar` を、依存の更新により利用可能にする（本体に変更なし）

## [0.33.0] - 2026-10-10

受験日（利用者入力）の保存と状態を共通化する。追加のみ。

### Added
- `package:ukalab_core/exam_date.dart`: `ExamDateStore`（アプリID別の端末内保存）、`ExamDateNotifier` / `examDateProvider` / `examDateStoreProvider`。`ui.dart` には含めない（独自の同名プロバイダーを持つアプリとの衝突を避けるため。使うアプリが明示的に import する）

## [0.32.0] - 2026-10-10

ブックマーク・メモの導入配線を共通化する。追加のみ。

### Added
- `package:ukalab_core/ui.dart`: `studyNotesOverrides(appId)`（3サービスを読み込んで ProviderScope の override を返す。main() で1回呼ぶだけ）、`StudyNotesHomeCards`（ホームの「ブックマーク」「自分用メモ」カード）

## [0.31.0] - 2026-10-10

ブックマークの一覧画面を共通化する。追加のみ。

### Added
- `package:ukalab_core/ui.dart`: `BookmarkedQuestionsScreen`（ブックマークした問題の一覧。タグで絞り込み・「タグを編集」・タップで詳細。読み取り専用で、続けて演習する画面は各アプリで作る）。`bookmarkServiceProvider` / `bookmarkTagServiceProvider` の override が前提

## [0.30.0] - 2026-10-10

ブックマーク・メモの部品と画面を共通化する。追加のみ。

### Added
- `package:ukalab_core/ui.dart`: `BookmarkToggleButton`（しおりボタン）/ `QuestionMemoField`（自分用メモの入力欄。フォーカスが外れたら保存）/ `QuestionDetailScreen`（読み取り専用の問題詳細。解説は `explanationBuilder` で差し替え可）/ `MemoListScreen`（メモの一覧。問題は `loadQuestions` で読み込む）
- いずれも `bookmarkServiceProvider` / `questionMemoServiceProvider` の override が前提

## [0.29.0] - 2026-10-10

ブックマークのタグ編集画面を共通化する。追加のみ。

### Added
- `package:ukalab_core/ui.dart`: `BookmarkTagEditScreen`（問題ごとのタグの追加・削除。`bookmarkTagServiceProvider` の override が前提）

## [0.28.0] - 2026-10-10

`app_common_kit` を v1.5.0 から v1.9.0 に上げる。機能の追加・変更はない。
アプリがキットの新しい部品（解答時の音と触覚 `AnswerFeedback` など）を使うには、core も同じ kit のタグに揃える必要がある（pub は kit のタグが食い違うと解決できない）。

### 移行
- アプリは `ukalab_core` を `v0.28.0`、`app_common_kit` を `v1.9.0` に上げる

## [0.27.0] - 2026-10-10

otsu4 にあった「ブックマーク・タグ・問題メモ・検索」のデータ部分を共通化する。追加のみで、既存 API に破壊的変更はない。画面（一覧・編集）は次の版で足す。

### Added
- `package:ukalab_core/ukalab_core.dart`（純Dart）: `filterByBookmark` / `searchQuestions` / `filterMemoedQuestions` / `allBookmarkTags`
- `package:ukalab_core/ui.dart`（Flutter）: `BookmarkService` / `BookmarkTagService` / `QuestionMemoService`（と、それぞれの Notifier・provider・保存先）。保存先は端末内 `SharedPreferences*Store(アプリID)`。キーは `ukalab_<アプリID>_bookmarks` / `_bookmark_tags` / `_question_memos`（otsu4 の従来のキーと同じなので、保存済みの値がそのまま読める）

## [0.26.0] - 2026-10-10

`app_common_kit` を v1.0.0 から v1.5.0 に上げる。機能の追加・変更はない。
アプリが kit v1.5.0（音声読み上げの共通部品 `hands_free_tts.dart`）を使うには、core も同じ kit のタグに揃える必要がある（pub は kit のタグが食い違うと解決できない）。

### 移行
- アプリは `ukalab_core` を `v0.26.0`、`app_common_kit` を `v1.5.0` に上げる

## [0.25.0] - 2026-10-10

otsu4 にあった受験日まわりの純Dartの計算を共通化する。追加のみで、既存 API に破壊的変更はない。

### Added
- `daysUntilExam`: 受験日までの残り日数（日付のみで数える。当日は 0、過去は負）
- `examCountdownText`: 残り日数からホームに出す文言
- `studyPlanQuestionsPerDay`: 残り日数と未解答数から、1日あたりの目安解答数

## [0.24.0] - 2026-10-10

app_common_kit v1.0.0 で、うかラボ専用の UI をこのパッケージへ移した。**Flutter パッケージになる**（純Dartのエンジンと検証CLIはそのまま使える）。

### Added
- `package:ukalab_core/ui.dart`（Flutter）: 推し（`mascot/`）・衣装/着せ替え/共有カード（`outfit/`）・学習コイン（`coin/`）・学習の引き継ぎ（`transfer/`）・`UkalabTheme`/`UkalabPalette`・学習ラボ系の部品（機械学習ラボ・畳み込み・NN組み立て・注意の可視化・AI動向・手法の選び方・評価指標・ストーリー・境界・失敗ギャラリー・予測実行・ルート）・`UkalabShell`・`CoinBreakdownCard`・`ReadinessProgressCard`・`TeachMascot`
- `UkalabScope`: 推しのセリフの差し替え（app_common_kit の `KitStringsScope.mascotLines` の移動先）
- マスコットの画像（`assets/mascot/`、`package: 'ukalab_core'`）。テストも移した

### Changed
- `pubspec.yaml`: Flutter と `app_common_kit` v1.0.0 に依存。CI は Flutter 版（`flutter analyze`/`flutter test`）
- `package:ukalab_core/ukalab_core.dart` は従来どおり純Dart。`validate_content` は変わらず `dart run ukalab_core:validate_content` で動く

### 移行（app_common_kit v0.30 までから）
- アプリは、`app_common_kit` を `v1.0.0`、`ukalab_core` を `v0.24.0` に上げる
- `import 'package:ukalab_core/ui.dart';` を足す（`mascot`・`outfit`・`coin`・テーマ・学習ラボの import 元が変わる）
- 推しのセリフを差し替えていたら、`KitStringsScope(mascotLines:)` を `UkalabScope(mascotLines:)` に

## [0.23.0] - 2026-10-09

アプリごとに重複していた純Dartの処理を共通化する。追加のみで、既存 API に破壊的変更はない。

### Added
- `appendHistory` / `historyRecordFor` / `encodeHistory` / `decodeHistory` / `historyCsv` / `historyMaxRecords`:
  解答履歴の追記（上限で古いものを捨てる）・保存形式・CSV。端末への保存（SharedPreferences など）はアプリ側
- `effectiveExamDates` / `encodeExamDate` / `decodeExamDate`: 利用者入力の受験日を試験定義より優先する選び方と保存形式

## [0.22.0] - 2026-10-09

パッケージ名を `yourwish_kentei` から `ukalab_core` に改名する（命名ルール: うかラボ専用の基盤は `ukalab_` 接頭辞）。
機能の追加・変更はない。**破壊的変更**: Dart のパッケージ名が変わるため、利用するアプリは次の移行が必要。

### 移行手順
1. `pubspec.yaml` の依存のキーを `yourwish_kentei:` から `ukalab_core:` に変え、`ref` を `v0.22.0` にする。
   `url` は改名前の `https://github.com/zka32101/yourwish_kentei.git` のままでも動く。
   リポジトリを `ukalab_core` に改名した後は、GitHub が旧URLを転送する（新URLに直すのが望ましい）。
2. `import 'package:yourwish_kentei/yourwish_kentei.dart';` を `import 'package:ukalab_core/ukalab_core.dart';` に置き換える。
3. 問題データの検証は `dart run ukalab_core:validate_content ...` に変える。

## [0.21.0] - 2026-10-09

違いの比較表示の自動生成、今週の弱点トップ・弱点の推移、`validate_content` への組み込み
（企画: 追加差別化機能 §1・§2、決定事項ログ追補3）。追加のみで、既存 API に破壊的変更はない。

### Added
- `buildComparison` / `ComparisonView` / `ComparisonRow`: 問題の比較対象タグ（`compareWith`）から、
  正解の用語（`Term.relatedQuestionIds` にその問題を持つ用語）と紛らわしい相手の用語を並べた
  違いの比較表示を自動生成する。無効・未定義・重複は除き、2つに満たなければ null
- `weeklyWeakTop`: 今週の弱点トップ（章単位、既定3件）
- `weakTrend` / `WeakTrend`: 章ごとの弱点スコアの推移（今と1週間前を、それぞれその時点までの
  解答で計算して比較。自分の過去との比較のみ）
- `validate_content`: `--update-log`・`--next-steps`・`--checklist` を追加。CI のサンプル検証にも
  `example/sample_update_log.jsonl`・`sample_next_steps.jsonl`・`sample_checklist.jsonl` を追加

## [0.20.0] - 2026-10-09

学習履歴の書き出し（企画: 追加差別化機能 §1・§3。premium 機能 `PremiumFeature.historyExport`）。
追加のみで、既存 API に破壊的変更はない。

### Added
- `summarizeByDay` / `DailyStudySummary`: 解答記録を日付ごと（解答数・正答数・学習時間）にまとめる
- `summarizeByTopic` / `TopicAccuracy`: 分野（章）ごとの解答数・正答率。論点が無い旧データは問題データから補う
- `dailySummaryCsv` / `topicAccuracyCsv`: CSV にする（ヘッダー付き、正答率は%で小数1桁、
  カンマ・引用符・改行は引用符で囲む）。氏名・ユーザーID・端末情報・問題IDは含めない。
  PDF 出力と、保存・共有の画面はアプリ側

## [0.19.0] - 2026-10-09

更新ログ・合格後の次の一手・試験当日チェックリスト（企画: 追加差別化機能 §1）。追加のみで、
既存 API に破壊的変更はない。いずれも配信データの構造・読み込み・配信前検証と、画面が使う
最小の関数だけを持つ（画面はアプリ側）。

### Added
- `UpdateLogEntry` / `UpdateKind` / `recentUpdates` / `parseUpdateLogJsonl` / `validateUpdateLog`:
  「法改正で◯問を差し替えた」を見える化する更新ログ。法改正・シラバス改訂には根拠の版
  （`versionRef`）が必須。一覧は新しい順で、未来の予定と古い更新（既定90日超）を除く
- `NextStepRule` / `suggestNextSteps` / `parseNextStepsJsonl` / `validateNextSteps`:
  合格後に提案する関連資格の対応表。公開済みの資格だけを提案する
- `ChecklistItem` / `ChecklistCategory` / `ExamVenueKind` / `checklistFor` / `unconfirmedItems` /
  `ChecklistProgress` / `parseChecklistItemsJsonl` / `validateChecklistItems`: 試験当日チェックリスト。
  自宅（オンライン）／会場で項目を出し分け。公式で未確認の項目は `officialConfirmed: false`
  のままにして、画面で「公式で要確認」と出す

## [0.18.0] - 2026-10-09

今日の10分プラン（企画: 追加差別化機能 §1・§3）。追加のみで、既存 API に破壊的変更はない。

### Added
- `QuestionTimeEstimator`: 問題1問にかかる時間（秒）の目安。同じ問題の回答時間の平均 →
  同じ章の平均 → 問題タイプごとの既定値（選択式45秒・仕訳120秒・表埋め/補助簿300秒）の順。10〜900秒に収める
- `buildTimeBoxedPlan` / `TimeBoxedPlan`: 空き時間（分）に収まる問題セットを組む。優先順は
  `firstQids`（試験直前モードの出題など）→ 弱点集中ドリル → 直近で間違えたまま → 未回答
  （やさしい順）→ 残り。残り時間に収まらない問題は飛ばし、後ろの短い問題を入れる

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
