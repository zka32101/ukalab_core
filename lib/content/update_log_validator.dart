import 'dart:convert';

import '../config/exam_config.dart';
import '../experience/update_log.dart';
import 'question_validator.dart' show ContentIssue;

class ParsedUpdateLog {
  const ParsedUpdateLog(this.entries, this.issues);

  final List<UpdateLogEntry> entries;

  /// 読み込み（JSON 構文・必須項目）で見つかった問題。
  final List<ContentIssue> issues;
}

/// JSON Lines（1行1件）を読む。読めない行は [ParsedUpdateLog.issues] に入れて続行する。
ParsedUpdateLog parseUpdateLogJsonl(String text) {
  final entries = <UpdateLogEntry>[];
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
      entries.add(UpdateLogEntry.fromJson(decoded));
    } on FormatException catch (e) {
      issues.add(ContentIssue('line:${i + 1}', 'parse', e.message));
    }
  }
  return ParsedUpdateLog(entries, issues);
}

/// 配信前の品質ゲート。ID重複・空の見出し・負の件数・根拠の版の欠落を検査する。
/// [exam] を渡すと、examId が試験定義と一致するかも検査する。
List<ContentIssue> validateUpdateLog(
  List<UpdateLogEntry> entries, {
  ExamConfig? exam,
}) {
  final issues = <ContentIssue>[];
  void add(UpdateLogEntry e, String code, String message) =>
      issues.add(ContentIssue(e.entryId, code, message));

  final seen = <String>{};
  for (final e in entries) {
    if (!seen.add(e.entryId)) add(e, 'duplicate-id', 'entryId が重複しています');
    if (e.title.trim().isEmpty) add(e, 'empty-title', '見出し(title)が空です');
    if (e.affectedQuestions < 0) {
      add(e, 'negative-count', 'affectedQuestions は0以上が必要です');
    }
    final needsVersion =
        e.kind == UpdateKind.lawChange || e.kind == UpdateKind.syllabusChange;
    if (needsVersion && (e.versionRef == null || e.versionRef!.trim().isEmpty)) {
      add(e, 'no-version-ref', '法改正・シラバス改訂には根拠の版(versionRef)が必要です');
    }
    if (exam != null && e.examId != exam.examId) {
      add(e, 'exam-mismatch', 'examId(${e.examId}) が試験(${exam.examId})と一致しません');
    }
  }
  return issues;
}
