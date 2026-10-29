import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

final exam = ExamConfig.fromJson(
  jsonDecode(File('example/sample_exam.json').readAsStringSync())
      as Map<String, dynamic>,
);

ChapterReading reading(List<ReadingSection> sections) => ChapterReading(
  readingId: 'r1',
  examId: 'sample',
  subjectId: 'math',
  title: '計算の基礎',
  sections: sections,
  source: QuestionSource.original,
  sourceRef: '自作',
  contentVer: '1',
);

Set<String> codes(List<ReadingSection> sections) => {
  for (final i in validateChapterReadings([reading(sections)], exam: exam))
    i.code,
};

const _legacy = {
  'readingId': 'r1',
  'examId': 'sample',
  'subjectId': 'math',
  'title': '計算の基礎',
  'sections': [
    {'heading': '導入', 'body': '本文です。'},
  ],
  'relatedQuestionIds': ['q1'],
  'source': 'original',
  'sourceRef': '自作',
  'contentVer': '1',
};

void main() {
  group('ReadingSection JSON', () {
    test('既存形式（heading+body）は読めて、往復で完全一致する', () {
      final r = ChapterReading.fromJson(Map<String, dynamic>.from(_legacy));
      expect(r.sections.single.kind, 'text');
      expect(r.sections.single.table, isNull);
      expect(jsonDecode(jsonEncode(r.toJson())), _legacy);
    });

    test('未指定の追加キーは出力しない', () {
      const s = ReadingSection(heading: 'h', body: 'b');
      expect(s.toJson(), {'heading': 'h', 'body': 'b'});
    });

    test('table / steps / figure は往復で一致し、body は省略できる', () {
      final json = {
        'readingId': 'r2',
        'examId': 'sample',
        'subjectId': 'math',
        'title': 't',
        'sections': [
          {
            'heading': '表',
            'kind': 'table',
            'table': {
              'columns': ['用語', '意味'],
              'rows': [
                ['a', 'b'],
                ['c', 'd'],
              ],
            },
          },
          {
            'heading': '手順',
            'kind': 'steps',
            'steps': ['まず', '次に'],
            'body': '補足',
          },
          {
            'heading': '図',
            'kind': 'figure',
            'figure': {
              'asset': 'assets/r/x.png',
              'alt': '流れ図',
              'caption': '図1',
            },
          },
        ],
        'source': 'original',
        'sourceRef': '自作',
        'contentVer': '1',
      };
      final r = ChapterReading.fromJson(json);
      expect(r.sections[0].body, '');
      expect(r.sections[1].steps, ['まず', '次に']);
      expect(r.sections[2].figure!.alt, '流れ図');
      expect(jsonDecode(jsonEncode(r.toJson())), json);
      expect(validateChapterReadings([r], exam: exam), isEmpty);
    });

    test('text の body 欠落は従来どおり読み込みエラー', () {
      final bad = Map<String, dynamic>.from(_legacy)
        ..['sections'] = [
          {'heading': 'h'},
        ];
      expect(() => ChapterReading.fromJson(bad), throwsFormatException);
    });

    test('型が違う table / steps / figure は読み込みエラー', () {
      for (final bad in [
        {'heading': 'h', 'kind': 'table', 'table': 'x'},
        {
          'heading': 'h',
          'kind': 'steps',
          'steps': [1],
        },
        {
          'heading': 'h',
          'kind': 'figure',
          'figure': {'asset': 'a'},
        },
      ]) {
        expect(() => ReadingSection.fromJson(bad, 'w'), throwsFormatException);
      }
    });
  });

  group('validateChapterReadings（kind）', () {
    test('従来の節は通る', () {
      expect(codes(const [ReadingSection(heading: 'h', body: 'b')]), isEmpty);
      expect(codes(const [ReadingSection(heading: 'h')]), {
        'empty-section-body',
      });
    });

    test('table: 列数・行長・上限・空', () {
      const ok = ReadingTable(
        columns: ['a', 'b'],
        rows: [
          ['1', '2'],
        ],
      );
      expect(
        codes([const ReadingSection(heading: 'h', kind: 'table', table: ok)]),
        isEmpty,
      );
      expect(codes(const [ReadingSection(heading: 'h', kind: 'table')]), {
        'table-missing',
      });
      expect(
        codes(const [
          ReadingSection(
            heading: 'h',
            kind: 'table',
            table: ReadingTable(
              columns: ['a', 'b'],
              rows: [
                ['1'],
              ],
            ),
          ),
        ]),
        {'table-row-length'},
      );
      expect(
        codes([
          ReadingSection(
            heading: 'h',
            kind: 'table',
            table: ReadingTable(
              columns: List.filled(kReadingTableMaxColumns + 1, 'c'),
              rows: [List.filled(kReadingTableMaxColumns + 1, 'x')],
            ),
          ),
        ]),
        {'table-too-many-columns'},
      );
      expect(
        codes([
          ReadingSection(
            heading: 'h',
            kind: 'table',
            table: ReadingTable(
              columns: const ['a'],
              rows: List.generate(kReadingTableMaxRows + 1, (_) => ['x']),
            ),
          ),
        ]),
        {'table-too-many-rows'},
      );
      expect(
        codes(const [
          ReadingSection(
            heading: 'h',
            kind: 'table',
            table: ReadingTable(columns: ['a'], rows: []),
          ),
        ]),
        {'table-no-rows'},
      );
    });

    test('steps: 空は不可', () {
      expect(
        codes(const [ReadingSection(heading: 'h', kind: 'steps', steps: [])]),
        {'steps-empty'},
      );
      expect(
        codes(const [
          ReadingSection(heading: 'h', kind: 'steps', steps: ['a', ' ']),
        ]),
        {'steps-empty-item'},
      );
      expect(
        codes(const [
          ReadingSection(heading: 'h', kind: 'steps', steps: ['a']),
        ]),
        isEmpty,
      );
    });

    test('figure: alt 必須・長さ・asset は相対パス', () {
      ReadingSection fig(String asset, String alt) => ReadingSection(
        heading: 'h',
        kind: 'figure',
        figure: ReadingFigure(asset: asset, alt: alt),
      );
      expect(codes([fig('assets/a.png', '説明')]), isEmpty);
      expect(codes([fig('assets/a.png', ' ')]), {'figure-no-alt'});
      expect(
        codes([fig('assets/a.png', 'あ' * (kReadingFigureAltMaxLength + 1))]),
        {'figure-alt-too-long'},
      );
      expect(codes([fig('/abs/a.png', 'x')]), {'figure-bad-asset'});
      expect(codes([fig('https://x.example/a.png', 'x')]), {
        'figure-bad-asset',
      });
      expect(codes([fig('../a.png', 'x')]), {'figure-bad-asset'});
      expect(codes(const [ReadingSection(heading: 'h', kind: 'figure')]), {
        'figure-missing',
      });
    });

    test('未知の kind は指摘される', () {
      expect(
        codes(const [ReadingSection(heading: 'h', body: 'b', kind: 'video')]),
        {'unknown-section-kind'},
      );
    });

    test('JSONL 経由でも新形式を読める', () {
      final line = jsonEncode({
        ..._legacy,
        'sections': [
          {
            'heading': 'h',
            'kind': 'steps',
            'steps': ['a'],
          },
        ],
      });
      final parsed = parseChapterReadingsJsonl(line);
      expect(parsed.issues, isEmpty);
      expect(parsed.items.single.sections.single.kind, 'steps');
    });
  });

  group('ExplanationParts', () {
    test('目印なしは全文を body にする', () {
      final p = ExplanationParts.fromPlain('ふつうの解説。');
      expect(p.body, 'ふつうの解説。');
      expect(p.hasOtherScene, isFalse);
    });

    test('【別の場面】で分ける', () {
      final p = ExplanationParts.fromPlain('本文です。\n\n【別の場面】別の例です。');
      expect(p.body, '本文です。');
      expect(p.otherScene, '別の例です。');
    });

    test('パース不能（複数・片側が空）は全文のまま', () {
      for (final t in ['a【別の場面】b【別の場面】c', '【別の場面】だけ', '本文だけ【別の場面】']) {
        final p = ExplanationParts.fromPlain(t);
        expect(p.body, t);
        expect(p.otherScene, isNull);
      }
    });

    test('readingsForQuestion は関連する有効な読み物だけ返す', () {
      ChapterReading r(
        String id, {
        bool disabled = false,
        List<String> q = const ['q1'],
      }) => ChapterReading(
        readingId: id,
        examId: 'sample',
        subjectId: 'math',
        title: id,
        sections: const [ReadingSection(heading: 'h', body: 'b')],
        relatedQuestionIds: q,
        source: QuestionSource.original,
        sourceRef: '自作',
        contentVer: '1',
        disabled: disabled,
      );
      final out = readingsForQuestion([
        r('a'),
        r('b', disabled: true),
        r('c', q: ['q2']),
      ], 'q1');
      expect(out.map((e) => e.readingId), ['a']);
    });
  });
}
