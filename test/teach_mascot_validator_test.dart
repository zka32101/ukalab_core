import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

final exam = ExamConfig.fromJson(
  jsonDecode(File('example/sample_exam.json').readAsStringSync())
      as Map<String, dynamic>,
);

MisconceptionScenario scenario({
  String scenarioId = 'm1',
  String examId = 'sample',
  String? subjectId = 'math',
  String title = '学習用データの収集',
  String statementTemplate = 'この学習データの収集は、{blank}だから問題ない',
  List<MisconceptionOption> options = const [
    MisconceptionOption(optionId: 'wrong', text: '非営利', isCorrect: false),
    MisconceptionOption(optionId: 'right', text: '享受目的を含まない', isCorrect: true),
  ],
  String explanation = '解説。',
  QuestionSource source = QuestionSource.original,
  String sourceRef = '自作',
  String contentVer = '1',
}) =>
    MisconceptionScenario(
      scenarioId: scenarioId,
      examId: examId,
      subjectId: subjectId,
      title: title,
      statementTemplate: statementTemplate,
      options: options,
      explanation: explanation,
      source: source,
      sourceRef: sourceRef,
      contentVer: contentVer,
    );

Set<String> codes(List<ContentIssue> issues) => {for (final i in issues) i.code};

void main() {
  test('正しい場面は指摘なし', () {
    expect(validateMisconceptionScenarios([scenario()], exam: exam), isEmpty);
  });

  test('scenarioId の重複', () {
    expect(
      codes(validateMisconceptionScenarios([scenario(), scenario()])),
      contains('duplicate-id'),
    );
  });

  group('必須項目', () {
    test('title が空', () {
      expect(
        codes(validateMisconceptionScenarios([scenario(title: ' ')])),
        contains('empty-title'),
      );
    });
    test('explanation が空', () {
      expect(
        codes(validateMisconceptionScenarios([scenario(explanation: ' ')])),
        contains('empty-explanation'),
      );
    });
    test('sourceRef が空', () {
      expect(
        codes(validateMisconceptionScenarios([scenario(sourceRef: ' ')])),
        contains('no-source'),
      );
    });
    test('contentVer が空', () {
      expect(
        codes(validateMisconceptionScenarios([scenario(contentVer: '')])),
        contains('no-content-ver'),
      );
    });
  });

  group('statementTemplate・選択肢', () {
    test('{blank} がない', () {
      expect(
        codes(validateMisconceptionScenarios([
          scenario(statementTemplate: '空欄を含まない文'),
        ])),
        contains('missing-blank'),
      );
    });

    test('選択肢が1つだけでは不足', () {
      expect(
        codes(validateMisconceptionScenarios([
          scenario(options: const [
            MisconceptionOption(optionId: 'right', text: '正解', isCorrect: true),
          ]),
        ])),
        contains('too-few-options'),
      );
    });

    test('optionId の重複', () {
      expect(
        codes(validateMisconceptionScenarios([
          scenario(options: const [
            MisconceptionOption(optionId: 'a', text: 'A', isCorrect: true),
            MisconceptionOption(optionId: 'a', text: 'B', isCorrect: false),
          ]),
        ])),
        contains('duplicate-option-id'),
      );
    });

    test('選択肢の文言が空', () {
      expect(
        codes(validateMisconceptionScenarios([
          scenario(options: const [
            MisconceptionOption(optionId: 'a', text: ' ', isCorrect: true),
            MisconceptionOption(optionId: 'b', text: 'B', isCorrect: false),
          ]),
        ])),
        contains('empty-option-text'),
      );
    });

    test('正解の選択肢がない', () {
      expect(
        codes(validateMisconceptionScenarios([
          scenario(options: const [
            MisconceptionOption(optionId: 'a', text: 'A', isCorrect: false),
            MisconceptionOption(optionId: 'b', text: 'B', isCorrect: false),
          ]),
        ])),
        contains('no-correct-option'),
      );
    });

    test('正解の選択肢が複数', () {
      expect(
        codes(validateMisconceptionScenarios([
          scenario(options: const [
            MisconceptionOption(optionId: 'a', text: 'A', isCorrect: true),
            MisconceptionOption(optionId: 'b', text: 'B', isCorrect: true),
          ]),
        ])),
        contains('multiple-correct-options'),
      );
    });
  });

  test('試験定義との整合', () {
    expect(
      codes(validateMisconceptionScenarios([scenario(examId: 'other')], exam: exam)),
      contains('exam-mismatch'),
    );
    expect(
      codes(validateMisconceptionScenarios([scenario(subjectId: 'zzz')], exam: exam)),
      contains('unknown-subject'),
    );
    expect(validateMisconceptionScenarios([scenario(subjectId: null)], exam: exam), isEmpty);
  });

  group('JSON Lines の読み込み', () {
    test('壊れた行は行番号つきの issue になり、他の行は読み込まれる', () {
      final good = jsonEncode(scenario().toJson());
      final parsed = parseMisconceptionScenariosJsonl('$good\nこれはJSONではない\n\n[1,2]\n');
      expect(parsed.scenarios, hasLength(1));
      expect(parsed.issues.map((i) => i.qid), ['line:2', 'line:4']);
      expect(parsed.issues.every((i) => i.code == 'parse'), isTrue);
    });
  });
}
