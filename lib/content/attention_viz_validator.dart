import 'dart:convert';

import '../config/exam_config.dart';
import '../experience/attention_viz.dart';
import 'question_validator.dart' show ContentIssue;

class ParsedAttentionVizScenarios {
  const ParsedAttentionVizScenarios(this.scenarios, this.issues);

  final List<AttentionVizScenario> scenarios;

  /// 読み込み（JSON 構文・必須項目）で見つかった問題。
  final List<ContentIssue> issues;
}

/// JSON Lines（1行1場面）を読む。読めない行は
/// [ParsedAttentionVizScenarios.issues] に入れて続行する。
ParsedAttentionVizScenarios parseAttentionVizScenariosJsonl(String text) {
  final scenarios = <AttentionVizScenario>[];
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
      scenarios.add(AttentionVizScenario.fromJson(decoded));
    } on FormatException catch (e) {
      issues.add(ContentIssue('line:${i + 1}', 'parse', e.message));
    }
  }
  return ParsedAttentionVizScenarios(scenarios, issues);
}

/// 配信前の品質ゲート。注意行列がトークン数に対して正方か、各行の合計が
/// およそ1.0か（softmaxらしい値か）、トークン数が可視化に十分かなどを
/// 検査する。
///
/// [exam] を渡すと、examId・subjectId が試験定義と整合するかも検査する。
List<ContentIssue> validateAttentionVizScenarios(
  List<AttentionVizScenario> scenarios, {
  ExamConfig? exam,
}) {
  final issues = <ContentIssue>[];
  void add(AttentionVizScenario s, String code, String message) =>
      issues.add(ContentIssue(s.scenarioId, code, message));

  final seenIds = <String>{};
  for (final s in scenarios) {
    if (!seenIds.add(s.scenarioId)) {
      add(s, 'duplicate-id', 'scenarioId が重複しています');
    }

    if (s.description.trim().isEmpty) add(s, 'empty-description', '説明(description)が空です');
    if (s.sourceRef.trim().isEmpty) add(s, 'no-source', '出典の説明がありません');
    if (s.contentVer.trim().isEmpty) add(s, 'no-content-ver', 'contentVer がありません');

    final n = s.tokens.length;
    if (n < 3) {
      add(s, 'too-few-tokens', 'tokens は3語以上必要です');
    }
    if (s.attention.length != n) {
      add(s, 'matrix-size-mismatch', 'attention の行数(${s.attention.length})がtokens数($n)と一致しません');
    } else {
      for (var i = 0; i < s.attention.length; i++) {
        final row = s.attention[i];
        if (row.length != n) {
          add(s, 'matrix-size-mismatch', 'attention[$i]の列数(${row.length})がtokens数($n)と一致しません');
          continue;
        }
        for (final v in row) {
          if (v < 0 || v > 1) {
            add(s, 'out-of-range', 'attention の値は0.0〜1.0の範囲が必要です: $v');
          }
        }
        final sum = row.fold(0.0, (a, b) => a + b);
        if ((sum - 1.0).abs() > 0.05) {
          add(s, 'row-not-normalized', 'attention[$i]の行の合計($sum)が1.0から外れています');
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
