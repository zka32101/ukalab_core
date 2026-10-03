import 'dart:convert';

import '../config/exam_config.dart';
import '../experience/predict_run.dart';
import 'question_validator.dart' show ContentIssue;

class ParsedPredictRunScenarios {
  const ParsedPredictRunScenarios(this.scenarios, this.issues);

  final List<PredictRunScenario> scenarios;

  /// 読み込み（JSON 構文・必須項目）で見つかった問題。
  final List<ContentIssue> issues;
}

/// JSON Lines（1行1場面）を読む。読めない行は [ParsedPredictRunScenarios.issues] に入れて続行する。
ParsedPredictRunScenarios parsePredictRunScenariosJsonl(String text) {
  final scenarios = <PredictRunScenario>[];
  final issues = <ContentIssue>[];
  final lines = const LineSplitter().convert(text);
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('//')) continue;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('1行は JSON オブジェクトが必要です');
      }
      scenarios.add(PredictRunScenario.fromJson(decoded));
    } on FormatException catch (e) {
      issues.add(ContentIssue('line:${i + 1}', 'parse', e.message));
    }
  }
  return ParsedPredictRunScenarios(scenarios, issues);
}

const _requiredParameters = {
  PredictRunKind.bayes: ['priorProbability', 'truePositiveRate', 'falsePositiveRate'],
  PredictRunKind.normalDistribution: ['mean', 'stdDev', 'lowerBound', 'upperBound'],
};

/// 配信前の品質ゲート（決定76）。kind ごとに必要なパラメータが揃っているか、
/// 確率が 0〜1 の範囲か、期待値の確率の合計が 1 かなどを検査する。
///
/// [exam] を渡すと、examId・subjectId が試験定義と整合するかも検査する。
List<ContentIssue> validatePredictRunScenarios(
  List<PredictRunScenario> scenarios, {
  ExamConfig? exam,
}) {
  final issues = <ContentIssue>[];
  void add(PredictRunScenario s, String code, String message) =>
      issues.add(ContentIssue(s.scenarioId, code, message));

  final seenIds = <String>{};
  for (final s in scenarios) {
    if (!seenIds.add(s.scenarioId)) {
      add(s, 'duplicate-id', 'scenarioId が重複しています');
    }

    if (s.title.trim().isEmpty) add(s, 'empty-title', '場面の見出し(title)が空です');
    if (s.question.trim().isEmpty) add(s, 'empty-question', '予測を促す問い(question)が空です');
    if (s.explanation.trim().isEmpty) add(s, 'empty-explanation', '解説(explanation)が空です');
    if (s.sourceRef.trim().isEmpty) add(s, 'no-source', '出典の説明がありません');
    if (s.contentVer.trim().isEmpty) add(s, 'no-content-ver', 'contentVer がありません');

    final required = _requiredParameters[s.kind];
    if (required != null) {
      for (final key in required) {
        if (!s.parameters.containsKey(key)) {
          add(s, 'missing-parameter', '"$key" パラメータが必要です');
        }
      }
    }

    switch (s.kind) {
      case PredictRunKind.bayes:
        for (final key in ['priorProbability', 'truePositiveRate', 'falsePositiveRate']) {
          final v = s.parameters[key];
          if (v != null && (v < 0 || v > 1)) {
            add(s, 'out-of-range', '"$key" は0〜1の確率が必要です: $v');
          }
        }
      case PredictRunKind.normalDistribution:
        final stdDev = s.parameters['stdDev'];
        if (stdDev != null && stdDev <= 0) {
          add(s, 'invalid-std-dev', '"stdDev" は正の数が必要です: $stdDev');
        }
        final lower = s.parameters['lowerBound'];
        final upper = s.parameters['upperBound'];
        if (lower != null && upper != null && lower > upper) {
          add(s, 'invalid-bounds', 'lowerBound が upperBound を超えています');
        }
      case PredictRunKind.expectedValue:
        if (s.outcomes.isEmpty) {
          add(s, 'empty-outcomes', 'expectedValue には outcomes が必要です');
        } else {
          final totalProbability = s.outcomes.fold(0.0, (sum, o) => sum + o.probability);
          if ((totalProbability - 1.0).abs() > 0.001) {
            add(s, 'probability-sum', 'outcomes の probability の合計が1ではありません: $totalProbability');
          }
          for (final o in s.outcomes) {
            if (o.probability < 0 || o.probability > 1) {
              add(s, 'out-of-range', 'outcomes["${o.label}"].probability は0〜1が必要です: ${o.probability}');
            }
          }
        }
    }

    if (exam != null) {
      if (s.examId != exam.examId) {
        add(s, 'exam-mismatch', 'examId(${s.examId}) が試験(${exam.examId})と一致しません');
      }
      final subjectId = s.subjectId;
      if (subjectId != null && exam.subject(subjectId) == null) {
        add(s, 'unknown-subject', '未定義の subjectId: $subjectId');
      }
    }
  }
  return issues;
}
