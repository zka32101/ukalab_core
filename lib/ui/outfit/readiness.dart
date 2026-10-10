import '../mascot/mascot_logic.dart';

/// 「準備完了」の判定（暫定）。
///
/// 設計書（推し×資格連動要素 v0.1）では、準備完了は「最短ルートの目標達成」で解放する。
/// 最短ルートプランナーが完成するまでの暫定として、次の**両方**を満たしたら準備完了とする。
///
/// - 習得度が最高段階の境目（既定 0.8）以上
/// - 模擬試験で合格点を1回以上超えた
///
/// 数値は差し替えられる（Remote Config から作る想定）。責める文言は出さない。
class ReadinessRule {
  const ReadinessRule({this.minMastery = 0.8, this.requireMockPass = true});

  final double minMastery;
  final bool requireMockPass;

  static const ReadinessRule standard = ReadinessRule();

  bool isReady({required MasteryInput mastery, required bool mockPassed, MasteryModel model = MasteryModel.standard}) {
    if (requireMockPass && !mockPassed) return false;
    return model.mastery(mastery) >= minMastery;
  }

  /// 準備完了までの進み具合。画面に「あと◯%」を出すための値。
  ReadinessProgress progress({required MasteryInput mastery, required bool mockPassed, MasteryModel model = MasteryModel.standard}) {
    final now = model.mastery(mastery).clamp(0.0, 1.0);
    final masteryPart = minMastery <= 0 ? 1.0 : (now / minMastery).clamp(0.0, 1.0);
    return ReadinessProgress(
      mastery: now,
      target: minMastery,
      masteryFraction: masteryPart,
      mockNeeded: requireMockPass && !mockPassed,
    );
  }
}

/// [ReadinessRule.progress] の結果。
class ReadinessProgress {
  const ReadinessProgress({
    required this.mastery,
    required this.target,
    required this.masteryFraction,
    required this.mockNeeded,
  });

  /// 今の習得度（0〜1）。
  final double mastery;

  /// 準備完了の習得度の目標。
  final double target;

  /// 習得度の目標に対する達成率（0〜1）。
  final double masteryFraction;

  /// 模擬試験の合格がまだ必要か。
  final bool mockNeeded;

  bool get isReady => masteryFraction >= 1.0 && !mockNeeded;

  /// 習得度があと何%で目標か（0〜100の整数、切り上げ）。
  int get masteryPercentLeft => ((target - mastery).clamp(0.0, 1.0) * 100 - 1e-9).ceil();
}
