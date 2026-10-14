# Changelog

破壊的変更は major を上げ、移行手順を記載する。タグは不変（付け替えない）。

## [Unreleased]

- tools/docs/CI のみ（Dart の公開 API・バージョンは変更なし、タグ不要）: 断定語バランスの集計 `tools/question_quality/assertive_word_bias.py`、両ツールをまとめて実行する `run_checks.py`、各アプリから呼べる再利用可能ワークフロー `.github/workflows/question-quality.yml`（警告のみ）、単体テストを追加。

## [0.71.1] - 2026-10-14

文字を大きくした・幅の狭い端末（320dp・280dp、文字 200〜300%）で、文字が切れる・はみ出す箇所を直す。公開 API（コンストラクタ・シグネチャ）の変更なし。

### Fixed
- `HomeSectionHeader` / `HomeSection`: 右側の `trailing` を幅の半分までにして折り返す（題名を押しつぶさない・はみ出さない）
- `HomeMenuTile` / `HomeMenuGrid`: `HomeMenuBadge.label` の長い文言が行を押し出していたのを、バッジ幅に上限（80dp）を付けて折り返すように
- `WeakSummaryCard`: 回数・推移の文言（右側）が長いときに章名を押しつぶして溢れていたのを、幅に上限を付けて折り返すように
- `MistakeNoteView`: 見出し・説明・お祝い・絞り込みの部分を高さの半分までにして超えた分はスクロール（文字が大きいと一覧の場所が無くなり溢れていた）
- `showOshiMedalDialog` / `showOshiGiftDialog`: `AlertDialog(scrollable: true)` にして、題名・ボタンまで含めてスクロールできるように
- `OshiMedalShareCard` / `PassShareCard`: 共有する「画像」なので文字倍率を固定（端末の文字サイズで 4:5 の枠からはみ出す・極端に縮むのを防ぐ。標準倍率の見た目は変わらない）
- `GlossaryListView`: 用語の「ひとこと」を 1 行 → 2 行まで表示。分野チップの行の高さを文字倍率に合わせ、チップが上下に切れないように
- `MlLabWidget` / `NnBuilderWidget`: クラス凡例を `Row` → `Wrap`（大きい文字で溢れていた）。`LegendMark` のラベルは `Flexible`
- `HyperParamSlider` / `ConfusionMatrixLabWidget` / `PredictRunWidget`: 数値表示の固定幅を文字倍率に合わせて広げる（桁が縦に折れていた）

### Tests
- `test/ui/text_overflow_test.dart` を追加（幅 320/280 × 文字倍率 1/2/3、長い文言で、共通 UI 部品の描画エラーを検査）

### 移行
- 不要（自動で反映）。`app_common_kit` のピンは v3.10.0 のまま（kit 側の同種の修正は kit v3.10.1）。

## [0.71.0] - 2026-10-14

app_common_kit を v3.9.0 → v3.10.0 に追従する。core のコード変更はない。

### Changed
- `app_common_kit` のピンを v3.9.0 → v3.10.0 に。kit 側は追加のみ（`SettingsScreen(showTextScale:)`、`loadKitPreferences()`、`WhatsNewGate`）。アプリごとの配線をキットに寄せた

### 移行
- アプリは `ukalab_core` を `v0.71.0`、`app_common_kit` を `v3.10.0` に上げる

## [0.70.0] - 2026-10-14

app_common_kit を v3.5.0 → v3.9.0 に追従する。core のコード変更はない。
アプリがキットの新しい部品を使うには、core も同じ kit のタグに揃える必要がある（pub は kit のタグが食い違うと解決できない）。

### Changed
- `app_common_kit` のピンを v3.5.0 → v3.9.0 に。kit 側は追加のみ（v3.6.0 更新内容の表示 `WhatsNew`、v3.7.0 機能フラグ `FeatureFlags`、v3.8.0 アプリ内の文字サイズ `AppTextScale`、v3.9.0 バックアップ/復元 `BackupService`）。core は kit を `export` していないので、アプリが `package:app_common_kit/app_common_kit.dart` から import する

### 移行
- アプリは `ukalab_core` を `v0.70.0`、`app_common_kit` を `v3.9.0` に上げる

## [0.69.0] - 2026-10-13

推しの成長演出を追加（追加のみ。既存 API は変更しない）。アプリが渡す累計の学習量（回答数・学習日数）に応じて推しの反応が段階的に変わり、節目に到達したら一度だけ祝う。煽らない・休んでも責めない（学習日数は連続ではなく合計。累計は減らないので段階も下がらない）。

