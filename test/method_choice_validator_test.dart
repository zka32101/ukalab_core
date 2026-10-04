import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

final exam = ExamConfig.fromJson(
  jsonDecode(File('example/sample_exam.json').readAsStringSync())
      as Map<String, dynamic>,
);

MethodChoiceScenario scenario({
  String scenarioId = 's1',
  String examId = 'sample',
  String? subjectId = 'math',
  String title = '顧客の離脱予測',
  String caseDescription = '顧客の年齢・購入履歴から、将来の離脱(はい/いいえ)を予測したい。',
  List<MethodChoiceOption> options = const [
    MethodChoiceOption(optionId: 'classification', text: '分類（教師あり学習）', isCorrect: true),
    MethodChoiceOption(optionId: 'clustering', text: 'クラスタリング（教師なし学習）', isCorrect: false),
  ],
  String explanation = '解説。',
  QuestionSource source = QuestionSource.original,
  String sourceRef = '自作',
  String contentVer = '1',
}) =>
    MethodChoiceScenario(
      scenarioId: scenarioId,
      examId: examId,
      subjectId: subjectId,
      title: title,
      caseDescription: caseDescription,
      options: options,
      explanation: explanation,
      source: source,
      sourceRef: sourceRef,
      contentVer: contentVer,
    );

Set<String> codes(List<ContentIssue> issues) => {for (final i in issues) i.code};

void main() {
  test('正しい場面は指摘なし', () {
    expect(validateMethodChoiceScenarios([scenario()], exam: exam), isEmpty);
  });

  test('scenarioId の重複', () {
    expect(
      codes(validateMethodChoiceScenarios([scenario(), scenario()])),
      contains('duplicate-id'),
    );
  });

  group('必須項目', () {
    test('caseDescription が空', () {
      expect(
        codes(validateMethodChoiceScenarios([scenario(caseDescription: ' ')])),
        contains('empty-case-description'),
      );
    });
    test('explanation が空', () {
      expect(
        codes(validateMethodChoiceScenarios([scenario(explanation: ' ')])),
        contains('empty-explanation'),
      );
    });
    test('sourceRef が空', () {
      expect(
        codes(validateMethodChoiceScenarios([scenario(sourceRef: ' ')])),
        contains('no-source'),
      );
    });
    test('contentVer が空', () {
      expect(
        codes(validateMethodChoiceScenarios([scenario(contentVer: '')])),
        contains('no-content-ver'),
      );
    });
  });

  group('選択肢', () {
    test('選択肢が1つだけでは不足', () {
      expect(
        codes(validateMethodChoiceScenarios([
          scenario(options: const [
            MethodChoiceOption(optionId: 'right', text: '正解', isCorrect: true),
          ]),
        ])),
        contains('too-few-options'),
      );
    });

    test('optionId の重複', () {
      expect(
        codes(validateMethodChoiceScenarios([
          scenario(options: const [
            MethodChoiceOption(optionId: 'a', text: 'A', isCorrect: true),
            MethodChoiceOption(optionId: 'a', text: 'B', isCorrect: false),
          ]),
        ])),
        contains('duplicate-option-id'),
      );
    });

    test('選択肢の文言が空', () {
      expect(
        codes(validateMethodChoiceScenarios([
          scenario(options: const [
            MethodChoiceOption(optionId: 'a', text: ' ', isCorrect: true),
            MethodChoiceOption(optionId: 'b', text: 'B', isCorrect: false),
          ]),
        ])),
        contains('empty-option-text'),
      );
    });

    test('正解の選択肢がない', () {
      expect(
        codes(validateMethodChoiceScenarios([
          scenario(options: const [
            MethodChoiceOption(optionId: 'a', text: 'A', isCorrect: false),
            MethodChoiceOption(optionId: 'b', text: 'B', isCorrect: false),
          ]),
        ])),
        contains('no-correct-option'),
      );
    });

    test('正解の選択肢が複数', () {
      expect(
        codes(validateMethodChoiceScenarios([
          scenario(options: const [
            MethodChoiceOption(optionId: 'a', text: 'A', isCorrect: true),
            MethodChoiceOption(optionId: 'b', text: 'B', isCorrect: true),
          ]),
        ])),
        contains('multiple-correct-options'),
      );
    });
  });

  test('試験定義との整合', () {
    expect(
      codes(validateMethodChoiceScenarios([scenario(examId: 'other')], exam: exam)),
      contains('exam-mismatch'),
    );
    expect(
      codes(validateMethodChoiceScenarios([scenario(subjectId: 'zzz')], exam: exam)),
      contains('unknown-subject'),
    );
    expect(
      validateMethodChoiceScenarios([scenario(subjectId: null)], exam: exam),
      isEmpty,
    );
  });

  group('JSON Lines の読み込み', () {
    test('壊れた行は行番号つきの issue になり、他の行は読み込まれる', () {
      final good = jsonEncode(scenario().toJson());
      final parsed = parseMethodChoiceScenariosJsonl('$good\nこれはJSONではない\n\n[1,2]\n');
      expect(parsed.scenarios, hasLength(1));
      expect(parsed.issues.map((i) => i.qid), ['line:2', 'line:4']);
      expect(parsed.issues.every((i) => i.code == 'parse'), isTrue);
    });
  });
}
