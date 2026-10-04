import 'dart:convert';

import '../config/exam_config.dart';
import '../experience/failure_gallery.dart';
import 'question_validator.dart' show ContentIssue;

class ParsedFailureCases {
  const ParsedFailureCases(this.cases, this.issues);

  final List<FailureCase> cases;

  /// 読み込み（JSON 構文・必須項目）で見つかった問題。
  final List<ContentIssue> issues;
}

/// JSON Lines（1行1症例）を読む。読めない行は [ParsedFailureCases.issues] に入れて続行する。
ParsedFailureCases parseFailureCasesJsonl(String text) {
  final cases = <FailureCase>[];
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
      cases.add(FailureCase.fromJson(decoded));
    } on FormatException catch (e) {
      issues.add(ContentIssue('line:${i + 1}', 'parse', e.message));
    }
  }
  return ParsedFailureCases(cases, issues);
}

/// 配信前の品質ゲート（決定76・77）。学習曲線の点数、選択肢の正解が
/// ちょうど1つか、選択肢の重複などを検査する。
///
/// [exam] を渡すと、examId・subjectId が試験定義と整合するかも検査する。
List<ContentIssue> validateFailureCases(
  List<FailureCase> cases, {
  ExamConfig? exam,
}) {
  final issues = <ContentIssue>[];
  void add(FailureCase c, String code, String message) =>
      issues.add(ContentIssue(c.caseId, code, message));

  final seenIds = <String>{};
  for (final c in cases) {
    if (!seenIds.add(c.caseId)) {
      add(c, 'duplicate-id', 'caseId が重複しています');
    }

    if (c.curve.length < 2) {
      add(c, 'too-few-curve-points', '学習曲線(curve)は2点以上必要です');
    }
    if (c.explanation.trim().isEmpty) add(c, 'empty-explanation', '解説(explanation)が空です');
    if (c.sourceRef.trim().isEmpty) add(c, 'no-source', '出典の説明がありません');
    if (c.contentVer.trim().isEmpty) add(c, 'no-content-ver', 'contentVer がありません');

    _validateOptions(c, c.symptomOptions, 'symptomOptions', add);
    _validateOptions(c, c.treatmentOptions, 'treatmentOptions', add);

    if (exam != null) {
      if (c.examId != exam.examId) {
        add(c, 'exam-mismatch', 'examId(${c.examId}) が試験(${exam.examId})と一致しません');
      }
      final subjectId = c.subjectId;
      if (subjectId != null && exam.subject(subjectId) == null) {
        add(c, 'unknown-subject', '未定義の subjectId: $subjectId');
      }
    }
  }
  return issues;
}

void _validateOptions(
  FailureCase c,
  List<FailureOption> options,
  String field,
  void Function(FailureCase c, String code, String message) add,
) {
  if (options.length < 2) {
    add(c, 'too-few-options', '$field は2つ以上必要です');
  }
  final optionIds = options.map((o) => o.optionId).toSet();
  if (optionIds.length != options.length) {
    add(c, 'duplicate-option-id', '$field の optionId が重複しています');
  }
  for (final o in options) {
    if (o.text.trim().isEmpty) add(c, 'empty-option-text', '$field の文言が空です: ${o.optionId}');
  }
  final correctCount = options.where((o) => o.isCorrect).length;
  if (correctCount == 0) {
    add(c, 'no-correct-option', '$field に正解の選択肢がありません');
  } else if (correctCount > 1) {
    add(c, 'multiple-correct-options', '$field の正解の選択肢が複数あります');
  }
}