### Added
- 純 Dart（`ukalab_core.dart`）
  - `OshiGrowthEngine`: `stageOf(progress)`（5 段階 `OshiGrowthStage`: newcomer / budding / growing / blooming / radiant。回答 10/100/300/1000 問・学習 7/30/100 日で上がる。進んでいる方で決まる）、`reaction(progress, seed:, salt:)`（表情の絵文字・ラベル・一言）、`newlyReached(progress, alreadyCelebrated:)`、`reached`、`headlineOf`、`celebrate(milestone)`
  - `OshiGrowthProgress`（`totalAnswered` / `studyDays`。負値は 0）、`OshiGrowthMilestone`（`answered(10/50/100/300/1000)` / `days(7/30/100)`。ID は `answered_10` / `days_7`。`milestones:` で差し替え可）
  - `OshiGrowthStrings`（ja・en、`copyWith`、`allTexts`。`UkalabStrings` は変えない）。責める・煽る語は禁止語リストでテスト
- UI（`ui.dart`、`lib/ui/oshi_growth/`）
  - `OshiGrowthBubble`: `OshiMessageBubble` と同じ見た目の吹き出し。表情＋ラベル＋一言、タップで別の一言
  - `OshiGrowthCelebrationCard` / `showOshiGrowthDialog`: 節目の祝福（閉じるボタンだけ）。「動きを減らす」対応
  - `OshiGrowthStore`（`InMemoryOshiGrowthStore` / `SharedPreferencesOshiGrowthStore(appId)`、キー `ukalab_oshi_growth_<appId>`）と `OshiGrowthService`（`check` / `checkHeadline`。保存に失敗したら記録せず次回また祝える。複数の節目を同時に迎えても祝福は 1 件）

### Tests
- `test/oshi_growth_test.dart`（段階の境界・節目の一度だけ・冪等・ストア・禁止語）、`test/oshi_growth_views_test.dart`（幅 320・文字 2 倍でオーバーフローなし、reduce motion、セマンティクス、ja・en）

## [0.68.0] - 2026-10-13

復習の自動出題（間隔反復の強化）を追加（追加のみ。既存 API は変更しない）。

### Added
- `lib/progress/review_scheduler_engine.dart`（`ukalab_core.dart` から export）
  - `ReviewSchedulerEngine`: 間違いノート（`MistakeNoteEntry`）の「これから」の問題を、間隔 1/3/7/14/30 日（`intervals` で変更可）の簡易ボックス方式で「今日の復習」にする純 Dart ロジック。正解で次の段、不正解で1段戻る、最後の段の正解で卒業。`sync` / `review` / `applyResult` / `due(max:)` / `dueCount` / `isDue`。日付は暦日、同じ入力なら同じ結果（冪等・決定的）
  - `ReviewItem`: 問題ID・段・次回の日・最終復習・卒業・分野ID（JSON 往復。壊れた入力は null）
- `lib/progress/review_scheduler_strings.dart`: `ReviewSchedulerStrings`（ja・en。`copyWith` 可。禁止語リストでテスト）
- `lib/ui/review_scheduler/`（`ui.dart` から export）
  - `TodayReviewCard`: ホーム用カード。件数と「やってみる」（`onStart` コールバック注入）。0 件は静かな「おやすみ」表示。警告色・赤字は使わない。幅 320・文字 2 倍で確認
  - `ReviewSchedulerStore` / `InMemoryReviewSchedulerStore` / `SharedPreferencesReviewSchedulerStore`（キー `ukalab_<アプリID>_review_schedule`）/ `reviewSchedulerDataPart`（バックアップ内のキー `reviewSchedule`）

### Notes
- 既存の `Srs`（`lib/engine/srs.dart`。箱0=すぐ再出題の Leitner 方式、全問題の履歴向け）・`review_priority.dart`・`MistakeNoteEngine` は変更しない。重複を避けるため、新エンジンは `MistakeNoteEntry` を入力にして「間違いノートの復習日程」だけを持つ。連携方法は docs/review_scheduler.md

### Tests
- `test/review_scheduler_test.dart`（エンジン・JSON・ストア・DataPart・文言）、`test/ui/today_review_card_test.dart`（表示・0 件・色・幅 320 かつ文字 2 倍・Semantics）

## [0.67.0] - 2026-10-13

模擬試験の結果分析を追加（追加のみ。既存 API は変更しない）。

### Added
- `lib/engine/mock_exam_analysis_engine.dart`: `MockExamAnalysisEngine`（純粋ロジック）。`MockExamAnswer(topicId, correct)` のリストから、分野別の正答率・伸びしろのある分野（弱点）・次にやる分野（最大1〜3件）を出す。何も保存しない
- `lib/engine/mock_exam_analysis_strings.dart`: `MockExamAnalysisStrings`（ja・en。「今日はここを少しだけ」調）
- `lib/ui/mock_exam_analysis/`: `MockExamAnalysisCard` / `MockExamAnalysisScreen`（`ui.dart` から export）。分野名は `topicLabel` で渡す

### Tests
- エンジン（集計・弱点・次の分野・空/全部得意）、文言の禁止語、カード/画面（幅320・文字2倍でオーバーフローなし）

