import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

final exam = ExamConfig.fromJson(
  jsonDecode(File('example/sample_exam.json').readAsStringSync())
      as Map<String, dynamic>,
);

List<List<double>> _grid8x8() => [
      for (var r = 0; r < 8; r++) [for (var c = 0; c < 8; c++) (r + c) % 2 == 0 ? 1.0 : 0.0],
    ];

ConvLabImage image({
  String imageId = 'i1',
  String examId = 'sample',
  String? subjectId = 'math',
  String title = '手書き風の「1」',
  String description = '縦棒だけの画像。',
  List<List<double>>? grid,
  QuestionSource source = QuestionSource.original,
  String sourceRef = '自作（教育用の仮データ）',
  String contentVer = '1',
}) =>
    ConvLabImage(
      imageId: imageId,
      examId: examId,
      subjectId: subjectId,
      title: title,
      description: description,
      grid: grid ?? _grid8x8(),
      source: source,
      sourceRef: sourceRef,
      contentVer: contentVer,
    );

Set<String> codes(List<ContentIssue> issues) => {for (final i in issues) i.code};

void main() {
  test('正しい画像は指摘なし', () {
    expect(validateConvLabImages([image()], exam: exam), isEmpty);
  });

  test('imageId の重複', () {
    expect(
      codes(validateConvLabImages([image(), image()])),
      contains('duplicate-id'),
    );
  });

  group('必須項目', () {
    test('description が空', () {
      expect(
        codes(validateConvLabImages([image(description: ' ')])),
        contains('empty-description'),
      );
    });
    test('sourceRef が空', () {
      expect(
        codes(validateConvLabImages([image(sourceRef: ' ')])),
        contains('no-source'),
      );
    });
    test('contentVer が空', () {
      expect(
        codes(validateConvLabImages([image(contentVer: '')])),
        contains('no-content-ver'),
      );
    });
  });

  group('grid', () {
    test('行の長さが揃っていない', () {
      expect(
        codes(validateConvLabImages([
          image(grid: [
            [0, 1, 0, 1, 0, 1],
            [0, 1, 0, 1, 0],
          ]),
        ])),
        contains('not-rectangular'),
      );
    });

    test('小さすぎる格子', () {
      expect(
        codes(validateConvLabImages([
          image(grid: [
            [0, 1],
            [1, 0],
          ]),
        ])),
        contains('too-small'),
      );
    });

    test('値が範囲外', () {
      expect(
        codes(validateConvLabImages([
          image(grid: [
            for (var r = 0; r < 6; r++) [for (var c = 0; c < 6; c++) r == 0 && c == 0 ? 1.5 : 0.0],
          ]),
        ])),
        contains('out-of-range'),
      );
    });
  });

  test('試験定義との整合', () {
    expect(
      codes(validateConvLabImages([image(examId: 'other')], exam: exam)),
      contains('exam-mismatch'),
    );
    expect(
      codes(validateConvLabImages([image(subjectId: 'zzz')], exam: exam)),
      contains('unknown-subject'),
    );
    expect(
      validateConvLabImages([image(subjectId: null)], exam: exam),
      isEmpty,
    );
  });

  group('JSON Lines の読み込み', () {
    test('壊れた行は行番号つきの issue になり、他の行は読み込まれる', () {
      final good = jsonEncode(image().toJson());
      final parsed = parseConvLabImagesJsonl('$good\nこれはJSONではない\n\n[1,2]\n');
      expect(parsed.images, hasLength(1));
      expect(parsed.issues.map((i) => i.qid), ['line:2', 'line:4']);
      expect(parsed.issues.every((i) => i.code == 'parse'), isTrue);
    });
  });
}
