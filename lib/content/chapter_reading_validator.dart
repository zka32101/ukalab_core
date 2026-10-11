import 'dart:convert';

import '../config/exam_config.dart';
import '../experience/chapter_reading.dart';
import 'question_validator.dart' show ContentIssue;

class ParsedChapterReadings {
  const ParsedChapterReadings(this.items, this.issues);

  final List<ChapterReading> items;

  /// 読み込み（JSON 構文・必須項目）で見つかった問題。
  final List<ContentIssue> issues;
}

/// JSON Lines（1行1件）を読む。読めない行は [ParsedChapterReadings.issues] に
/// 入れて続行する。
ParsedChapterReadings parseChapterReadingsJsonl(String text) {
  final items = <ChapterReading>[];
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
      items.add(ChapterReading.fromJson(decoded));
    } on FormatException catch (e) {
      issues.add(ContentIssue('line:${i + 1}', 'parse', e.message));
    }
  }
  return ParsedChapterReadings(items, issues);
}

/// 配信前の品質ゲート。節が空でないか、章・用語・問題の参照が有効かを検査する。
///
/// [exam] を渡すと、examId・subjectId が試験定義と整合するかも検査する。
List<ContentIssue> validateChapterReadings(
  List<ChapterReading> items, {
  ExamConfig? exam,
  List<String>? termIds,
  List<String>? questionIds,
}) {
  final issues = <ContentIssue>[];
  void add(ChapterReading r, String code, String message) =>
      issues.add(ContentIssue(r.readingId, code, message));

  final seenIds = <String>{};
  for (final r in items) {
    if (!seenIds.add(r.readingId)) {
      add(r, 'duplicate-id', 'readingId が重複しています');
    }

    if (r.title.trim().isEmpty) add(r, 'empty-title', 'title が空です');
    if (r.sourceRef.trim().isEmpty) add(r, 'no-source', '出典の説明がありません');
    if (r.contentVer.trim().isEmpty) add(r, 'no-content-ver', 'contentVer がありません');

    for (var i = 0; i < r.sections.length; i++) {
      final s = r.sections[i];
      if (s.heading.trim().isEmpty) {
        add(r, 'empty-section-heading', '節[$i]のheadingが空です');
      }
      if (s.body.trim().isEmpty) {
        add(r, 'empty-section-body', '節[$i]のbodyが空です');
      }
    }

    if (exam != null && r.examId != exam.examId) {
      add(r, 'exam-mismatch', 'examId(${r.examId}) が試験(${exam.examId})と一致しません');
    }
    if (exam != null && exam.subject(r.subjectId) == null) {
      add(r, 'unknown-subject', '未定義のsubjectId: ${r.subjectId}');
    }
    if (termIds != null) {
      for (final id in r.relatedTermIds) {
        if (!termIds.contains(id)) {
          add(r, 'unknown-related-term', '未定義の関連用語termId: $id');
        }
      }
    }
    if (questionIds != null) {
      for (final id in r.relatedQuestionIds) {
        if (!questionIds.contains(id)) {
          add(r, 'unknown-related-question', '未定義の関連問題qid: $id');
        }
      }
    }
  }
  return issues;
}
