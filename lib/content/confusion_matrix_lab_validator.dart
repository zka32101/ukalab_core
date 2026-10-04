import 'dart:convert';

import '../config/exam_config.dart';
import '../experience/confusion_matrix_lab.dart';
import 'question_validator.dart' show ContentIssue;

class ParsedConfusionMatrixScenarios {
  const ParsedConfusionMatrixScenarios(this.scenarios, this.issues);

  final List<ConfusionMatrixScenario> scenarios;

  /// 読み込み（JSON 構文・必須項目）で見つかった問題。
  final List<ContentIssue> issues;
}

/// JSON Lines（1行1場面）を読む。読めない行は [ParsedConfusionMatrixScenarios.issues]
/// に入れて続行する。
ParsedConfusionMatrixScenarios parseConfusionMatrixScenariosJsonl(String text) {
  final scenarios = <ConfusionMatrixScenario>[];
  final issues = <ContentIssue>[];
  final lines = const LineSplitter().convert(text);
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('//')) continue;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('1行は JSON オブジェクトが必要です');
      }
      scenarios.add(ConfusionMatrixScenario.fromJson(decoded));
    } on FormatException catch (e) {
      issues.add(ContentIssue('line:${i + 1}', 'parse', e.message));
    }
  }
  return ParsedConfusionMatrixScenarios(scenarios, issues);
}

/// 配信前の品質ゲート。初期の混同行列が非負か、選択肢の正解がちょうど1つか、
/// 選択肢の重複などを検査する。
///
/// [exam] を渡すと、examId・subjectId が試験定義と整合するかも検査する。
List<ContentIssue> validateConfusionMatrixScenarios(
  List<ConfusionMatrixScenario> scenarios, {
  ExamConfig? exam,
}) {
  final issues = <ContentIssue>[];
  void add(ConfusionMatrixScenario s, String code, String message) =>
      issues.add(ContentIssue(s.scenarioId, code, message));

  final seenIds = <String>{};
  for (final s in scenarios) {
    if (!seenIds.add(s.scenarioId)) {
      add(s, 'duplicate-id', 'scenarioId が重複しています');
    }

    if (s.initialTp < 0 || s.initialFp < 0 || s.initialFn < 0 || s.initialTn < 0) {
      add(s, 'negative-count', '初期の混同行列(TP/FP/FN/TN)は0以上が必要です');
    }
    if (s.description.trim().isEmpty) add(s, 'empty-description', '場面の説明(description)が空です');
    if (s.explanation.trim().isEmpty) add(s, 'empty-explanation', '解説(explanation)が空です');
    if (s.sourceRef.trim().isEmpty) add(s, 'no-source', '出典の説明がありません');
    if (s.contentVer.trim().isEmpty) add(s, 'no-content-ver', 'contentVer がありません');

    if (s.options.length < 2) {
      add(s, 'too-few-options', 'options は2つ以上必要です');
    }
    final optionIds = s.options.map((o) => o.optionId).toSet();
    if (optionIds.length != s.options.length) {
      add(s, 'duplicate-option-id', 'options の optionId が重複しています');
    }
    for (final o in s.options) {
      if (o.text.trim().isEmpty) add(s, 'empty-option-text', 'options の文言が空です: ${o.optionId}');
    }
    final correctCount = s.options.where((o) => o.isCorrect).length;
    if (correctCount == 0) {
      add(s, 'no-correct-option', 'options に正解の選択肢がありません');
    } else if (correctCount > 1) {
      add(s, 'multiple-correct-options', 'options の正解の選択肢が複数あります');
    }

    if (exam != null) {
      if (s.examId != exam.examId) {
        add(s, 'exam-mismatch', 'examId(${s.examId}) が試験(${exam.examId})と一致しません');
      }
      final subjectId = s.subjectId;
      if (subjectId != null && exam.subject(subjectId) == null) {
        add(s, 'unknown-subject', '未定義の subjectId: $subjectId');
      }
    }
  }
  return issues;
}
