import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:ukalab_core/ukalab_core.dart';

final exam = ExamConfig.fromJson(
  jsonDecode(File('example/sample_exam.json').readAsStringSync())
      as Map<String, dynamic>,
);

FailureCase failureCase({
  String caseId = 'f1',
  String examId = 'sample',
  String? subjectId = 'math',
  List<LearningCurvePoint> curve = const [
    LearningCurvePoint(epoch: 1, trainLoss: 0.8, valLoss: 0.9),
    LearningCurvePoint(epoch: 10, trainLoss: 0.05, valLoss: 0.6),
  ],
  List<FailureOption> symptomOptions = const [
    FailureOption(optionId: 'overfit', text: '過学習', isCorrect: true),
    FailureOption(optionId: 'underfit', text: '未学習', isCorrect: false),
  ],
  List<FailureOption> treatmentOptions = const [
    FailureOption(optionId: 'regularize', text: '正則化を強める', isCorrect: true),
    FailureOption(optionId: 'more-epoch', text: 'エポック数を増やす', isCorrect: false),
  ],
  String explanation = '解説。',
  QuestionSource source = QuestionSource.original,
  String sourceRef = '自作',
  String contentVer = '1',
}) =>
    FailureCase(
      caseId: caseId,
      examId: examId,
      subjectId: subjectId,
      curve: curve,
      symptomOptions: symptomOptions,
      treatmentOptions: treatmentOptions,
      explanation: explanation,
      source: source,
      sourceRef: sourceRef,
      contentVer: contentVer,
    );

Set<String> codes(List<ContentIssue> issues) => {for (final i in issues) i.code};

void main() {
  test('正しい症例は指摘なし', () {
    expect(validateFailureCases([failureCase()], exam: exam), isEmpty);
  });

  test('caseId の重複', () {
    expect(
      codes(validateFailureCases([failureCase(), failureCase()])),
      contains('duplicate-id'),
    );
  });

  group('必須項目', () {
    test('学習曲線の点数が1点だけでは不足', () {
      expect(
        codes(validateFailureCases([
          failureCase(curve: const [LearningCurvePoint(epoch: 1, trainLoss: 0.5, valLoss: 0.5)]),
        ])),
        contains('too-few-curve-points'),
      );
    });
    test('explanation が空', () {
      expect(
        codes(validateFailureCases([failureCase(explanation: ' ')])),
        contains('empty-explanation'),
      );
    });
    test('sourceRef が空', () {
      expect(
        codes(validateFailureCases([failureCase(sourceRef: ' ')])),
        contains('no-source'),
      );
    });
    test('contentVer が空', () {
      expect(
        codes(validateFailureCases([failureCase(contentVer: '')])),
        contains('no-content-ver'),
      );
    });
  });

  group('症状・処方の選択肢', () {
    test('症状の選択肢が1つだけでは不足', () {
      expect(
        codes(validateFailureCases([
          failureCase(symptomOptions: const [
            FailureOption(optionId: 'right', text: '正解', isCorrect: true),
          ]),
        ])),
        contains('too-few-options'),
      );
    });

    test('処方の optionId の重複', () {
      expect(
        codes(validateFailureCases([
          failureCase(treatmentOptions: const [
            FailureOption(optionId: 'a', text: 'A', isCorrect: true),
            FailureOption(optionId: 'a', text: 'B', isCorrect: false),
          ]),
        ])),
        contains('duplicate-option-id'),
      );
    });

    test('症状の選択肢の文言が空', () {
      expect(
        codes(validateFailureCases([
          failureCase(symptomOptions: const [
            FailureOption(optionId: 'a', text: ' ', isCorrect: true),
            FailureOption(optionId: 'b', text: 'B', isCorrect: false),
          ]),
        ])),
        contains('empty-option-text'),
      );
    });

    test('処方に正解の選択肢がない', () {
      expect(
        codes(validateFailureCases([
          failureCase(treatmentOptions: const [
            FailureOption(optionId: 'a', text: 'A', isCorrect: false),
            FailureOption(optionId: 'b', text: 'B', isCorrect: false),
          ]),
        ])),
        contains('no-correct-option'),
      );
    });

    test('症状に正解の選択肢が複数', () {
      expect(
        codes(validateFailureCases([
          failureCase(symptomOptions: const [
            FailureOption(optionId: 'a', text: 'A', isCorrect: true),
            FailureOption(optionId: 'b', text: 'B', isCorrect: true),
          ]),
        ])),
        contains('multiple-correct-options'),
      );
    });
  });

  test('試験定義との整合', () {
    expect(
      codes(validateFailureCases([failureCase(examId: 'other')], exam: exam)),
      contains('exam-mismatch'),
    );
    expect(
      codes(validateFailureCases([failureCase(subjectId: 'zzz')], exam: exam)),
      contains('unknown-subject'),
    );
    expect(validateFailureCases([failureCase(subjectId: null)], exam: exam), isEmpty);
  });

  group('JSON Lines の読み込み', () {
    test('壊れた行は行番号つきの issue になり、他の行は読み込まれる', () {
      final good = jsonEncode(failureCase().toJson());
      final parsed = parseFailureCasesJsonl('$good\nこれはJSONではない\n\n[1,2]\n');
      expect(parsed.cases, hasLength(1));
      expect(parsed.issues.map((i) => i.qid), ['line:2', 'line:4']);
      expect(parsed.issues.every((i) => i.code == 'parse'), isTrue);
    });
  });
}
