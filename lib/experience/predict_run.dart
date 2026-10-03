import 'dart:math' as math;

import '../question/question.dart' show QuestionSource;
import '../src/json_util.dart';

/// 予測→実行（型②、決定76）で計算できる式の種類。
enum PredictRunKind {
  /// ベイズ更新（例: 検査の陽性率から本当に病気である確率）。
  bayes,

  /// 期待値（Σ 結果の値 × 確率）。
  expectedValue,

  /// 正規分布で、ある区間に入る確率。
  normalDistribution,
}

/// 期待値の計算に使う結果1つ（値と確率）。
class PredictOutcome {
  const PredictOutcome({
    required this.label,
    required this.value,
    required this.probability,
  });

  final String label;
  final double value;
  final double probability;

  factory PredictOutcome.fromJson(Map<String, dynamic> j, String where) {
    return PredictOutcome(
      label: reqString(j, 'label', where),
      value: reqNum(j, 'value', where),
      probability: reqNum(j, 'probability', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
        'probability': probability,
      };
}

/// 予測→実行の1場面（決定76「先に答えを予測→計算・シミュレーション結果を
/// 表示→ズレを解説」）。[question] で予測を促し、[compute] で計算した正解との
/// ズレを [explanation] で説明する。
class PredictRunScenario {
  const PredictRunScenario({
    required this.scenarioId,
    required this.examId,
    required this.title,
    required this.question,
    required this.kind,
    required this.parameters,
    required this.explanation,
    required this.source,
    required this.sourceRef,
    required this.contentVer,
    this.subjectId,
    this.outcomes = const [],
    this.disabled = false,
  });

  final String scenarioId;
  final String examId;

  /// null なら分野を問わない。
  final String? subjectId;

  /// 場面の見出し（例: "確率の手ざわり"）。
  final String title;

  /// 予測を促す問い（例: "陽性なら本当に病気の確率は?"）。
  final String question;
  final PredictRunKind kind;

  /// kind ごとに使うパラメータ。
  /// - bayes: priorProbability・truePositiveRate・falsePositiveRate
  /// - normalDistribution: mean・stdDev・lowerBound・upperBound
  final Map<String, double> parameters;

  /// expectedValue でのみ使う、値と確率の一覧。
  final List<PredictOutcome> outcomes;

  /// 予測とのズレの解説。
  final String explanation;

  final QuestionSource source;
  final String sourceRef;
  final String contentVer;
  final bool disabled;

  /// 正解の計算結果。bayes・normalDistribution は 0.0〜1.0 の確率、
  /// expectedValue は期待値そのもの。
  double compute() {
    switch (kind) {
      case PredictRunKind.bayes:
        final prior = parameters['priorProbability']!;
        final truePositiveRate = parameters['truePositiveRate']!;
        final falsePositiveRate = parameters['falsePositiveRate']!;
        final numerator = truePositiveRate * prior;
        final denominator = numerator + falsePositiveRate * (1 - prior);
        return denominator == 0 ? 0 : numerator / denominator;
      case PredictRunKind.expectedValue:
        var sum = 0.0;
        for (final o in outcomes) {
          sum += o.value * o.probability;
        }
        return sum;
      case PredictRunKind.normalDistribution:
        final mean = parameters['mean']!;
        final stdDev = parameters['stdDev']!;
        final lower = parameters['lowerBound']!;
        final upper = parameters['upperBound']!;
        return _normalCdf(upper, mean, stdDev) - _normalCdf(lower, mean, stdDev);
    }
  }

  factory PredictRunScenario.fromJson(Map<String, dynamic> j) {
    final scenarioId = reqString(j, 'scenarioId', 'predictRunScenario');
    final where = 'predictRunScenario[$scenarioId]';

    final sourceName = reqString(j, 'source', where);
    final source = QuestionSource.values.where((s) => s.name == sourceName);
    if (source.isEmpty) {
      fail(where, '"source" は original / statute / licensed のいずれか');
    }

    final kindName = reqString(j, 'kind', where);
    final kind = PredictRunKind.values.where((k) => k.name == kindName);
    if (kind.isEmpty) {
      fail(where, '"kind" は bayes / expectedValue / normalDistribution のいずれか');
    }

    final rawParameters = j['parameters'];
    if (rawParameters is! Map) fail(where, '"parameters" はオブジェクトが必要です');
    final parameters = <String, double>{};
    rawParameters.forEach((k, v) {
      if (v is! num) fail(where, '"parameters.$k" は数値が必要です');
      parameters[k as String] = v.toDouble();
    });

    final rawOutcomes = j['outcomes'];
    final outcomes = rawOutcomes == null
        ? const <PredictOutcome>[]
        : reqObjectList(j, 'outcomes', where)
            .map((o) => PredictOutcome.fromJson(o, where))
            .toList();

    return PredictRunScenario(
      scenarioId: scenarioId,
      examId: reqString(j, 'examId', where),
      subjectId: optString(j, 'subjectId', where),
      title: reqString(j, 'title', where),
      question: reqString(j, 'question', where),
      kind: kind.first,
      parameters: parameters,
      outcomes: outcomes,
      explanation: reqString(j, 'explanation', where),
      source: source.first,
      sourceRef: reqString(j, 'sourceRef', where),
      contentVer: reqString(j, 'contentVer', where),
      disabled: j['disabled'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'scenarioId': scenarioId,
        'examId': examId,
        if (subjectId != null) 'subjectId': subjectId,
        'title': title,
        'question': question,
        'kind': kind.name,
        'parameters': parameters,
        if (outcomes.isNotEmpty) 'outcomes': outcomes.map((o) => o.toJson()).toList(),
        'explanation': explanation,
        'source': source.name,
        'sourceRef': sourceRef,
        'contentVer': contentVer,
        if (disabled) 'disabled': true,
      };
}

double _normalCdf(double x, double mean, double stdDev) {
  final z = (x - mean) / (stdDev * math.sqrt(2));
  return 0.5 * (1 + _erf(z));
}

/// Abramowitz and Stegun の近似式（最大誤差 1.5e-7）。
double _erf(double x) {
  final sign = x < 0 ? -1 : 1;
  final ax = x.abs();
  const a1 = 0.254829592;
  const a2 = -0.284496736;
  const a3 = 1.421413741;
  const a4 = -1.453152027;
  const a5 = 1.061405429;
  const p = 0.3275911;
  final t = 1.0 / (1.0 + p * ax);
  final y =
      1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-ax * ax);
  return sign * y;
}