## [0.66.0] - 2026-10-13

app_common_kit を v3.1.0 → v3.5.0 に追従。ながらセッションの `onAnswered(question, chosen, correct)` が使える（kit PR #140）。

### Changed
- `app_common_kit` のピンを v3.1.0 → v3.5.0 に（`pubspec.lock` も該当行のみ）。kit v3.1.0→v3.5.0 は追加のみ（破壊的変更・新しい required 引数・依存パッケージの追加なし）で、core のコード変更は不要。core に同名の型はなく名前衝突なし
- kit v3.5.0: ながらセッションに `onAnswered(question, chosen, correct)`（`NagaraSessionController` / `NagaraSessionView`）。正答を含む全てのタップ回答を返す。呼び出し順は解答確定 → `onAnswered` → （誤答なら）`onWrongAnswer`、1 問につき最大 1 回。未回答・スキップでは呼ばない。既存の `onWrongAnswer` / `onUnanswered` / `onFinished` の意味は変わらない
- 取り込んだ kit v3.2.0〜v3.4.0（いずれも追加のみ）:
  - v3.2.0: 同意管理 `ConsentController`（未回答は「同意なし」。`ConsentBinder` / `showConsentPrompt` / `showConsentSettings` / `SettingsScreen(consent:)`）
  - v3.3.0: 保護者ゲート `ParentalGateDialog` / `requireParentalGate`（別の入口 `package:app_common_kit/parental_gate.dart`、`app_common_kit.dart` からは出さない）
  - v3.4.0: 診断情報つき不具合報告（`DiagnosticsCollector` / `DiagnosticLog` / `FeedbackFormPage(collectDiagnostics:)`、`scrubText`）。診断情報を Issue に載せるには、各アプリが `functions/src/feedback-issue.ts` を更新して配備する必要がある（core は functions を持たない）

### Tests
- `test/kit_nagara_reexport_test.dart`: `onAnswered(question, chosen, correct)` をコントローラ生成時に引数として渡せること（型を含む）を確認

## [0.65.0] - 2026-10-13

ホーム画面を「わかりやすく分類分け」するための共通 UI 部品を追加（追加のみ。既存 API は変更しない）。文言は持たず、見出し・ラベルはアプリが渡す（`UkalabStrings` / `HomeStrings` は不要なので追加しない）。

### Added
- `lib/ui/home/home_sections.dart`（`ui.dart` から export）
  - `HomeSectionHeader`: タイトル・補足・leading（アイコン/絵文字）・trailing。`Semantics(header: true)`
  - `HomeMenuTile` / `HomeMenuBadge`（`dot` / `count`（99+）/ `label`（NEW 等）/ `premium`）: 1 列版、最小タップ領域 48dp
  - `HomeMenuItem` / `HomeMenuGrid`: 2 列コンパクトグリッド。幅 360 未満または文字倍率 1.3 超で 1 列にフォールバック
  - `HomeSection`: 見出し + 子。`collapsible` / `initiallyExpanded`。開閉の保存はアプリ側（`expandedListenable` / `onExpandedChanged`）、core は永続化しない。「動きを減らす」では開閉アニメーションなし
- 色・角丸は ColorScheme から取得（ダーク対応）。`test/home_sections_test.dart`

## [0.64.0] - 2026-10-13

app_common_kit を v3.1.0 に追従（PR #135 のながらセッション）。ながらセッション（`NagaraSessionController` / `NagaraSessionView` / `AwaitableSpeechBackend` / `HandsFreeSettings` の `thinkSeconds`・`betweenSeconds`・`autoAdvance` / `KitStrings.nagara`）は kit v3.1.0 から提供され、core は再エクスポートのみ（ここでは何も実装しない）。

### Changed
- `app_common_kit` のピンを v3.0.0 → v3.1.0 に（`pubspec.lock` も該当行のみ）。kit 側は追加のみで、core のコード変更は不要。core は kit を `export` していないため、アプリは従来どおり `package:app_common_kit/app_common_kit.dart` から import する（`NagaraSessionView` のみ flutter_tts 依存のため `package:app_common_kit/hands_free_tts.dart`）。名前衝突なし（core に同名の型なし）

### Added
- `test/kit_nagara_reexport_test.dart`: core の依存経由で kit v3.1.0 のながらセッション API が import できることの確認

## [0.63.0] - 2026-10-13

試験日までの日数を、煽らず前向きに見せる「試験日カウントダウン」を追加。「あと◯日」を押し付けず「自分のペースで」「今日できること」を添え、試験日を過ぎたら静かに「おつかれさまでした」を出してカウントを消す。追加のみ（`UkalabStrings` は変えず、文言は新設の `ExamCountdownStrings`）。既存の `daysUntilExam`・`OshiMessageEngine`・`ExamPrepCard` は変更しない。

