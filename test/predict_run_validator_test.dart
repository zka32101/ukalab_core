import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:ukalab_core/ukalab_core.dart';

final exam = ExamConfig.fromJson(
  jsonDecode(File('example/sample_exam.json').readAsStringSync())
      as Map<String, dynamic>,
);

PredictRunScenario scenario({
  String scenarioId = 'p1',
  String examId = 'sample',
  String? subjectId = 'math',
  String title = '確率の手ざわり',
  String question = '陽性なら本当に病気の確率は?',
  PredictRunKind kind = PredictRunKind.bayes,
  Map<String, double> parameters = const {
    'priorProbability': 0.01,
    'truePositiveRate': 0.9,
    'falsePositiveRate': 0.05,
  },
  List<PredictOutcome> outcomes = const [],
  String explanation = '事前確率が低いと、検査で陽性でも病気である確率は意外と低い。',
  QuestionSource source = QuestionSource.original,
  String sourceRef = '自作',
  String contentVer = '1',
}) =>
    PredictRunScenario(
      scenarioId: scenarioId,
      examId: examId,
      subjectId: subjectId,
      title: title,
      question: question,
      kind: kind,
      parameters: parameters,
      outcomes: outcomes,
      explanation: explanation,
      source: source,
      sourceRef: sourceRef,
      contentVer: contentVer,
    );

Set<String> codes(List<ContentIssue> issues) => {for (final i in issues) i.code};

void main() {
  test('正しい場面(bayes)は指摘なし', () {
    expect(validatePredictRunScenarios([scenario()], exam: exam), isEmpty);
  });

  test('正しい場面(normalDistribution)は指摘なし', () {
    expect(
      validatePredictRunScenarios([
        scenario(
          kind: PredictRunKind.normalDistribution,
          parameters: const {'mean': 0, 'stdDev': 1, 'lowerBound': -1, 'upperBound': 1},
        ),
      ], exam: exam),
      isEmpty,
    );
  });

  test('正しい場面(expectedValue)は指摘なし', () {
    expect(
      validatePredictRunScenarios([
        scenario(
          kind: PredictRunKind.expectedValue,
          parameters: const {},
          outcomes: const [
            PredictOutcome(label: '当たり', value: 100, probability: 0.1),
            PredictOutcome(label: 'はずれ', value: 0, probability: 0.9),
          ],
        ),
      ], exam: exam),
      isEmpty,
    );
  });

  test('scenarioId の重複', () {
    expect(
      codes(validatePredictRunScenarios([scenario(), scenario()])),
      contains('duplicate-id'),
    );
  });

  group('必須項目', () {
    test('title が空', () {
      expect(
        codes(validatePredictRunScenarios([scenario(title: ' ')])),
        contains('empty-title'),
      );
    });
    test('question が空', () {
      expect(
        codes(validatePredictRunScenarios([scenario(question: ' ')])),
        contains('empty-question'),
      );
    });
    test('explanation が空', () {
      expect(
        codes(validatePredictRunScenarios([scenario(explanation: ' ')])),
        contains('empty-explanation'),
      );
    });
    test('sourceRef が空', () {
      expect(
        codes(validatePredictRunScenarios([scenario(sourceRef: ' ')])),
        contains('no-source'),
      );
    });
    test('contentVer が空', () {
      expect(
        codes(validatePredictRunScenarios([scenario(contentVer: '')])),
        contains('no-content-ver'),
      );
    });
  });

  group('bayes', () {
    test('必須パラメータが不足', () {
      expect(
        codes(validatePredictRunScenarios([
          scenario(parameters: const {'priorProbability': 0.01}),
        ])),
        contains('missing-parameter'),
      );
    });
    test('確率が範囲外', () {
      expect(
        codes(validatePredictRunScenarios([
          scenario(parameters: const {
            'priorProbability': 1.5,
            'truePositiveRate': 0.9,
            'falsePositiveRate': 0.05,
          }),
        ])),
        contains('out-of-range'),
      );
    });
  });

  group('normalDistribution', () {
    test('stdDev が0以下', () {
      expect(
        codes(validatePredictRunScenarios([
          scenario(
            kind: PredictRunKind.normalDistribution,
            parameters: const {'mean': 0, 'stdDev': 0, 'lowerBound': -1, 'upperBound': 1},
          ),
        ])),
        contains('invalid-std-dev'),
      );
    });
    test('lowerBound が upperBound を超える', () {
      expect(
        codes(validatePredictRunScenarios([
          scenario(
            kind: PredictRunKind.normalDistribution,
            parameters: const {'mean': 0, 'stdDev': 1, 'lowerBound': 1, 'upperBound': -1},
          ),
        ])),
        contains('invalid-bounds'),
      );
    });
  });

  group('expectedValue', () {
    test('outcomes が空', () {
      expect(
        codes(validatePredictRunScenarios([
          scenario(kind: PredictRunKind.expectedValue, parameters: const {}),
        ])),
        contains('empty-outcomes'),
      );
    });
    test('probability の合計が1でない', () {
      expect(
        codes(validatePredictRunScenarios([
          scenario(
            kind: PredictRunKind.expectedValue,
            parameters: const {},
            outcomes: const [
              PredictOutcome(label: 'A', value: 1, probability: 0.3),
              PredictOutcome(label: 'B', value: 2, probability: 0.3),
            ],
          ),
        ])),
        contains('probability-sum'),
      );
    });
  });

  test('試験定義との整合', () {
    expect(
      codes(validatePredictRunScenarios([scenario(examId: 'other')], exam: exam)),
      contains('exam-mismatch'),
    );
    expect(
      codes(validatePredictRunScenarios([scenario(subjectId: 'zzz')], exam: exam)),
      contains('unknown-subject'),
    );
    expect(validatePredictRunScenarios([scenario(subjectId: null)], exam: exam), isEmpty);
  });

  group('JSON Lines の読み込み', () {
    test('壊れた行は行番号つきの issue になり、他の行は読み込まれる', () {
      final good = jsonEncode(scenario().toJson());
      final parsed = parsePredictRunScenariosJsonl('$good\nこれはJSONではない\n\n[1,2]\n');
      expect(parsed.scenarios, hasLength(1));
      expect(parsed.issues.map((i) => i.qid), ['line:2', 'line:4']);
      expect(parsed.issues.every((i) => i.code == 'parse'), isTrue);
    });
  });
}
