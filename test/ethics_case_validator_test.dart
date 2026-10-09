import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:ukalab_core/ukalab_core.dart';

final exam = ExamConfig.fromJson(
  jsonDecode(File('example/sample_exam.json').readAsStringSync())
      as Map<String, dynamic>,
);

EthicsCaseScenario scenario({
  String scenarioId = 's1',
  String examId = 'sample',
  String? subjectId = 'math',
  String title = '採用AIの偏り',
  String caseDescription = '過去の採用データで学習したAIが、特定の属性の応募者を不当に低く評価していた。',
  List<EthicsCaseOption> options = const [
    EthicsCaseOption(optionId: 'fairness', text: '公平性(バイアス・差別)', isCorrect: true),
    EthicsCaseOption(optionId: 'copyright', text: '著作権(学習データの無断利用)', isCorrect: false),
  ],
  String explanation = '解説。',
  QuestionSource source = QuestionSource.original,
  String sourceRef = '自作',
  String contentVer = '1',
}) =>
    EthicsCaseScenario(
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
    expect(validateEthicsCaseScenarios([scenario()], exam: exam), isEmpty);
  });

  test('scenarioId の重複', () {
    expect(
      codes(validateEthicsCaseScenarios([scenario(), scenario()])),
      contains('duplicate-id'),
    );
  });

  group('必須項目', () {
    test('caseDescription が空', () {
      expect(
        codes(validateEthicsCaseScenarios([scenario(caseDescription: ' ')])),
        contains('empty-case-description'),
      );
    });
    test('explanation が空', () {
      expect(
        codes(validateEthicsCaseScenarios([scenario(explanation: ' ')])),
        contains('empty-explanation'),
      );
    });
    test('sourceRef が空', () {
      expect(
        codes(validateEthicsCaseScenarios([scenario(sourceRef: ' ')])),
        contains('no-source'),
      );
    });
    test('contentVer が空', () {
      expect(
        codes(validateEthicsCaseScenarios([scenario(contentVer: '')])),
        contains('no-content-ver'),
      );
    });
  });

  group('選択肢', () {
    test('選択肢が1つだけでは不足', () {
      expect(
        codes(validateEthicsCaseScenarios([
          scenario(options: const [
            EthicsCaseOption(optionId: 'right', text: '正解', isCorrect: true),
          ]),
        ])),
        contains('too-few-options'),
      );
    });

    test('optionId の重複', () {
      expect(
        codes(validateEthicsCaseScenarios([
          scenario(options: const [
            EthicsCaseOption(optionId: 'a', text: 'A', isCorrect: true),
            EthicsCaseOption(optionId: 'a', text: 'B', isCorrect: false),
          ]),
        ])),
        contains('duplicate-option-id'),
      );
    });

    test('選択肢の文言が空', () {
      expect(
        codes(validateEthicsCaseScenarios([
          scenario(options: const [
            EthicsCaseOption(optionId: 'a', text: ' ', isCorrect: true),
            EthicsCaseOption(optionId: 'b', text: 'B', isCorrect: false),
          ]),
        ])),
        contains('empty-option-text'),
      );
    });

    test('正解の選択肢がない', () {
      expect(
        codes(validateEthicsCaseScenarios([
          scenario(options: const [
            EthicsCaseOption(optionId: 'a', text: 'A', isCorrect: false),
            EthicsCaseOption(optionId: 'b', text: 'B', isCorrect: false),
          ]),
        ])),
        contains('no-correct-option'),
      );
    });

    test('正解の選択肢が複数', () {
      expect(
        codes(validateEthicsCaseScenarios([
          scenario(options: const [
            EthicsCaseOption(optionId: 'a', text: 'A', isCorrect: true),
            EthicsCaseOption(optionId: 'b', text: 'B', isCorrect: true),
          ]),
        ])),
        contains('multiple-correct-options'),
      );
    });
  });

  test('試験定義との整合', () {
    expect(
      codes(validateEthicsCaseScenarios([scenario(examId: 'other')], exam: exam)),
      contains('exam-mismatch'),
    );
    expect(
      codes(validateEthicsCaseScenarios([scenario(subjectId: 'zzz')], exam: exam)),
      contains('unknown-subject'),
    );
    expect(
      validateEthicsCaseScenarios([scenario(subjectId: null)], exam: exam),
      isEmpty,
    );
  });

  group('JSON Lines の読み込み', () {
    test('壊れた行は行番号つきの issue になり、他の行は読み込まれる', () {
      final good = jsonEncode(scenario().toJson());
      final parsed = parseEthicsCaseScenariosJsonl('$good\nこれはJSONではない\n\n[1,2]\n');
      expect(parsed.scenarios, hasLength(1));
      expect(parsed.issues.map((i) => i.qid), ['line:2', 'line:4']);
      expect(parsed.issues.every((i) => i.code == 'parse'), isTrue);
    });
  });
}
