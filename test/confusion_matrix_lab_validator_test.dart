import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:ukalab_core/ukalab_core.dart';

final exam = ExamConfig.fromJson(
  jsonDecode(File('example/sample_exam.json').readAsStringSync())
      as Map<String, dynamic>,
);

ConfusionMatrixScenario scenario({
  String scenarioId = 's1',
  String examId = 'sample',
  String? subjectId = 'math',
  String title = 'がん検診',
  String description = '見逃し(偽陰性)と誤検知(偽陽性)、どちらが重いか。',
  int initialTp = 40,
  int initialFp = 10,
  int initialFn = 10,
  int initialTn = 40,
  List<ConfusionMatrixOption> options = const [
    ConfusionMatrixOption(optionId: 'recall', text: '再現率を優先する', isCorrect: true),
    ConfusionMatrixOption(optionId: 'precision', text: '適合率を優先する', isCorrect: false),
  ],
  String explanation = '解説。',
  QuestionSource source = QuestionSource.original,
  String sourceRef = '自作',
  String contentVer = '1',
}) =>
    ConfusionMatrixScenario(
      scenarioId: scenarioId,
      examId: examId,
      subjectId: subjectId,
      title: title,
      description: description,
      initialTp: initialTp,
      initialFp: initialFp,
      initialFn: initialFn,
      initialTn: initialTn,
      options: options,
      explanation: explanation,
      source: source,
      sourceRef: sourceRef,
      contentVer: contentVer,
    );

Set<String> codes(List<ContentIssue> issues) => {for (final i in issues) i.code};

void main() {
  test('正しい場面は指摘なし', () {
    expect(validateConfusionMatrixScenarios([scenario()], exam: exam), isEmpty);
  });

  test('scenarioId の重複', () {
    expect(
      codes(validateConfusionMatrixScenarios([scenario(), scenario()])),
      contains('duplicate-id'),
    );
  });

  group('必須項目', () {
    test('初期の混同行列が負', () {
      expect(
        codes(validateConfusionMatrixScenarios([scenario(initialTp: -1)])),
        contains('negative-count'),
      );
    });
    test('description が空', () {
      expect(
        codes(validateConfusionMatrixScenarios([scenario(description: ' ')])),
        contains('empty-description'),
      );
    });
    test('explanation が空', () {
      expect(
        codes(validateConfusionMatrixScenarios([scenario(explanation: ' ')])),
        contains('empty-explanation'),
      );
    });
    test('sourceRef が空', () {
      expect(
        codes(validateConfusionMatrixScenarios([scenario(sourceRef: ' ')])),
        contains('no-source'),
      );
    });
    test('contentVer が空', () {
      expect(
        codes(validateConfusionMatrixScenarios([scenario(contentVer: '')])),
        contains('no-content-ver'),
      );
    });
  });

  group('選択肢', () {
    test('選択肢が1つだけでは不足', () {
      expect(
        codes(validateConfusionMatrixScenarios([
          scenario(options: const [
            ConfusionMatrixOption(optionId: 'right', text: '正解', isCorrect: true),
          ]),
        ])),
        contains('too-few-options'),
      );
    });

    test('optionId の重複', () {
      expect(
        codes(validateConfusionMatrixScenarios([
          scenario(options: const [
            ConfusionMatrixOption(optionId: 'a', text: 'A', isCorrect: true),
            ConfusionMatrixOption(optionId: 'a', text: 'B', isCorrect: false),
          ]),
        ])),
        contains('duplicate-option-id'),
      );
    });

    test('選択肢の文言が空', () {
      expect(
        codes(validateConfusionMatrixScenarios([
          scenario(options: const [
            ConfusionMatrixOption(optionId: 'a', text: ' ', isCorrect: true),
            ConfusionMatrixOption(optionId: 'b', text: 'B', isCorrect: false),
          ]),
        ])),
        contains('empty-option-text'),
      );
    });

    test('正解の選択肢がない', () {
      expect(
        codes(validateConfusionMatrixScenarios([
          scenario(options: const [
            ConfusionMatrixOption(optionId: 'a', text: 'A', isCorrect: false),
            ConfusionMatrixOption(optionId: 'b', text: 'B', isCorrect: false),
          ]),
        ])),
        contains('no-correct-option'),
      );
    });

    test('正解の選択肢が複数', () {
      expect(
        codes(validateConfusionMatrixScenarios([
          scenario(options: const [
            ConfusionMatrixOption(optionId: 'a', text: 'A', isCorrect: true),
            ConfusionMatrixOption(optionId: 'b', text: 'B', isCorrect: true),
          ]),
        ])),
        contains('multiple-correct-options'),
      );
    });
  });

  test('試験定義との整合', () {
    expect(
      codes(validateConfusionMatrixScenarios([scenario(examId: 'other')], exam: exam)),
      contains('exam-mismatch'),
    );
    expect(
      codes(validateConfusionMatrixScenarios([scenario(subjectId: 'zzz')], exam: exam)),
      contains('unknown-subject'),
    );
    expect(
      validateConfusionMatrixScenarios([scenario(subjectId: null)], exam: exam),
      isEmpty,
    );
  });

  group('JSON Lines の読み込み', () {
    test('壊れた行は行番号つきの issue になり、他の行は読み込まれる', () {
      final good = jsonEncode(scenario().toJson());
      final parsed = parseConfusionMatrixScenariosJsonl('$good\nこれはJSONではない\n\n[1,2]\n');
      expect(parsed.scenarios, hasLength(1));
      expect(parsed.issues.map((i) => i.qid), ['line:2', 'line:4']);
      expect(parsed.issues.every((i) => i.code == 'parse'), isTrue);
    });
  });
}
