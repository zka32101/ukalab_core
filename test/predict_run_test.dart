import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

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

void main() {
  group('compute', () {
    test('bayes: ベイズ更新で事後確率を計算する', () {
      final s = scenario();
      // P(病気|陽性) = 0.9*0.01 / (0.9*0.01 + 0.05*0.99) = 0.009/0.0585 ≈ 0.1538
      expect(s.compute(), closeTo(0.1538, 0.001));
    });

    test('expectedValue: Σ 値×確率', () {
      final s = scenario(
        kind: PredictRunKind.expectedValue,
        parameters: const {},
        outcomes: const [
          PredictOutcome(label: '当たり', value: 100, probability: 0.1),
          PredictOutcome(label: 'はずれ', value: 0, probability: 0.9),
        ],
      );
      expect(s.compute(), closeTo(10.0, 0.0001));
    });

    test('normalDistribution: 区間に入る確率(68-95-99.7則、平均±1標準偏差)', () {
      final s = scenario(
        kind: PredictRunKind.normalDistribution,
        parameters: const {
          'mean': 0,
          'stdDev': 1,
          'lowerBound': -1,
          'upperBound': 1,
        },
      );
      expect(s.compute(), closeTo(0.6827, 0.001));
    });
  });

  test('toJson → fromJson で往復できる(bayes)', () {
    final original = scenario();
    final again = PredictRunScenario.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    expect(again.toJson(), original.toJson());
  });

  test('toJson → fromJson で往復できる(expectedValue、outcomesあり)', () {
    final original = scenario(
      kind: PredictRunKind.expectedValue,
      parameters: const {},
      outcomes: const [
        PredictOutcome(label: '当たり', value: 100, probability: 0.1),
        PredictOutcome(label: 'はずれ', value: 0, probability: 0.9),
      ],
    );
    final again = PredictRunScenario.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    expect(again.toJson(), original.toJson());
  });

  group('JSON Lines の読み込み', () {
    test('壊れた行は行番号つきの issue になり、他の行は読み込まれる', () {
      final good = jsonEncode(scenario().toJson());
      final parsed = parsePredictRunScenariosJsonl('$good\nこれはJSONではない\n\n[1,2]\n');
      expect(parsed.scenarios, hasLength(1));
      expect(parsed.issues.map((i) => i.qid), ['line:2', 'line:4']);
      expect(parsed.issues.every((i) => i.code == 'parse'), isTrue);
    });

    test('kind が不正だと読み込みエラー', () {
      final j = scenario().toJson();
      j['kind'] = 'unknown';
      final parsed = parsePredictRunScenariosJsonl(jsonEncode(j));
      expect(parsed.scenarios, isEmpty);
      expect(parsed.issues.single.message, contains('kind'));
    });
  });
}
