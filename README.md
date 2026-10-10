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
  engine/     scoreMockExam（採点・合否）, Srs（間隔反復）, PracticeSession（演習）
bin/
  validate_content.dart   問題データ検証 CLI
example/      架空のサンプル試験と問題（実在の試験の問題ではない）
```

## UI（`ui.dart`）

推し・衣装/着せ替え・学習コイン・テーマ・学習ラボ系の部品。使い方は [docs/ui.md](docs/ui.md)。

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