### Added
- `ExamCountdownEngine`（純 Dart、`ukalab_core.dart`）: 試験日（null 可）と基準日（`today`、テスト用に注入可）から `ExamCountdown{daysLeft, phase}` を作る。`ExamCountdownPhase` は none（未設定）/ farAway（100日超）/ approaching（31〜100日）/ close（8〜30日）/ finalDays（1〜7日。`final` は予約語のため）/ today / done（過去）。日数は既存 `daysUntilExam` の暦日差で、時刻・タイムゾーン・夏時間で 1 日ずれない
- `ExamCountdownChip` / `ExamCountdownCard`（`ui.dart`）: ホームの AppBar 付近・`ExamPrepCard` 内に置けるチップと、今日できることの短い提案を添えるカード。`onTap` で試験日設定を開く想定。未設定は何も出さず、終了後は日数を消して「おつかれさまでした」のみ。Semantics 付き、「動きを減らす」設定では動きなし
- `ExamCountdownStrings`（ja・en。`copyWith` で上書き可）。禁止語（責める・煽る語）をテストで機械検証。final 期でも「いつもどおりで大丈夫」の調子

## [0.62.0] - 2026-10-13

推しの小物（アクセサリー）画像と API を追加（#79）。追加のみ。

### Added
- 小物 `UkalabAccessory`（helmet/hachimaki/calculator/notebookPc/goggles/drone）と `UkalabAccessories`（`image(id, a)`・`availableFor`・`shopItems(id)` で `ShopCategory.accessory` の品目・`fromShopId`）。画像は `assets/mascot/<id>/items/`（各キャラ3種・計12枚）
- `UkalabOshiRoom(accessory:)`（任意）: 衣装なしのとき小物を持った推しの絵で表示。未指定なら従来どおり

## [0.61.0] - 2026-10-13

間違えた問題を見返して解き直せる「間違いノート」を追加。間違いを「伸びしろ」として扱い、解き直して正解になったら「克服」と祝う。責めない・煽らない・件数ランキングにしない。追加のみ（`UkalabStrings` は変えず、文言は新設の `MistakeNoteStrings`）。

### Added
- `MistakeNoteEngine`（純 Dart、`ukalab_core.dart`）: 既存の `ProgressRecord`（原因 `WrongCause`・`topicId` を再利用）から `MistakeNoteEntry{qid, firstMissedAt, lastMissedAt, missCount, overcome, lastCause?, topicId?}` を作る。克服は「間違えたあと連続 N 回正解」（`overcomeStreak`、既定 2。暫定）。同じ入力なら同じ結果で、同じ履歴を再度取り込んでも変わらない（`update`）。`newlyOvercome` で新しい克服を取り出せる
- `MistakeNoteStore` / `InMemoryMistakeNoteStore` / `SharedPreferencesMistakeNoteStore`（`ui.dart`。キー `ukalab_<アプリID>_mistake_notes`）: 問題ID・日時・原因コード・分野ID・回数のみ保存。壊れた保存値は空として読む
- `mistakeNoteDataPart`: バックアップ・リセット（`DataPart`、キー `mistakeNotes`）への登録用
- `MistakeNoteView`（`ui.dart`）: 「これから」「克服」のフィルタ、直近の間違い順、`questionBuilder`（問題文はアプリ側）、`onRetry`（解き直す）、`celebrateQids` で克服を祝う表示。Semantics 付き、「動きを減らす」設定では動きなし。premium の出し分けはアプリ側で包む（core は制限しない）
- `MistakeNoteStrings`（ja・en。`copyWith` で上書き可）。禁止語（責める語・件数で圧をかける語）をテストで機械検証

### Added / Changed（マスコット素材。#76・#77。v0.61.0 タグに含まれていたが記載漏れだったため追記）

#### Added
- `MascotPose`（thinking/cheer/hint/rest/fight）と `UkalabCharacters.poseImage`（`assets/mascot/<id>/poses/`）
- `MascotState`（empty/error/loading/welcome/streak）と `UkalabCharacters.stateImage`（`assets/mascot/<id>/states/`）
- 共通画面の小さな widget `MascotStateView`（`.empty` / `.error` / `.loading` / `.welcome`）と `MascotPoseImage`。標準キャラはコード描画に戻る
- 合格メダル画像17枚（`assets/mascot/medals/<certId>_medal.webp`）と `UkalabMedals.image(certId)`（`OshiMedal.image` に渡す）
- 特別ポーズ「おじぎ」`<id>_special_bow.webp` と `UkalabCharacters.specialBowImage` / `specialPassImage`

#### Changed
- `MascotScene.streak` の絵を新素材 `states/<id>_streak.webp`（全Lv共通）に置き換え、旧 `scenes/<id>_lv<1-5>_streak.webp` を削除。`sceneFile(id, streak)` は `<id>_streak` を返す（API・enumは不変）。`UkalabCharacters.sceneDir` を追加
- 推し4体の Lv1〜5（normal/joy）と `special_pass` を新しい webp（長辺512）に差し替え（ファイル名・APIは同じ）

