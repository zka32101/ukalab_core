import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

final exam = ExamConfig.fromJson(
  jsonDecode(File('example/sample_exam.json').readAsStringSync())
      as Map<String, dynamic>,
);

ChapterReading reading({
  String readingId = 'r1',
  String examId = 'sample',
  String subjectId = 'math',
  String title = '計算の基礎',
  List<ReadingSection> sections = const [
    ReadingSection(heading: '導入', body: '計算とは何かを説明する。'),
  ],
  List<String> relatedTermIds = const [],
  List<String> relatedQuestionIds = const [],
  QuestionSource source = QuestionSource.original,
  String sourceRef = '自作（シラバスに基づく）',
  String contentVer = '1',
}) =>
    ChapterReading(
      readingId: readingId,
      examId: examId,
      subjectId: subjectId,
      title: title,
      sections: sections,
      relatedTermIds: relatedTermIds,
      relatedQuestionIds: relatedQuestionIds,
      source: source,
      sourceRef: sourceRef,
      contentVer: contentVer,
    );

Set<String> codes(List<ContentIssue> issues) => {for (final i in issues) i.code};

void main() {
  test('正しい項目は指摘なし', () {
    expect(validateChapterReadings([reading()], exam: exam), isEmpty);
  });

  test('readingId の重複', () {
    expect(
      codes(validateChapterReadings([reading(), reading()])),
      contains('duplicate-id'),
    );
  });

  group('必須項目', () {
    test('title が空', () {
      expect(
        codes(validateChapterReadings([reading(title: ' ')])),
        contains('empty-title'),
      );
    });
    test('sourceRef が空', () {
      expect(
        codes(validateChapterReadings([reading(sourceRef: ' ')])),
        contains('no-source'),
      );
    });
    test('contentVer が空', () {
      expect(
        codes(validateChapterReadings([reading(contentVer: '')])),
        contains('no-content-ver'),
      );
    });
    test('節の heading が空', () {
      expect(
        codes(validateChapterReadings([
          reading(sections: const [ReadingSection(heading: ' ', body: '本文')]),
        ])),
        contains('empty-section-heading'),
      );
    });
    test('節の body が空', () {
      expect(
        codes(validateChapterReadings([
          reading(sections: const [ReadingSection(heading: '見出し', body: ' ')]),
        ])),
        contains('empty-section-body'),
      );
    });
  });

  test('試験定義との整合', () {
    expect(
      codes(validateChapterReadings([reading(examId: 'other')], exam: exam)),
      contains('exam-mismatch'),
    );
  });

  test('未定義の subjectId', () {
    expect(
      codes(validateChapterReadings([reading(subjectId: 'nope')], exam: exam)),
      contains('unknown-subject'),
    );
  });

  test('関連用語の整合', () {
    expect(
      codes(validateChapterReadings(
        [reading(relatedTermIds: const ['nope'])],
        termIds: const ['t1'],
      )),
      contains('unknown-related-term'),
    );
  });

  test('関連問題の整合', () {
    expect(
      codes(validateChapterReadings(
        [reading(relatedQuestionIds: const ['nope'])],
        questionIds: const ['q1'],
      )),
      contains('unknown-related-question'),
    );
  });

  group('JSON Lines の読み込み', () {
    test('壊れた行は行番号つきの issue になり、他の行は読み込まれる', () {
      final good = jsonEncode(reading().toJson());
      final parsed = parseChapterReadingsJsonl('$good\nこれはJSONではない\n\n[1,2]\n');
      expect(parsed.items, hasLength(1));
      expect(parsed.issues.map((i) => i.qid), ['line:2', 'line:4']);
      expect(parsed.issues.every((i) => i.code == 'parse'), isTrue);
    });

    test('sections が空の配列だとパースエラー', () {
      expect(
        () => ChapterReading.fromJson({
          'readingId': 'r1',
          'examId': 'sample',
          'subjectId': 'math',
          'title': 'タイトル',
          'sections': [],
          'source': 'original',
          'sourceRef': '自作',
          'contentVer': '1',
        }),
        throwsFormatException,
      );
    });
  });
}
