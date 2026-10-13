# ukalab_core

うかラボ（成人向け検定アプリ）の共通エンジン。ジャンル追加 = **ExamConfig(JSON) + 問題データ + テーマ**で、コード変更は問題タイプ追加時のみ。

## 位置づけ

```
アプリ（資格ごとの薄いリポジトリ） → ukalab_core（本リポジトリ） → app_common_kit
```

- 依存は一方向、アプリ側は `ref: vX.Y.Z` のタグ固定で参照する（`main` は参照しない）。
- アプリ側リポジトリは ExamConfig・問題データ・テーマ・ストア設定だけを持つ。
- `package:ukalab_core/ukalab_core.dart` は純Dart（エンジン・検証CLI）。`package:ukalab_core/ui.dart` は Flutter の UI（推し・衣装・コイン・テーマ・学習ラボ）。v0.24.0 から Flutter パッケージで、`app_common_kit` v1.0.0 に依存する。

## 構成

```
lib/
  config/     ExamConfig（試験定義）
  question/   Question（選択式。出典区分・配点・無効フラグ）
  term/       Term（専門用語の解説カード。決定50）
  content/    問題データ・用語データの検証（配信前の品質ゲート）
  progress/   解答記録・弱点・推移（weak_summary など）
  engine/     scoreMockExam（採点・合否）, Srs（間隔反復）, PracticeSession（演習）
bin/
  validate_content.dart   問題データ検証 CLI
example/      架空のサンプル試験と問題（実在の試験の問題ではない）
```

## UI（`ui.dart`）

推し・衣装/着せ替え・学習コイン・テーマ・学習ラボ系の部品。使い方は [docs/ui.md](docs/ui.md)。

