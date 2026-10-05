import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

final exam = ExamConfig.fromJson(
  jsonDecode(File('example/sample_exam.json').readAsStringSync())
      as Map<String, dynamic>,
);

const _defaultPoints = [
  NnBuilderPoint(x: 1, y: 1, label: 0),
  NnBuilderPoint(x: 2, y: 1.5, label: 0),
  NnBuilderPoint(x: 1.5, y: 2, label: 0),
  NnBuilderPoint(x: 8, y: 8, label: 1),
  NnBuilderPoint(x: 7, y: 8.5, label: 1),
  NnBuilderPoint(x: 8.5, y: 7, label: 1),
];

NnBuilderDataset dataset({
  String datasetId = 'd1',
  String examId = 'sample',
  String? subjectId = 'math',
  String title = '線形分離',
  String description = '2クラスの点。',
  List<NnBuilderPoint> points = _defaultPoints,
  QuestionSource source = QuestionSource.original,
  String sourceRef = '自作',
  String contentVer = '1',
}) =>
    NnBuilderDataset(
      datasetId: datasetId,
      examId: examId,
      subjectId: subjectId,
      title: title,
      description: description,
      points: points,
      source: source,
      sourceRef: sourceRef,
      contentVer: contentVer,
    );

Set<String> codes(List<ContentIssue> issues) => {for (final i in issues) i.code};

void main() {
  test('正しいデータセットは指摘なし', () {
    expect(validateNnBuilderDatasets([dataset()], exam: exam), isEmpty);
  });

  test('datasetId の重複', () {
    expect(
      codes(validateNnBuilderDatasets([dataset(), dataset()])),
      contains('duplicate-id'),
    );
  });

  group('必須項目', () {
    test('description が空', () {
      expect(
        codes(validateNnBuilderDatasets([dataset(description: ' ')])),
        contains('empty-description'),
      );
    });
    test('sourceRef が空', () {
      expect(
        codes(validateNnBuilderDatasets([dataset(sourceRef: ' ')])),
        contains('no-source'),
      );
    });
    test('contentVer が空', () {
      expect(
        codes(validateNnBuilderDatasets([dataset(contentVer: '')])),
        contains('no-content-ver'),
      );
    });
  });

  group('データ点', () {
    test('点が5点以下では不足', () {
      expect(
        codes(validateNnBuilderDatasets([
          dataset(points: _defaultPoints.sublist(0, 5)),
        ])),
        contains('too-few-points'),
      );
    });

    test('片方のクラスしかない', () {
      expect(
        codes(validateNnBuilderDatasets([
          dataset(points: [for (final p in _defaultPoints) NnBuilderPoint(x: p.x, y: p.y, label: 0)]),
        ])),
        contains('single-class'),
      );
    });

    test('座標が範囲外', () {
      expect(
        codes(validateNnBuilderDatasets([
          dataset(points: [..._defaultPoints, const NnBuilderPoint(x: 11, y: 5, label: 1)]),
        ])),
        contains('out-of-range'),
      );
    });
  });

  test('試験定義との整合', () {
    expect(
      codes(validateNnBuilderDatasets([dataset(examId: 'other')], exam: exam)),
      contains('exam-mismatch'),
    );
    expect(
      codes(validateNnBuilderDatasets([dataset(subjectId: 'zzz')], exam: exam)),
      contains('unknown-subject'),
    );
    expect(
      validateNnBuilderDatasets([dataset(subjectId: null)], exam: exam),
      isEmpty,
    );
  });

  group('JSON Lines の読み込み', () {
    test('壊れた行は行番号つきの issue になり、他の行は読み込まれる', () {
      final good = jsonEncode(dataset().toJson());
      final parsed = parseNnBuilderDatasetsJsonl('$good\nこれはJSONではない\n\n[1,2]\n');
      expect(parsed.datasets, hasLength(1));
      expect(parsed.issues.map((i) => i.qid), ['line:2', 'line:4']);
      expect(parsed.issues.every((i) => i.code == 'parse'), isTrue);
    });
  });
}