## [0.60.0] - 2026-10-13

週に一度、「できたこと」だけを見せる週間ふりかえりを追加。責めない・煽らない・前週と比べて「少なかった」と見せない。追加のみ（`UkalabStrings` は変えず、文言は新設の `WeeklyRecapStrings`）。

### Added
- `WeeklyRecapEngine`（純 Dart、`ukalab_core.dart`）: 日別記録 `WeeklyRecapDay{date, answered, correct, topicId?}`（個人情報・問題IDなし）と週の起点（`weekStartsOn`、既定は月曜）から `WeeklyRecap{answered, correct, studyDays, streakDays, topTopics, improvedTopics, medalsEarned}` を作る。連続日数は週内の最長。0件の週は `isEmpty`（穏やかな表示用）
- `weeklyRecapDaysFromRecords`: 既存の `ProgressRecord` 履歴から `WeeklyRecapDay` を作るアダプタ（問題ID・原因・回答時間は引き継がない）
- `WeeklyRecapCard`（`ui.dart`）: Semantics 付き、「動きを減らす」設定では出現の動きなし。`message` に `OshiMessageBubble` などを置ける。共有用 `WeeklyRecapShareCard` は後から同じ `WeeklyRecap` を受け取る形で足せる構成（今回は含めない）
- `WeeklyRecapStrings`（ja・en。`copyWith` で上書き可）。禁止語（責める語・前週との比較語）をテストで機械検証

## [0.59.0] - 2026-10-13

学習の節目（連続学習・メダル・模試合格）で、推しの衣装や背景を「プレゼント」として解放し、祝うダイアログで知らせる機能を追加。煽らない・未達を理由に催促しない。追加のみ（`UkalabStrings` は変えず、文言は新設の `OshiGiftStrings`）。

### Added
- `OshiGiftEngine`（純 Dart、`ukalab_core.dart`）: `OshiGiftProgress`（連続日数・獲得済みメダルID集合・模試合格の有無。個人情報なし）と、アプリが渡す定義リスト（`OshiGiftSpec` / UI 側の `OshiGift`: id・`OshiGiftKind`[outfit/background]・`OshiGiftCondition`[`streakDays`/`medal`/`mockPass`]・表示名・任意の `ImageProvider`）から、新たに解放されたものだけを返す。既解放IDは除外、同じ入力なら同じ結果
- `OshiGiftStore`（`InMemoryOshiGiftStore` / `SharedPreferencesOshiGiftStore(appId)`、キー `ukalab_oshi_gift_<appId>`。`OutfitStore` と同じ流儀）と `OshiGiftService`（`load` / `check` / `isUnlocked`）
- `showOshiGiftDialog` / `OshiGiftCard`（`ui.dart`）: 画像未指定なら衣装は仮アイコン、背景はコード描画のグラデーション（`image: AssetImage(...)` を渡すだけで差し替わる）。Semantics 付き、「動きを減らす」設定では出現の動きなし
- `OshiGiftStrings`（ja・en。`copyWith` で上書き可）。祝う調子のみ。禁止語リストでテスト

## [0.58.0] - 2026-10-13

学習状況に応じて推しが短い一言を出す機能を追加。責めない・煽らない・罪悪感を与えない励ましだけ。追加のみ（`UkalabStrings`・`ExamPrepStrings` は変えない）。

### Added
- `OshiMessageEngine`（純 Dart、`ukalab_core.dart`）: `OshiMessageContext`（久しぶり・連続日数・今日の解答数/正答率・試験までの日数・苦手の有無。個人情報なし）から `OshiMessage{id, text, mood}` を選ぶ。seed（`seedFromDate`）で日替わり、`salt` で別の言い回し。同じ入力と seed なら同じ結果
- `OshiMessageStrings`（ja・en。`copyWith` で一部上書き可）。「サボった」「遅れている」「〜しないと」「ダメ」などの語や残り日数での脅しを使わない（ja/en 全文言を禁止語リストでテスト）。試験までの日数は「あと◯日。自分のペースで大丈夫」程度の軽い言及のみ
- `OshiMessageBubble`（`ui.dart`）: キャラ（`avatar`）か絵文字＋吹き出し。Semantics 付き、タップで別の一言、「動きを減らす」設定では切替の動きなし

## [0.57.0] - 2026-10-13

「試験に向けて」系の画面（10分プラン・試験直前・当日チェックリスト・更新ログ・学習データ書き出し）を `ui.dart` に追加（otsu4 の `core_feature_views.dart` を共通化）。追加のみ（`UkalabStrings` は変えず、文言は新設の `ExamPrepStrings`）。

