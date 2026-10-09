import 'dart:convert';

import 'package:test/test.dart';
import 'package:ukalab_core/ukalab_core.dart';

BoundaryScenario scenario({
  String scenarioId = 's1',
  String examId = 'sample',
  String? subjectId = 'law',
  String title = '学習用データの収集',
  List<BoundaryCondition> conditions = const [
    BoundaryCondition(
      conditionId: 'forProfit',
      label: '営利目的か',
      trueLabel: '営利',
      falseLabel: '非営利',
    ),
    BoundaryCondition(
      conditionId: 'enjoymentPurpose',
      label: '享受目的があるか',
      trueLabel: 'あり',
      falseLabel: 'なし',
    ),
  ],
  List<BoundaryRule> rules = const [
    BoundaryRule(
      conditionValues: {'enjoymentPurpose': true},
      conclusion: '対象外（目安）',
      lawReference: '著作権法30条の4',
    ),
    BoundaryRule(
      conditionValues: {'enjoymentPurpose': false},
      conclusion: '適法（目安）',
      lawReference: '著作権法30条の4',
    ),
  ],
  QuestionSource source = QuestionSource.statute,
  String sourceRef = '著作権法30条の4',
  String? lawVersion = '2026-04',
  String contentVer = '1',
}) =>
    BoundaryScenario(
      scenarioId: scenarioId,
      examId: examId,
      subjectId: subjectId,
      title: title,
      conditions: conditions,
      rules: rules,
      source: source,
      sourceRef: sourceRef,
      lawVersion: lawVersion,
      contentVer: contentVer,
    );

void main() {
  group('evaluate', () {
    test('条件が一致する最初のルールを返す', () {
      final s = scenario();
      expect(
        s.evaluate({'forProfit': true, 'enjoymentPurpose': true})!.conclusion,
        '対象外（目安）',
      );
      expect(
        s.evaluate({'forProfit': false, 'enjoymentPurpose': false})!.conclusion,
        '適法（目安）',
      );
    });

    test('マッチするルールがなければ null', () {
      final s = scenario(rules: const [
        BoundaryRule(
          conditionValues: {'enjoymentPurpose': true},
          conclusion: '対象外（目安）',
          lawReference: '著作権法30条の4',
        ),
      ]);
      expect(s.evaluate({'forProfit': true, 'enjoymentPurpose': false}), isNull);
    });
  });

  test('toJson → fromJson で往復できる', () {
    final original = scenario();
    final again = BoundaryScenario.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    expect(again.toJson(), original.toJson());
  });
}
