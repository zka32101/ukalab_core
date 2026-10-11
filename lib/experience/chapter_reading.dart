import '../question/question.dart' show QuestionSource;
import '../src/json_util.dart';

/// 章ごとの解説読み物の1節（見出し＋本文）。
class ReadingSection {
  const ReadingSection({required this.heading, required this.body});

  final String heading;
  final String body;

  factory ReadingSection.fromJson(Map<String, dynamic> j, String where) {
    return ReadingSection(
      heading: reqString(j, 'heading', where),
      body: reqString(j, 'body', where),
    );
  }

  Map<String, dynamic> toJson() => {'heading': heading, 'body': body};
}

/// 章ごとの解説読み物（教科書的なまとめページ）。
///
/// 用語の暗記だけでなく、章の学習項目を体系的に読める記事を提供する。
/// 問題・解説文中の用語と同じく [relatedTermIds]・[relatedQuestionIds] で
/// 用語カード・関連問題に繋げる。
class ChapterReading {
  const ChapterReading({
    required this.readingId,
    required this.examId,
    required this.subjectId,
    required this.title,
    required this.sections,
    required this.source,
    required this.sourceRef,
    required this.contentVer,
    this.relatedTermIds = const [],
    this.relatedQuestionIds = const [],
    this.disabled = false,
  });

  final String readingId;
  final String examId;

  /// 対象の章（ExamConfig の subjectId）。
  final String subjectId;

  /// 章の見出し（例: 「3 機械学習の概要」）。
  final String title;

  /// 節（見出し＋本文）の並び。
  final List<ReadingSection> sections;

  final List<String> relatedTermIds;
  final List<String> relatedQuestionIds;

  final QuestionSource source;
  final String sourceRef;
  final String contentVer;
  final bool disabled;

  factory ChapterReading.fromJson(Map<String, dynamic> j) {
    final readingId = reqString(j, 'readingId', 'chapterReading');
    final where = 'chapterReading[$readingId]';

    final sourceName = reqString(j, 'source', where);
    final source = QuestionSource.values.where((s) => s.name == sourceName);
    if (source.isEmpty) {
      fail(where, '"source" は original / statute / licensed のいずれか');
    }

    final sectionsJson = j['sections'];
    if (sectionsJson is! List || sectionsJson.isEmpty) {
      fail(where, '"sections" は1件以上の配列が必要です');
    }
    final sections = sectionsJson
        .map((s) => ReadingSection.fromJson(s as Map<String, dynamic>, where))
        .toList();

    return ChapterReading(
      readingId: readingId,
      examId: reqString(j, 'examId', where),
      subjectId: reqString(j, 'subjectId', where),
      title: reqString(j, 'title', where),
      sections: sections,
      relatedTermIds: _stringList(j, 'relatedTermIds', where),
      relatedQuestionIds: _stringList(j, 'relatedQuestionIds', where),
      source: source.first,
      sourceRef: reqString(j, 'sourceRef', where),
      contentVer: reqString(j, 'contentVer', where),
      disabled: j['disabled'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'readingId': readingId,
        'examId': examId,
        'subjectId': subjectId,
        'title': title,
        'sections': sections.map((s) => s.toJson()).toList(),
        if (relatedTermIds.isNotEmpty) 'relatedTermIds': relatedTermIds,
        if (relatedQuestionIds.isNotEmpty) 'relatedQuestionIds': relatedQuestionIds,
        'source': source.name,
        'sourceRef': sourceRef,
        'contentVer': contentVer,
        if (disabled) 'disabled': true,
      };

  static List<String> _stringList(
    Map<String, dynamic> j,
    String key,
    String where,
  ) {
    final v = j[key];
    if (v == null) return const [];
    if (v is! List || v.any((e) => e is! String)) {
      fail(where, '"$key" は文字列の配列が必要です');
    }
    return v.cast<String>();
  }
}