### Added
- `ExamPrepCard`: 10分プラン・試験直前モード・当日チェックリストの入口。問題・履歴・試験日・premium 判定・練習画面の起動はすべて引数/コールバックで受ける
- `ExamDayChecklistView`: 当日チェックリスト。`items` を渡さなければ一般項目（すべて「公式で要確認」）。チェック状態は `initialProgress` / `onChanged` でアプリが保存する
- `defaultExamDayChecklist` / `defaultChecklistIds`: 一般のチェック項目（会場/オンラインで切り替え）
- `UpdateLogView`、`HistoryExportView`（CSV 表示とコピー）、`ExamPrepSettingsTiles`（設定タブの入口）
- `ExamPrepStrings`: 上記の文言（ja・en は推敲済み、zh/zh-Hant/ko は機械翻訳の下書き）。責める表現・他人との比較は使わない（全言語をテストで検査）
- `historyCsvText`（純 Dart、`ukalab_core.dart`）: 日別と分野別の CSV を続けて返す。**アプリ側に同名の関数があると、両方を import するファイルで曖昧になる。移行時にアプリ側を消す**

## [0.56.0] - 2026-10-13

推しの画像の隅にメダルを置き、画像保存・SNS 共有できるカードを追加。追加のみ（`UkalabStrings` に必須項目 `medalTitle`/`medalNote`/`medalDisclaimer`/`medalSave` を追加。独自に `UkalabStrings(...)` を組み立てているアプリは追記が要る）。

### Added
- `OshiMedal`（id・label・tier・kind・任意の `ImageProvider? image`）、`OshiMedalKind`、`OshiMedalCorner`、`OshiMedalView`
- `OshiMedalShareCard`: 4:5 の共有カード。`MascotWidget(animate: false, joy)` の隅（既定は右下）にメダルを重ねる。画像が無ければコード描画（リボン+円+アイコン）。個人情報の欄なし（日付・うかラボ・「自己記録・非公式」のみ）
- `showOshiMedalDialog(context, medal:, onShare:, onSave:)`: `captureShareCard`（pixelRatio 3）で PNG 化して渡す。null のボタンは出さない。画像化の前に precache。ネイティブプラグインは追加しない
- 文言 5 言語（ja/en は推敲済み、zh/zh-Hant/ko は機械翻訳の下書き）

## [0.55.1] - 2026-10-13

`subtopic-conflict` 検査の単位を選べるようにした。既定は従来どおり章（`topicId`）で、挙動は変わらない。

### Added
- `SubtopicScope`（`topic` / `subject`）と `validateAnswerFeedbackTags(subtopicScope:)`
- `validate_content --subtopic-scope=topic|subject`: `subject` にすると、同じ細目IDが複数の `subjectId` に付くときだけ衝突とする（`topicId` が概念単位の試験向け）

## [0.55.0] - 2026-10-13

解答後フィードバック（誤答の原因ラベル・違いの比較表示・今週の弱点）の共通部品を、単機能エントリ
`package:ukalab_core/answer_feedback.dart` として追加（企画: 追加差別化機能 §1・§2）。追加のみ。

### Added
- `WrongCauseSelector`: 誤答直後に原因ラベルを自分で選ぶ UI（任意・再タップで取り消し、`includeCalculation: false` で「計算ミス」を除外）
- `AnswerFeedbackPanel`: 解答後に置くだけの統合ウィジェット。不正解時に 原因選択・違いの比較表示（`compareWith` があるとき）・原因別の対策を出す。正解時は何も出さない
- `ComparisonCard`: `ComparisonView`（違いの比較表示）の画面
- `WeakSummaryCard` / `canShowWeakSummary`: 今週の弱点トップ3・原因別の内訳・自分の先週との推移。premium 判定は呼び出し側
- `AnswerFeedbackStrings`: 上記の文言（ja・en・zh・zh-Hant・ko。ja・en 以外は機械翻訳の下書き）
- `buildWeakSummary` / `WeakSummary`（純 Dart）: 弱点まとめの元データ
- `attachCauseToLatest`: 解答の記録に、後から選んだ原因ラベルを付ける
- `validateAnswerFeedbackTags`: `subtopic-conflict`・`compare-self`・`compare-no-view` を検査。`validate_content` に組み込み済み
- README に統合例と「論点タグ・比較対象タグを付ける手順」

## [0.54.0] - 2026-10-13

うかラボ5アプリの相互紹介を共通化する `package:ukalab_core/cross_promo.dart` を追加（`cross_promo_kit` v0.3.0）。追加のみ。

- `UkalabCrossPromo.init()`: Firebase 初期化（失敗は握りつぶす）→ `CrossPromoService.init()`。二重呼び出し安全。`unawaited` で呼べる
- `UkalabCrossPromoSection(currentAppId: ...)`: `currentCategory: 'うかラボ'` 固定の薄いラッパー。成人向けのため `isChildDirected` は付けない
- `kUkalabCrossPromoCategory = 'うかラボ'`
- 依存追加: `cross_promo_kit`（git, v0.3.0）・`firebase_core`・`firebase_remote_config`
- `ui.dart` には含めない（Firebase 依存を持ち込まないため。使うアプリが明示的に import する）
- アプリ側の作業は README「相互紹介」を参照

