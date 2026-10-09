import 'dart:convert';

import '../experience/next_step.dart';
import 'question_validator.dart' show ContentIssue;

class ParsedNextSteps {
  const ParsedNextSteps(this.rules, this.issues);

  final List<NextStepRule> rules;

  /// 読み込み（JSON 構文・必須項目）で見つかった問題。
  final List<ContentIssue> issues;
}

/// JSON Lines（1行1件）を読む。読めない行は [ParsedNextSteps.issues] に入れて続行する。
ParsedNextSteps parseNextStepsJsonl(String text) {
  final rules = <NextStepRule>[];
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
      rules.add(NextStepRule.fromJson(decoded));
    } on FormatException catch (e) {
      issues.add(ContentIssue('line:${i + 1}', 'parse', e.message));
    }
  }
  return ParsedNextSteps(rules, issues);
}

/// 配信前の品質ゲート。自分自身への提案・同じ組の重複・空の理由を検査する。
/// [knownExamIds] を渡すと、未定義の試験IDも検出する。
List<ContentIssue> validateNextSteps(
  List<NextStepRule> rules, {
  Set<String>? knownExamIds,
}) {
  final issues = <ContentIssue>[];
  void add(NextStepRule r, String code, String message) =>
      issues.add(ContentIssue('${r.fromExamId}->${r.toExamId}', code, message));

  final seen = <String>{};
  for (final r in rules) {
    if (r.fromExamId == r.toExamId) add(r, 'self-reference', '自分自身を提案しています');
    if (!seen.add('${r.fromExamId}->${r.toExamId}')) {
      add(r, 'duplicate-rule', '同じ組み合わせが重複しています');
    }
    if (r.reason.trim().isEmpty) add(r, 'empty-reason', '理由(reason)が空です');
    if (knownExamIds != null) {
      if (!knownExamIds.contains(r.fromExamId)) {
        add(r, 'unknown-exam', '未定義の試験ID: ${r.fromExamId}');
      }
      if (!knownExamIds.contains(r.toExamId)) {
        add(r, 'unknown-exam', '未定義の試験ID: ${r.toExamId}');
      }
    }
  }
  return issues;
}