v0.63.0 で試験日カウントダウン（`ExamCountdownEngine` / `ExamCountdownChip` / `ExamCountdownCard`。「自分のペースで」「今日できること」を添え、試験日を過ぎたら静かに「おつかれさまでした」。[docs/ui.md](docs/ui.md#試験日カウントダウンexamcountdownengine--examcountdownchip--examcountdowncard)）を追加。

v0.61.0 で間違いノート（`MistakeNoteEngine` / `MistakeNoteView`。間違いを「伸びしろ」として見返し、解き直して克服したら祝う。[docs/ui.md](docs/ui.md#間違いノートmistakenoteengine--mistakenoteview)）を追加。

v0.60.0 で週間ふりかえりカード（`WeeklyRecapEngine` / `WeeklyRecapCard`。できたことだけを見せ、前週との比較はしない。[docs/ui.md](docs/ui.md#週間ふりかえりweeklyrecapengine--weeklyrecapcard)）を追加。

v0.59.0 で衣装・背景のプレゼント（`OshiGiftEngine` / `showOshiGiftDialog`。連続学習・メダル・模試合格で解放し、祝うだけ。[docs/ui.md](docs/ui.md#衣装背景のプレゼントoshigiftengine--showoshigiftdialog)）を追加。

v0.58.0 で推しの一言（`OshiMessageEngine` / `OshiMessageBubble`。責めない励ましのみ。[docs/ui.md](docs/ui.md#推しの一言oshimessageengine--oshimessagebubble)）を追加。

v0.57.0 で「試験に向けて」系の画面（`ExamPrepCard`・`ExamDayChecklistView`・`UpdateLogView`・`HistoryExportView`・`ExamPrepSettingsTiles`。[docs/ui.md](docs/ui.md#試験に向けて10分プラン試験直前チェックリスト更新ログ書き出し)）を追加。

v0.56.0 で `OshiMedalShareCard` / `showOshiMedalDialog`（推しの画像の隅にメダルを置いた、画像保存・SNS 共有用カード。個人情報は入らない）を追加。

```dart
import 'package:app_common_kit/app_common_kit.dart'; // 全アプリ共通（KitStrings・設定画面など）
import 'package:ukalab_core/ui.dart';              // うかラボ専用のUI
```

## 使い方

### 試験を定義する

[example/sample_exam.json](example/sample_exam.json) を参照。級・科目・出題数・制限時間・合格基準（総合％と科目別の足切り％）・試験日を JSON で書く。

```dart
final exam = ExamConfig.fromJson(jsonDecode(text) as Map<String, dynamic>);
```

### 問題データを検証する（配信前・CI）

問題は JSON Lines（1行1問）。[example/sample_questions.jsonl](example/sample_questions.jsonl) を参照。

```bash
dart run ukalab_core:validate_content exam.json questions.jsonl
```

検査する項目: 出典の説明が必須／`licensed` は `license` 必須／`statute` は `lawVersion` 必須／qid の重複／選択肢の個数／同じ文面の選択肢（正解の一意性）／`answerIndex` の範囲／解説・`contentVer` の有無／試験定義との整合（examId・subjectId・levelId）。問題が1件でもあれば終了コード 1。

### 用語データを検証する（配信前・CI、決定50）

専門用語の解説カードも JSON Lines（1行1用語）。[example/sample_terms.jsonl](example/sample_terms.jsonl) を参照。問題文・解説文からは `termId` で参照する（アプリ側の責務）。

```bash
dart run ukalab_core:validate_content exam.json --terms terms.jsonl questions.jsonl
```

検査する項目: `headline`（①ひとことで言うと）・`definition`（②正確な意味）が空でないか／`termId` の重複／見出し語（表記）の重複（同義語は `relatedTermIds` で結ぶ）／`relatedTermIds`・`relatedQuestionIds` のリンク切れ／出典の有無／試験定義との整合。`--terms` は複数指定できる。

```dart
final parsed = parseTermsJsonl(text);
final issues = validateTerms(parsed.terms, exam: exam, questions: questions);
```

### 模擬試験を採点する

```dart
final result = scoreMockExam(
  questions: examQuestions,
  answers: {'q1': 2, 'q2': null}, // qid → 選んだ番号（未回答は null）
  rule: exam.level('basic')!.passRule,
);
result.passed;               // 合否（総合の合格ライン + 科目別の足切り）
result.shortBy;              // 総合の合格ラインまであと何点か
result.subjectShortfalls;    // 足切りに満たない科目 → あと何点
result.failedBySubjectCutoff // 総合は届いたが足切りで不合格
```

出題を選ぶには `pickMockExamQuestions` を使う。`ExamConfig` の `LevelConfig.subjectQuestionCounts`（科目別の出題数。例: 乙4の法令15問・物理化学10問・性質消火10問）を指定すれば科目ごとに決まった数を抽出し、省略すれば全体から `questionCount` 問をランダムに抽出する。

```dart
final picked = pickMockExamQuestions(
  pool: examQuestions,
  level: exam.level('otsu4')!, // subjectQuestionCounts を持つ level
  seed: 1,
);
```

### 演習と間隔反復

```dart
final due = Srs.due(items, now, limit: 10);
final session = PracticeSession(
  pool: questions,
  size: 10,
  seed: 1,
  priorityQids: [for (final i in due) i.qid], // 復習時期の問題を先頭に
);
final record = session.answer(choiceIndex, ms: elapsedMs);
items[record.qid] = Srs.review(items[record.qid], qid: record.qid, correct: record.correct, now: now);
```

保存（端末内・Firestore）はこのパッケージの範囲外。型は JSON に往復できる。

### 無料枠とプレミアムの線引き

```dart
const limits = FreeTierLimits.standard; // 暫定。値は変更できる
final quota = limits.mockExamQuota(isPremium: hasPremium, store: myStore);
if (quota.canUse && await quota.tryConsume()) { /* 模擬試験を開始 */ }
final topics = limits.weakTopicLimit(isPremium: hasPremium); // null なら全分野
```

`KeyValueStore` はアプリ側で SharedPreferences などを使って実装する。premium だけが対象で、noads のみの人は無料と同じ扱い。

### 解答後フィードバック（`answer_feedback.dart`）

誤答の原因ラベル・違いの比較表示・今週の弱点を、アプリ側の追加コードを最小にして出す部品。
`ui.dart` とは別の単機能エントリ（Flutter が要る）。ロジックは `ukalab_core.dart`（純 Dart）にもある。

- `AnswerFeedbackPanel`: 解答後に置く統合ウィジェット。**不正解のときだけ** (1) 原因ラベルの選択（任意）
  (2) 問題に `compareWith` があれば違いの比較表示 (3) 選んだ原因に応じた対策の一言 を出す。正解なら何も出ない
- `WrongCauseSelector`: 原因ラベル4つ（知識不足／ひっかけ／計算ミス／読み違い）の選択だけ。`includeCalculation: false` で「計算ミス」を除く
- `WeakSummaryCard`: 今週の弱点トップ3・原因別の内訳・自分の先週との推移（他人とは比べない）。
  premium 機能（`PremiumFeature.weakDrill`）なので、出すかどうかは呼び出し側が `canShowWeakSummary(isPremium: ...)` で決める
- 文言は `AnswerFeedbackStrings`（ja・en・zh・zh-Hant・ko、`KitStringsScope` の言語に従う。ja・en 以外は機械翻訳の下書き）

アプリ側の統合（解答後の画面。履歴の保存と `attachCauseToLatest` で原因を反映するだけ）:

```dart
import 'package:ukalab_core/answer_feedback.dart';

// 1. 解答後に置く（selectedIndex は Question.choices の元の並びでの番号）
if (_answered) AnswerFeedbackPanel(question: q, selectedIndex: _selectedOriginal, terms: widget.terms,
    onCause: (c) => ref.read(historyProvider.notifier).setCause(q.qid, c)),
// 2. 履歴ストアに1メソッド足す: state = attachCauseToLatest(state, qid, cause); 保存
// 3. 弱点画面（premium のみ）
if (canShowWeakSummary(isPremium: isPremium)) WeakSummaryCard(records: history, questions: questions, chapterLabel: chapterName)
```

計算を使わない資格は `includeCalculation: false`（パネル・カード両方）。

#### 問題データへ論点タグ・比較対象タグを付ける手順

1. 章: すべての問題に `topicId`（必須）。細目を使うなら `subtopicId`（任意）。
   同じ `subtopicId` は1つの章にだけ付ける（別の章に付けると `subtopic-conflict`）。
   `topicId` が概念単位で章を `subjectId` で表す試験（細目IDが `<subjectId>-<細目>`）は、
   `validate_content` に `--subtopic-scope=subject` を付けると衝突の単位が科目になる（既定は `topic`）
2. 用語データ（`--terms`）で、その問題の答えにあたる用語の `relatedQuestionIds` に問題の `qid` を入れる
3. 紛らわしい相手の用語の `termId` を、問題の `compareWith`（配列）に入れる。
   答えの用語自身は入れない（`compare-self`）。空・重複・用語データに無いIDは `compare-empty` / `compare-duplicate` / `compare-unknown`
4. 比較表示は「答えの用語＋相手の用語」で2つ以上そろったときだけ出る。そろわないタグは `compare-no-view`
5. `dart run ukalab_core:validate_content exam.json --terms terms.jsonl questions.jsonl` で検査する
   （`--terms` が無いと用語を使う検査はできず、`compareWith` は未定義扱いになる）

例（問題の1行）: `{"qid":"q-012","topicId":"ch2","subtopicId":"ch2-a","compareWith":["term-recall"], ...}`
（答えの用語 `term-precision` 側に `"relatedQuestionIds":["q-012"]`）

### 相互紹介（`cross_promo.dart`）

うかラボ5アプリの「他のアプリもチェック！」。`cross_promo_kit` を `うかラボ` カテゴリに固定した薄いラッパー。
`ui.dart` には含めない（Firebase 依存を持ち込まないため。使うアプリが明示的に import する）。

各アプリの作業:

1. `pubspec.yaml` の `ukalab_core` の `ref` を、この機能を含むタグへ更新する
2. `main.dart` で起動時に1回（起動は止めない。Firebase 初期化は中で行う。失敗しても例外にならない）

   ```dart
   import 'package:ukalab_core/cross_promo.dart';

   unawaited(UkalabCrossPromo.init());
   ```

3. 設定画面に置く（掲載が0件なら何も表示しない。うかラボは大人向けなので保護者ゲートは付けない）

   ```dart
   UkalabCrossPromoSection(currentAppId: '<本番の applicationId>')
   ```

   子ども向け設定で広告を配信するアプリ（漢検など）は、`isChildDirected: true, beforeOpenStore: (context) => requireParentalGate(context)` を足す（ゲート未指定だとデバッグで assert）。

   `currentAppId` は本番の applicationId と完全一致させる（自アプリの除外に使う）。

ユーザー作業（コードでは済まない）:

- Firebase プロジェクトを作り、各アプリに `google-services.json`（Android）/ `GoogleService-Info.plist`（iOS）を置く
- Play の Data Safety を更新する（Firebase 利用に伴う収集の申告）
- 掲載リストは、公開を確認してから `cross_promo_kit/docs/cross_promo_apps.json` に載せ、検証して Remote Config（`cross_promo_apps`）へ投入する（手順は cross_promo_kit の `docs/ROLLOUT.md`）

## キャラ・メダル画像（`assets/mascot/`）

- 推し4体の Lv1〜5・特別ポーズ（`<id>_special_pass` / `<id>_special_bow`）、合格メダル（`medals/<certId>_medal.webp`、`UkalabMedals.image(certId)`）。いずれも webp・長辺512。
- AI生成素材: Leonardo.Ai Phoenix/Nano Banana, 規約版・プランは公開前に確認

## アイコン生成（tools/icon_gen）

共通テンプレート（上段「うかラボ」／中央にシンボル／下部に試験名。組織ロゴ・✓バッジなし）で、データから量産する。

```bash
pip install -r tools/icon_gen/requirements.txt
python tools/icon_gen/icon_gen.py --spec tools/icon_gen/specs/sample.json --out build/icons
python tools/icon_gen/check_icons.py --spec tools/icon_gen/specs/sample.json --out build/icons
```

- 定義（JSON）: `{"id": 資格ID, "short": 試験名の短縮, "symbol": symbols/ のファイル名}`。資格ID（例: `g_kentei`）
- シンボルは白一色の SVG（viewBox `-50 -50 100 100`）を `tools/icon_gen/symbols/` に置く。中抜きの色が必要なら `__BG__`（背景色に置換）
- 出力: `<id>_1024.png`、`<id>_fg.png`／`<id>_bg.png`（Android adaptive。前景は中央66%以内）、`<id>_small_1024.png`（最小サイズ用）
- 日本語の太字フォントが必要（Windows は游ゴシック、CI は fonts-noto-cjk）。`--font` で指定もできる
- AI 画像は使わない。試験団体のロゴ・「公式」「認定」の文字は入れない
- シンボルの最終デザインは未決（サンプルは仮）
- 実際のアプリ用の定義は `tools/icon_gen/specs/ukalab_apps.json`（今は `bike_license` のみ。シンボル `motorcycle` は仮のデザイン）。アプリのアイコンを更新するときは、これで生成して `<id>_1024.png`・`<id>_fg.png`・`<id>_bg.png` を使う

## まだ入っていないもの

Firebase 連携、課金・広告の組み込み、問題タイプ（○×・数値・仕訳・手書き）、苦手分析、学習プラン、問題の自動生成。
設計は `kentei-engine（うかラボ）` の企画設計書・決定ログ・`app_common_kit_v0_2_追加仕様.md` を参照。

## 開発

```bash
flutter pub get
flutter analyze
flutter test
```

ローカルで `app_common_kit` などを path 参照に切り替えるときは `pubspec_overrides.yaml` を使う（コミットしない）。