## [0.53.0] - 2026-10-12

共通 Firebase（`ukalab-prod`／`ukalab-dev`）のルール・検査・手順を、`app_common_kit` の `firebase/` から `firebase/` へ移す（うかラボ専用のため）。コードの変更なし。

- `firebase/firestore.rules`・`test_rules.py`・`firebase.json`・`.firebaserc`・`README.md`
- 新しい資格を足すときは、`UkalabCert`（`lib/ui/theme/ukalab_palette.dart`）と `firebase/firestore.rules` の `examIds()` を同じ PR で更新する

## [0.52.0] - 2026-10-12

`app_common_kit` を v3.0.0 に上げ、キットから外れた画面専用の文言 51 項目を `UkalabStrings` として持つ。`package:ukalab_core/ui.dart` から使う。

- 新しい `UkalabStrings`（ja・en・簡体字 zh・繁体字 zh-Hant・ko）。コイン・着せ替え・推し・合格報告・共有カード・下部タブの文言
- 言語は `UkalabStrings.of(context)` が `KitStringsScope`（`KitStrings.languageCode`）から選ぶ。アプリ側の設定は変わらない
- 画面のウィジェット（`WardrobeScreen`・`PassShareCard`・`showPassReport`・`showMockRecord`・`outfitLockedReason`・`coinEventLabel`）の `strings` 引数の型が `KitStrings` から `UkalabStrings` に変わる

## [0.51.0] - 2026-10-12

`app_common_kit` を v2.0.0 に上げ、キットから外れたうかラボ専用の部品を受け取る。`package:ukalab_core/ui.dart` から使う。

- 移ってきた: `LabStrings`・`TermCard`（`showTermCard`・`RelatedTermRef`・`RelatedQuestionRef`）・`TermMapWidget` 系・`ChapterReadingWidget`（`ReadingSectionView`）・`TappableTermText`（`TermReference`）・`StatsCompareWidget`・`ExamStats*`（`ExamStatsService`・`FakeExamStatsService`・`FirebaseExamStatsService`・`examStatsServiceProvider`）
- `LabStrings.of` は言語に応じた既定のみ（キットの `KitStringsScope.labs` は廃止）
- アプリ側は、上記の名前を使うファイルに `package:ukalab_core/ui.dart` の import が要る

## [0.50.0] - 2026-10-12

`CustomMockExamSetupScreen`（カスタム模擬試験の科目・問題数の設定画面）を追加する。G検定・生成AIパスポート両アプリに重複していたUIをここに一本化する。追加のみ。

## [0.49.0] - 2026-10-11

`PremiumFeature.readingReadAloud`（章ごとの解説読み物の全文読み上げ）を追加する。追加のみ。

## [0.48.0] - 2026-10-11

`app_common_kit` を v1.11.0 → v1.13.0 に追従する。

### Changed
- `app_common_kit` が追加した `MockExamTrendChart`・`ChapterReadingWidget.onReadAloud` を、依存の更新により利用可能にする（本体に変更なし）

## [0.47.0] - 2026-10-11

模擬試験の成長グラフ・カスタム模擬試験（プレミアム機能）を追加する。追加のみ。

### Added
- `package:ukalab_core/mock_exam_history.dart`: `MockExamHistoryEntry`（模擬試験1回分の結果のスナップショット）・`MockExamHistoryStore`/`MockExamHistoryService`/`mockExamHistoryProvider`（端末内保存、キーは`ukalab_<アプリID>_mock_exam_history`、保持上限50件）・`mockExamHistoryOverrides(appId)`
- `pickCustomMockExamQuestions`: 指定した科目だけから出題する（カスタム模擬試験用）。複数科目は均等に、余りは先頭の科目から割り振る
- `PremiumFeature.mockExamHistory`・`PremiumFeature.customMockExam`

グラフ表示部品（`MockExamTrendChart`）は`app_common_kit`側に追加する（依存の向きを守るため、ukalab_coreの型をapp_common_kitに持ち込まない）。

## [0.46.0] - 2026-10-11

`app_common_kit` を v1.10.0 → v1.11.0 に追従する。

### Changed
- `app_common_kit` が追加した `ChapterReadingWidget` を、依存の更新により利用可能にする（本体に変更なし）

## [0.45.0] - 2026-10-11

章ごとの解説読み物（教科書的なまとめページ）モデルを追加する。追加のみ。

### Added
- `ChapterReading`（`readingId`・章`subjectId`・見出しと本文の節`sections`・関連用語/関連問題・出典）
- `parseChapterReadingsJsonl`・`validateChapterReadings`
- `validate_content` CLI に `--reading reading.jsonl` オプションを追加

