import 'dart:convert';

import '../config/exam_config.dart';
import '../experience/boundary_slider.dart';
import '../question/question.dart';
import 'question_validator.dart' show ContentIssue;

class ParsedBoundaryScenarios {
  const ParsedBoundaryScenarios(this.scenarios, this.issues);

  final List<BoundaryScenario> scenarios;

  /// 読み込み（JSON 構文・必須項目）で見つかった問題。
  final List<ContentIssue> issues;
}

/// JSON Lines（1行1場面）を読む。読めない行は [ParsedBoundaryScenarios.issues] に入れて続行する。
ParsedBoundaryScenarios parseBoundaryScenariosJsonl(String text) {
  final scenarios = <BoundaryScenario>[];
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
      scenarios.add(BoundaryScenario.fromJson(decoded));
    } on FormatException catch (e) {
      issues.add(ContentIssue('line:${i + 1}', 'parse', e.message));
    }
  }
  return ParsedBoundaryScenarios(scenarios, issues);
}

/// 配信前の品質ゲート（決定76・77）。条件・ルール表の整合性、
/// 全ての条件の組み合わせに結論があるか（網羅性）、出典の有無などを検査する。
///
/// [exam] を渡すと、examId・subjectId が試験定義と整合するかも検査する。
List<ContentIssue> validateBoundaryScenarios(
  List<BoundaryScenario> scenarios, {
  ExamConfig? exam,
}) {
  final issues = <ContentIssue>[];
  void add(BoundaryScenario s, String code, String message) =>
      issues.add(ContentIssue(s.scenarioId, code, message));

  final seenIds = <String>{};
  for (final s in scenarios) {
    if (!seenIds.add(s.scenarioId)) {
      add(s, 'duplicate-id', 'scenarioId が重複しています');
    }

    if (s.title.trim().isEmpty) add(s, 'empty-title', '場面の見出し(title)が空です');
    if (s.sourceRef.trim().isEmpty) add(s, 'no-source', '出典の説明がありません');
    if (s.source == QuestionSource.statute &&
        (s.lawVersion == null || s.lawVersion!.trim().isEmpty)) {
      add(s, 'no-law-version', 'statute の場面には lawVersion が必要です');
    }
    if (s.contentVer.trim().isEmpty) add(s, 'no-content-ver', 'contentVer がありません');

    if (s.conditions.length < 2) {
      add(s, 'too-few-conditions', '条件は2つ以上必要です（境界線を体験できません）');
    }
    final conditionIds = s.conditions.map((c) => c.conditionId).toSet();
    if (conditionIds.length != s.conditions.length) {
      add(s, 'duplicate-condition-id', 'conditionId が重複しています');
    }
    if (s.rules.isEmpty) {
      add(s, 'empty-rules', 'rules が空です');
      continue;
    }

    for (final rule in s.rules) {
      if (rule.conclusion.trim().isEmpty) {
        add(s, 'empty-conclusion', '結論(conclusion)が空のルールがあります');
      }
      if (rule.lawReference.trim().isEmpty) {
        add(s, 'empty-law-reference', '根拠(lawReference)が空のルールがあります');
      }
      for (final key in rule.conditionValues.keys) {
        if (!conditionIds.contains(key)) {
          add(s, 'unknown-condition', 'ルールが未定義の条件を参照しています: $key');
        }
      }
    }

    // 網羅性: 条件の全ての真偽値の組み合わせに結論があるか（高々 2^10 通りまで）。
    if (s.conditions.length <= 10 && conditionIds.length == s.conditions.length) {
      final ids = s.conditions.map((c) => c.conditionId).toList();
      final total = 1 << ids.length;
      for (var mask = 0; mask < total; mask++) {
        final values = <String, bool>{};
        for (var bit = 0; bit < ids.length; bit++) {
          values[ids[bit]] = (mask & (1 << bit)) != 0;
        }
        if (s.evaluate(values) == null) {
          add(s, 'unreachable-combination', '結論がない条件の組み合わせがあります: $values');
          break;
        }
      }
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
