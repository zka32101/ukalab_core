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
    if (r.contentVer.trim().isEmpty)
      add(r, 'no-content-ver', 'contentVer がありません');

    for (var i = 0; i < r.sections.length; i++) {
      final s = r.sections[i];
      if (s.heading.trim().isEmpty) {
        add(r, 'empty-section-heading', '節[$i]のheadingが空です');
      }
      _validateSectionKind(r, s, i, add);
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

/// 節の種類（kind）ごとの検査。kind 省略/text は従来どおり body 必須のみ。
void _validateSectionKind(
  ChapterReading r,
  ReadingSection s,
  int i,
  void Function(ChapterReading, String, String) add,
) {
  switch (s.kind) {
    case kReadingSectionText:
      if (s.body.trim().isEmpty) {
        add(r, 'empty-section-body', '節[$i]のbodyが空です');
      }
    case kReadingSectionTable:
      final t = s.table;
      if (t == null) {
        add(r, 'table-missing', '節[$i]は kind=table ですが table がありません');
        break;
      }
      if (t.columns.isEmpty || t.columns.any((c) => c.trim().isEmpty)) {
        add(r, 'table-empty-column', '節[$i]の table.columns に空の列見出しがあります');
      }
      if (t.columns.length > kReadingTableMaxColumns) {
        add(
          r,
          'table-too-many-columns',
          '節[$i]の列数(${t.columns.length})が上限$kReadingTableMaxColumnsを超えています',
        );
      }
      if (t.rows.isEmpty) {
        add(r, 'table-no-rows', '節[$i]の table.rows が空です');
      }
      if (t.rows.length > kReadingTableMaxRows) {
        add(
          r,
          'table-too-many-rows',
          '節[$i]の行数(${t.rows.length})が上限$kReadingTableMaxRowsを超えています',
        );
      }
      for (var k = 0; k < t.rows.length; k++) {
        if (t.rows[k].length != t.columns.length) {
          add(
            r,
            'table-row-length',
            '節[$i]の行[$k]のセル数(${t.rows[k].length})が列数(${t.columns.length})と一致しません',
          );
        }
      }
    case kReadingSectionSteps:
      final st = s.steps;
      if (st == null || st.isEmpty) {
        add(r, 'steps-empty', '節[$i]は kind=steps ですが steps が空です');
      } else if (st.any((e) => e.trim().isEmpty)) {
        add(r, 'steps-empty-item', '節[$i]の steps に空の手順があります');
      }
    case kReadingSectionFigure:
      final f = s.figure;
      if (f == null) {
        add(r, 'figure-missing', '節[$i]は kind=figure ですが figure がありません');
        break;
      }
      final alt = f.alt.trim();
      if (alt.isEmpty) {
        add(r, 'figure-no-alt', '節[$i]の figure.alt が空です');
      } else if (alt.length > kReadingFigureAltMaxLength) {
        add(
          r,
          'figure-alt-too-long',
          '節[$i]の figure.alt が$kReadingFigureAltMaxLength文字を超えています',
        );
      }
      final a = f.asset.trim();
      if (a.startsWith('/') ||
          a.contains('..') ||
          a.contains('\\') ||
          RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(a)) {
        add(
          r,
          'figure-bad-asset',
          '節[$i]の figure.asset は assets 配下の相対パスにしてください: $a',
        );
      }
    default:
      add(
        r,
        'unknown-section-kind',
        '節[$i]の kind(${s.kind}) は ${kReadingSectionKinds.join(" / ")} のいずれか',
      );
      if (s.body.trim().isEmpty) {
        add(r, 'empty-section-body', '節[$i]のbodyが空です');
      }
  }
}
