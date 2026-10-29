import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

Map<String, dynamic> _json({Map<String, dynamic> extra = const {}}) => {
  'readingId': 'r1',
  'examId': 'sample',
  'subjectId': 'math',
  'title': '読み物',
  'sections': [
    {'heading': '導入', 'body': '本文です。'},
  ],
  'source': 'original',
  'sourceRef': '自作',
  'contentVer': '1',
  ...extra,
};

ChapterReading _r(String id, {String? levelId, List<ContentLink>? links}) =>
    ChapterReading(
      readingId: id,
      examId: 'sample',
      subjectId: 'math',
      title: 't$id',
      sections: const [ReadingSection(heading: 'h', body: 'b')],
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
      levelId: levelId,
      relatedLinks: links ?? const [],
    );

Set<String> _codes(ChapterReading r) => {
  for (final i in validateChapterReadings([r])) i.code,
};

void main() {
  group('levelId', () {
    test('未指定は JSON に出ず往復一致', () {
      final j = _json();
      final r = ChapterReading.fromJson(j);
      expect(r.levelId, isNull);
      expect(r.toJson().containsKey('levelId'), isFalse);
      expect(r.toJson().containsKey('relatedLinks'), isFalse);
      expect(r.toJson(), j);
    });

    test('指定は往復一致', () {
      final j = _json(extra: {'levelId': 'level3_from_2027_04'});
      final r = ChapterReading.fromJson(j);
      expect(r.levelId, 'level3_from_2027_04');
      expect(r.toJson(), j);
    });

    test('readingsForLevel: null は常に含め、指定は一致のみ', () {
      final all = [
        _r('a'),
        _r('b', levelId: 'l3'),
        _r('c', levelId: 'l2'),
      ];
      expect(readingsForLevel(all, 'l3').map((r) => r.readingId), ['a', 'b']);
      expect(readingsForLevel(all, 'l2').map((r) => r.readingId), ['a', 'c']);
      expect(readingsForLevel(all, 'x').map((r) => r.readingId), ['a']);
      expect(readingsForLevel(all, null).length, 3);
    });

    test('validator: 空文字は拒否、通常値は通す', () {
      expect(_codes(_r('a', levelId: '')), contains('empty-level-id'));
      expect(_codes(_r('a', levelId: '  ')), contains('empty-level-id'));
      expect(_codes(_r('a', levelId: 'l3')), isEmpty);
      expect(_codes(_r('a')), isEmpty);
    });
  });

  group('relatedLinks', () {
    test('往復一致', () {
      final j = _json(
        extra: {
          'relatedLinks': [
            {'kind': 'hazard', 'id': 'h1'},
            {'kind': 'story', 'id': 's1'},
          ],
        },
      );
      final r = ChapterReading.fromJson(j);
      expect(r.relatedLinks.length, 2);
      expect(r.toJson(), j);
    });

    test('不正な形は FormatException', () {
      expect(
        () => ChapterReading.fromJson(_json(extra: {'relatedLinks': 'x'})),
        throwsFormatException,
      );
      expect(
        () => ChapterReading.fromJson(
          _json(
            extra: {
              'relatedLinks': [
                {'kind': 'hazard'},
              ],
            },
          ),
        ),
        throwsFormatException,
      );
    });

    test('linksOfKind は種類で絞り順序を保つ', () {
      final r = _r(
        'a',
        links: const [
          ContentLink(kind: 'hazard', id: 'h1'),
          ContentLink(kind: 'story', id: 's1'),
          ContentLink(kind: 'hazard', id: 'h2'),
        ],
      );
      expect(linksOfKind(r, 'hazard').map((l) => l.id), ['h1', 'h2']);
      expect(linksOfKind(r, 'term'), isEmpty);
      expect(const ContentLink(kind: 'a', id: 'b'), const ContentLink(kind: 'a', id: 'b'));
    });

    test('validator: kind/id が空なら指摘', () {
      final bad = _r(
        'a',
        links: const [
          ContentLink(kind: '', id: 'x'),
          ContentLink(kind: 'hazard', id: ' '),
        ],
      );
      expect(_codes(bad), containsAll(['empty-link-kind', 'empty-link-id']));
      expect(
        _codes(_r('a', links: const [ContentLink(kind: 'hazard', id: 'h1')])),
        isEmpty,
      );
    });

    test('既存の relatedTermIds / relatedQuestionIds は従来どおり', () {
      final j = _json(
        extra: {
          'relatedTermIds': ['t1'],
          'relatedQuestionIds': ['q1'],
        },
      );
      expect(ChapterReading.fromJson(j).toJson(), j);
    });
  });
}