## [0.44.0] - 2026-10-11

学習リマインダーの OS 通知（端末のローカル通知）の共通部分を追加する。追加のみ。

### Added
- `package:ukalab_core/reminder_notification.dart`: 通知する時刻の判断（`upcomingReminderTimes`・`goalAchievedToday`・`rescheduleStudyReminders`）/ 端末の通知機能への差し込み口 `ReminderNotifier`（既定は何もしない `NoopReminderNotifier`、`reminderNotifierProvider` を override して差し込む）/ `ReminderNotificationWatcher`（`MaterialApp` の `builder` で包む。起動時に一度、そのあとは設定や今日の目標が変わるたびに予約し直す）
- `ReminderSettingsSection`: 学習リマインダーをオンにしたとき、端末の通知の許可を求める

端末の通知機能そのもの（プラグイン・権限・タイムゾーン）は core には入れない。アプリ側で `ReminderNotifier` を実装して差し込む。

## [0.43.0] - 2026-10-11

用語集の並び順を選べるようにする。追加のみ（既定は従来どおり用語名順）。

### Added
- `GlossaryListView.sortByTerm`（既定 true）。false なら渡した用語の並び（データの順）のまま出す

## [0.42.0] - 2026-10-11

用語集の一覧と「覚えた」を共通化する。追加のみ。

### Added
- `package:ukalab_core/glossary.dart`: `GlossaryListView`（検索・分野での絞り込み・「覚えた」チェックと「すべて／覚えた／未習得」。Riverpod 不要）/ `LearnedTermsStore`（キーは `ukalab_<アプリID>_learned_term_ids`）/ `learnedTermsDataPart`（バックアップ・リセットの部品）/ `openTermCard`（関連用語を辿れる用語カード）。`ui.dart` には含めない（アプリ側の同名と衝突しないため）

## [0.41.0] - 2026-10-11

デイリーミッションの記録だけで作れる共通の実績を追加する。追加のみ。

### Added
- `achievements.dart`: `dailyGoalAchievements`（連続学習日数＝履歴の範囲の直近30日まで・目標達成の連続）/ `dailyGoalAchievementsOverride`（`achievementsProvider` の差し込み）/ `studyStreakFromHistory` / `achievementUnlockDataPart`（バックアップ・リセットの部品）/ `dailyGoalAchievementCategoryLabels`

## [0.40.0] - 2026-10-11

実績バッジの共通部品を追加する。追加のみ。

### Added
- `package:ukalab_core/achievements.dart`: `Achievement`（バッジ1件。定義と達成判定はアプリ側）/ `achievementsProvider`（アプリ側で override）/ 解除日時の保存（キーは `ukalab_<アプリID>_notified_achievement_ids`）/ `achievementUnlockOverrides(appId)`（main で1回呼ぶ）/ `watchAchievementUnlocks(ref, key)`（解除スナックバー）/ `AchievementsView`（カテゴリ別タブ付きの一覧。達成カードは `shareCardBuilder` で任意）。`ui.dart` には含めない（独自の同名クラスを持つアプリとの衝突を避けるため）

## [0.39.0] - 2026-10-11

アプリ内リマインダー（学習）を共通化する。追加のみ。

### Added
- `package:ukalab_core/reminder.dart`: `ReminderSettings`（学習・模試リマインダーのオン／オフと学習の時刻）/ `shouldShowStudyReminder` / 保存とサービス（キーは `ukalab_<アプリID>_reminder_settings`）/ `reminderOverrides(appId)`（main で1回呼ぶ）/ `StudyReminderCard`（ホームに置く。目標が未達成の夜だけ出る）/ `ReminderSettingsSection`（設定画面）。OS のプッシュ通知ではなく、アプリ内で出すカード。`ui.dart` には含めない（独自の同名クラスを持つアプリとの衝突を避けるため）

## [0.38.0] - 2026-10-11

デイリーミッション（今日の目標問題数）と学習カレンダーを共通化する。追加のみ。

### Added
- `package:ukalab_core/daily_goal.dart`: `DailyGoal` / `DailyGoalHistoryEntry` / 連続達成日数の計算（`nextAchievedStreak`・`effectiveAchievedStreak`）/ カレンダーの計算（`monthCalendarDays` ほか）/ 保存とサービス（キーは `ukalab_<アプリID>_daily_goal`・`_daily_goal_history`）/ `dailyGoalOverrides(appId)`（main で1回呼ぶ）/ `recordDailyAnswer(ref)`（1問答えたときに呼ぶ）/ 画面の部品 `DailyMissionCard`・`DailyGoalSetting`。`ui.dart` には含めない（独自の同名クラスを持つアプリとの衝突を避けるため）

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
- `bin/validate_content`: 問題データ検証 CLI（問題があれば終了コード 1）
- GitHub Actions CI（analyze・test・サンプルデータ検証）
