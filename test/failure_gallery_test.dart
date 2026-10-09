import 'dart:convert';

import 'package:test/test.dart';
import 'package:ukalab_core/ukalab_core.dart';

FailureCase failureCase({
  String caseId = 'f1',
  String examId = 'sample',
  String? subjectId = 'math',
  List<LearningCurvePoint> curve = const [
    LearningCurvePoint(epoch: 1, trainLoss: 0.8, valLoss: 0.9),
    LearningCurvePoint(epoch: 5, trainLoss: 0.2, valLoss: 0.1),
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
  String explanation = '訓練誤差は下がり続けるが検証誤差が途中から上がる、過学習の典型例。',
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

void main() {
  test('correctSymptom・correctTreatment は isCorrect:true の選択肢', () {
    final c = failureCase();
    expect(c.correctSymptom.optionId, 'overfit');
    expect(c.correctTreatment.optionId, 'regularize');
  });

  test('toJson → fromJson で往復できる', () {
    final original = failureCase();
    final again = FailureCase.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    expect(again.toJson(), original.toJson());
  });
}
