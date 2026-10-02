# yourwish_kentei

うかラボ（成人向け検定アプリ）の共通エンジン。ジャンル追加 = **ExamConfig(JSON) + 問題データ + テーマ**で、コード変更は問題タイプ追加時のみ。

## 位置づけ

```
アプリ（資格ごとの薄いリポジトリ） → yourwish_kentei（本リポジトリ） → app_common_kit
```

- 依存は一方向、アプリ側は `ref: vX.Y.Z` のタグ固定で参照する（`main` は参照しない）。
- アプリ側リポジトリは ExamConfig・問題データ・テーマ・ストア設定だけを持つ。
- v0.1.0 は純Dart。`app_common_kit`（権利管理・広告ゲート・フィードバック）への依存は、UI・課金を載せる段階で追加する。

## 構成

```
lib/
  config/     ExamConfig（試験定義）
  question/   Question（選択式。出典区分・配点・無効フラグ）
  content/    問題データの検証（配信前の品質ゲート）
  engine/     scoreMockExam（採点・合否）, Srs（間隔反復）, PracticeSession（演習）
bin/
  validate_content.dart   問題データ検証 CLI
example/      架空のサンプル試験と問題（実在の試験の問題ではない）
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
dart run yourwish_kentei:validate_content exam.json questions.jsonl
```

検査する項目: 出典の説明が必須／`licensed` は `license` 必須／`statute` は `lawVersion` 必須／qid の重複／選択肢の個数／同じ文面の選択肢（正解の一意性）／`answerIndex` の範囲／解説・`contentVer` の有無／試験定義との整合（examId・subjectId・levelId）。問題が1件でもあれば終了コード 1。

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

## まだ入っていないもの

テーマ（分野色・資格別テーマ色）、推し・コイン、共通UI部品、学習体験の「型」9部品、Firebase 連携、課金・広告の組み込み、問題タイプ（○×・数値・仕訳・手書き）、苦手分析、学習プラン、問題の自動生成。
設計は `kentei-engine（うかラボ）` の企画設計書・決定ログ・`app_common_kit_v0_2_追加仕様.md` を参照。

## 開発

```bash
dart pub get
dart analyze
dart test
```

ローカルで `app_common_kit` などを path 参照に切り替えるときは `pubspec_overrides.yaml` を使う（コミットしない）。
