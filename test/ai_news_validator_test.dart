import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

final exam = ExamConfig.fromJson(
  jsonDecode(File('example/sample_exam.json').readAsStringSync())
      as Map<String, dynamic>,
);

AiNewsItem newsItem({
  String newsItemId = 'n1',
  String examId = 'sample',
  String summary = '生成AIの新しい基盤モデルが発表された。',
  String sourceUrl = 'https://example.com/news/1',
  DateTime? sourceDate,
  String syllabusTag = '2',
  bool isExamRelevant = false,
  DateTime? asOfDate,
  String? relatedQuestionId,
  QuestionSource source = QuestionSource.original,
  String sourceRef = '自作（一次情報の要約）',
  String contentVer = '1',
}) =>
    AiNewsItem(
      newsItemId: newsItemId,
      examId: examId,
      summary: summary,
      sourceUrl: sourceUrl,
      sourceDate: sourceDate ?? DateTime(2026, 9, 1),
      syllabusTag: syllabusTag,
      isExamRelevant: isExamRelevant,
      asOfDate: asOfDate ?? DateTime(2026, 10, 1),
      relatedQuestionId: relatedQuestionId,
      source: source,
      sourceRef: sourceRef,
      contentVer: contentVer,
    );

Set<String> codes(List<ContentIssue> issues) => {for (final i in issues) i.code};

void main() {
  test('正しい項目は指摘なし', () {
    expect(validateAiNewsItems([newsItem()], exam: exam), isEmpty);
  });

  test('newsItemId の重複', () {
    expect(
      codes(validateAiNewsItems([newsItem(), newsItem()])),
      contains('duplicate-id'),
    );
  });

  group('必須項目', () {
    test('summary が空', () {
      expect(
        codes(validateAiNewsItems([newsItem(summary: ' ')])),
        contains('empty-summary'),
      );
    });
    test('sourceUrl が空', () {
      expect(
        codes(validateAiNewsItems([newsItem(sourceUrl: ' ')])),
        contains('empty-source-url'),
      );
    });
    test('syllabusTag が空', () {
      expect(
        codes(validateAiNewsItems([newsItem(syllabusTag: ' ')])),
        contains('empty-syllabus-tag'),
      );
    });
    test('sourceRef が空', () {
      expect(
        codes(validateAiNewsItems([newsItem(sourceRef: ' ')])),
        contains('no-source'),
      );
    });
    test('contentVer が空', () {
      expect(
        codes(validateAiNewsItems([newsItem(contentVer: '')])),
        contains('no-content-ver'),
      );
    });
  });

  test('asOfDate が sourceDate より前', () {
    expect(
      codes(validateAiNewsItems([
        newsItem(sourceDate: DateTime(2026, 10, 1), asOfDate: DateTime(2026, 9, 1)),
      ])),
      contains('as-of-before-source'),
    );
  });

  test('試験定義との整合', () {
    expect(
      codes(validateAiNewsItems([newsItem(examId: 'other')], exam: exam)),
      contains('exam-mismatch'),
    );
  });

  test('関連問題の整合', () {
    expect(
      codes(validateAiNewsItems(
        [newsItem(relatedQuestionId: 'nope')],
        questionIds: const ['q1', 'q2'],
      )),
      contains('unknown-related-question'),
    );
    expect(
      validateAiNewsItems(
        [newsItem(relatedQuestionId: 'q1')],
        questionIds: const ['q1', 'q2'],
      ),
      isEmpty,
    );
  });

  group('JSON Lines の読み込み', () {
    test('壊れた行は行番号つきの issue になり、他の行は読み込まれる', () {
      final good = jsonEncode(newsItem().toJson());
      final parsed = parseAiNewsItemsJsonl('$good\nこれはJSONではない\n\n[1,2]\n');
      expect(parsed.items, hasLength(1));
      expect(parsed.issues.map((i) => i.qid), ['line:2', 'line:4']);
      expect(parsed.issues.every((i) => i.code == 'parse'), isTrue);
    });
  });
}
