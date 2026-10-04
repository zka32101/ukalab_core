import 'dart:convert';

import '../config/exam_config.dart';
import '../experience/method_choice.dart';
import 'question_validator.dart' show ContentIssue;

class ParsedMethodChoiceScenarios {
  const ParsedMethodChoiceScenarios(this.scenarios, this.issues);

  final List<MethodChoiceScenario> scenarios;

  /// 読み込み（JSON 構文・必須項目）で見つかった問題。
  final List<ContentIssue> issues;
}

/// JSON Lines（1行1場面）を読む。読めない行は [ParsedMethodChoiceScenarios.issues]
/// に入れて続行する。
ParsedMethodChoiceScenarios parseMethodChoiceScenariosJsonl(String text) {
  final scenarios = <MethodChoiceScenario>[];
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
      scenarios.add(MethodChoiceScenario.fromJson(decoded));
    } on FormatException catch (e) {
      issues.add(ContentIssue('line:${i + 1}', 'parse', e.message));
    }
  }
  return ParsedMethodChoiceScenarios(scenarios, issues);
}

/// 配信前の品質ゲート。事例説明・解説が空でないか、選択肢の正解がちょうど
/// 1つか、選択肢の重複などを検査する。
///
/// [exam] を渡すと、examId・subjectId が試験定義と整合するかも検査する。
List<ContentIssue> validateMethodChoiceScenarios(
  List<MethodChoiceScenario> scenarios, {
  ExamConfig? exam,
}) {
  final issues = <ContentIssue>[];
  void add(MethodChoiceScenario s, String code, String message) =>
      issues.add(ContentIssue(s.scenarioId, code, message));

  final seenIds = <String>{};
  for (final s in scenarios) {
    if (!seenIds.add(s.scenarioId)) {
      add(s, 'duplicate-id', 'scenarioId が重複しています');
    }

    if (s.caseDescription.trim().isEmpty) {
      add(s, 'empty-case-description', '事例の説明(caseDescription)が空です');
    }
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
