import 'dart:math' as math;

import 'mascot_models.dart';

/// 習得度の入力。どちらも 0.0〜1.0。
class MasteryInput {
  const MasteryInput({required this.coverage, required this.accuracy});

  /// 出題範囲の網羅率（解いた問題数 ÷ 全問題数）。
  final double coverage;

  /// 正答率。
  final double accuracy;

  /// 件数から作る。網羅率＝解いた問題の種類÷全問題数、正答率＝正解数÷回答数。
  /// 全問題数か回答数が0以下なら、どちらも0。
  factory MasteryInput.fromCounts({
    required int distinctAnswered,
    required int totalQuestions,
    required int correct,
    required int answered,
  }) {
    if (totalQuestions <= 0 || answered <= 0) {
      return const MasteryInput(coverage: 0, accuracy: 0);
    }
    return MasteryInput(
      coverage: (distinctAnswered / totalQuestions).clamp(0.0, 1.0),
      accuracy: (correct / answered).clamp(0.0, 1.0),
    );
  }

  /// 回答ログから作る。[questionIds] の範囲外の回答は数えない。
  factory MasteryInput.fromLogs({
    required Set<String> questionIds,
    required Iterable<({String questionId, bool isCorrect})> logs,
  }) {
    final inScope = logs.where((l) => questionIds.contains(l.questionId)).toList();
    return MasteryInput.fromCounts(
      distinctAnswered: inScope.map((l) => l.questionId).toSet().length,
      totalQuestions: questionIds.length,
      correct: inScope.where((l) => l.isCorrect).length,
      answered: inScope.length,
    );
  }
}

/// 習得度と成長段階の計算。端末内で行う。
///
/// 習得度 = 網羅率^a × 正答率^b（既定 a=b=1 ＝ 網羅率×正答率）。
/// 計算式の細部は未決（マスコット仕様）なので、係数と段階の境目は差し替えられる
/// （Remote Config から作る想定）。
class MasteryModel {
  const MasteryModel({
    this.coverageExponent = 1.0,
    this.accuracyExponent = 1.0,
    this.stageThresholds = const [0.2, 0.4, 0.6, 0.8],
  });

  final double coverageExponent;
  final double accuracyExponent;

  /// Lv2・Lv3・Lv4・Lv5 に上がる習得度の境目（昇順）。
  final List<double> stageThresholds;

  static const MasteryModel standard = MasteryModel();

  double mastery(MasteryInput i) {
    final c = _clamp01(i.coverage);
    final a = _clamp01(i.accuracy);
    return _clamp01(math.pow(c, coverageExponent).toDouble() * math.pow(a, accuracyExponent).toDouble());
  }

  MascotStage stageFor(double mastery) {
    var level = 0;
    for (final t in stageThresholds) {
      if (mastery >= t) level++;
    }
    return MascotStage.values[math.min(level, MascotStage.values.length - 1)];
  }

  MascotStage stageOf(MasteryInput i) => stageFor(mastery(i));

  /// 次の段階まであと何問解けばよいか（正答率が今のままと仮定）。
  ///
  /// すでに最高段階、または今の正答率では次の段階に届かないときは null。
  int? questionsToNextStage(MasteryInput i, {required int totalQuestions}) {
    final stage = stageOf(i);
    if (stage == MascotStage.lv5 || totalQuestions <= 0) return null;
    final target = stageThresholds[math.min(stage.index, stageThresholds.length - 1)];
    final a = _clamp01(i.accuracy);
    final accFactor = math.pow(a, accuracyExponent).toDouble();
    if (accFactor <= 0) return null;
    // 網羅率^cExp × accFactor >= target → 網羅率 >= (target / accFactor)^(1/cExp)
    final needRatio = target / accFactor;
    if (needRatio > 1) return null;
    final needCoverage = math.pow(needRatio, 1 / coverageExponent).toDouble();
    final remaining = ((needCoverage - _clamp01(i.coverage)) * totalQuestions).ceil();
    return remaining < 1 ? 1 : remaining;
  }

  static double _clamp01(double v) => v.isNaN ? 0 : v.clamp(0.0, 1.0);
}

/// 今日の状態。表情とセリフを決める。
class MascotDayState {
  const MascotDayState({
    this.studiedToday = false,
    this.streakDays = 0,
    this.daysSinceLastStudy,
    this.examDate,
  });

  final bool studiedToday;
  final int streakDays;

  /// 最後に学習した日からの日数。まだ学習がなければ null。
  final int? daysSinceLastStudy;

  /// 試験日（設定した人だけ）。
  final DateTime? examDate;

  /// 3日以上空いていれば「おかえり」。
  bool get isWelcomeBack => !studiedToday && (daysSinceLastStudy ?? 0) >= 3;

  /// 今日学習したか、3日以上の連続なら、よろこびの表情。責める表情は使わない。
  MascotExpression get expression =>
      (studiedToday || streakDays >= 3) ? MascotExpression.joy : MascotExpression.normal;

  /// 試験日までの日数による装い。過去の日付・未設定は none。
  ExamPhase examPhase(DateTime now) {
    final d = examDate;
    if (d == null) return ExamPhase.none;
    final days = DateTime(d.year, d.month, d.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days < 0) return ExamPhase.none;
    if (days == 0) return ExamPhase.today;
    if (days == 1) return ExamPhase.eve;
    if (days <= 7) return ExamPhase.close;
    if (days <= 30) return ExamPhase.approaching;
    return ExamPhase.none;
  }
}
