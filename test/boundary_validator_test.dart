import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:ukalab_core/ukalab_core.dart';

final exam = ExamConfig.fromJson(
  jsonDecode(File('example/sample_exam.json').readAsStringSync())
      as Map<String, dynamic>,
);

const _conditions = [
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
];

BoundaryScenario scenario({
  String scenarioId = 's1',
  String examId = 'sample',
  String? subjectId = 'math',
  String title = '学習用データの収集',
  List<BoundaryCondition> conditions = _conditions,
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

Set<String> codes(List<ContentIssue> issues) => {for (final i in issues) i.code};

void main() {
  test('正しい場面は指摘なし', () {
    expect(validateBoundaryScenarios([scenario()], exam: exam), isEmpty);
  });

  test('scenarioId の重複', () {
    expect(
      codes(validateBoundaryScenarios([scenario(), scenario()])),
      contains('duplicate-id'),
    );
  });

  group('必須項目', () {
    test('title が空', () {
      expect(
        codes(validateBoundaryScenarios([scenario(title: ' ')])),
        contains('empty-title'),
      );
    });
    test('sourceRef が空', () {
      expect(
        codes(validateBoundaryScenarios([scenario(sourceRef: ' ')])),
        contains('no-source'),
      );
    });
    test('statute は lawVersion が必要', () {
      expect(
        codes(validateBoundaryScenarios([scenario(lawVersion: null)])),
        contains('no-law-version'),
      );
    });
    test('contentVer が空', () {
      expect(
        codes(validateBoundaryScenarios([scenario(contentVer: '')])),
        contains('no-content-ver'),
      );
    });
  });

  group('条件・ルール', () {
    test('条件が1つだけでは不足', () {
      expect(
        codes(validateBoundaryScenarios([
          scenario(conditions: const [
            BoundaryCondition(
              conditionId: 'a',
              label: 'A',
              trueLabel: 'あり',
              falseLabel: 'なし',
            ),
          ], rules: const [
            BoundaryRule(
              conditionValues: {'a': true},
              conclusion: '可（目安）',
              lawReference: 'x',
            ),
            BoundaryRule(
              conditionValues: {'a': false},
              conclusion: '不可（目安）',
              lawReference: 'x',
            ),
          ]),
        ])),
        contains('too-few-conditions'),
      );
    });

    test('rules が空', () {
      expect(
        codes(validateBoundaryScenarios([scenario(rules: const [])])),
        contains('empty-rules'),
      );
    });

    test('未定義の条件を参照するルール', () {
      expect(
        codes(validateBoundaryScenarios([
          scenario(rules: const [
            BoundaryRule(
              conditionValues: {'zzz': true},
              conclusion: '可（目安）',
              lawReference: 'x',
            ),
          ]),
        ])),
        contains('unknown-condition'),
      );
    });

    test('結論・根拠が空のルール', () {
      expect(
        codes(validateBoundaryScenarios([
          scenario(rules: const [
            BoundaryRule(
              conditionValues: {'enjoymentPurpose': true},
              conclusion: ' ',
              lawReference: ' ',
            ),
            BoundaryRule(
              conditionValues: {'enjoymentPurpose': false},
              conclusion: '適法（目安）',
              lawReference: '著作権法30条の4',
            ),
          ]),
        ])),
        containsAll(['empty-conclusion', 'empty-law-reference']),
      );
    });

    test('条件の組み合わせに結論がないと網羅性エラー', () {
      expect(
        codes(validateBoundaryScenarios([
          scenario(rules: const [
            BoundaryRule(
              conditionValues: {'forProfit': true, 'enjoymentPurpose': true},
              conclusion: '対象外（目安）',
              lawReference: '著作権法30条の4',
            ),
          ]),
        ])),
        contains('unreachable-combination'),
      );
    });

    test('全ての組み合わせを網羅していれば指摘なし', () {
      expect(validateBoundaryScenarios([scenario()]), isEmpty);
    });
  });

  test('試験定義との整合', () {
    expect(
      codes(validateBoundaryScenarios([scenario(examId: 'other')], exam: exam)),
      contains('exam-mismatch'),
    );
    expect(
      codes(validateBoundaryScenarios([scenario(subjectId: 'zzz')], exam: exam)),
      contains('unknown-subject'),
    );
    expect(validateBoundaryScenarios([scenario(subjectId: null)], exam: exam), isEmpty);
  });

  group('JSON Lines の読み込み', () {
    test('壊れた行は行番号つきの issue になり、他の行は読み込まれる', () {
      final good = jsonEncode(scenario().toJson());
      final parsed = parseBoundaryScenariosJsonl('$good\nこれはJSONではない\n\n[1,2]\n');
      expect(parsed.scenarios, hasLength(1));
      expect(parsed.issues.map((i) => i.qid), ['line:2', 'line:4']);
      expect(parsed.issues.every((i) => i.code == 'parse'), isTrue);
    });

    test('toJson → fromJson で往復できる', () {
      final original = scenario();
      final again = BoundaryScenario.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(again.toJson(), original.toJson());
    });
  });
}
