/// 145問ペース走（型④の直前版、決定76）の設定。
///
/// 本番は「100分で約145問」。最小実装では、これを体感する短縮版
/// （20問×14分）として使う想定だが、問題数・時間は呼び出し側で決める。
class PaceRunConfig {
  const PaceRunConfig({
    required this.questionCount,
    required this.timeLimitSec,
  });

  final int questionCount;
  final int timeLimitSec;
}

/// ある時点でのペースの状態。
class PaceStatus {
  const PaceStatus({
    required this.expectedAnswered,
    required this.aheadBy,
    required this.projectedTotal,
    required this.onTrack,
  });

  /// この時点で理想的に解き終わっているべき問題数。
  final int expectedAnswered;

  /// 実際の解答数 − [expectedAnswered]。正ならペースが速い、負なら遅れている。
  final int aheadBy;

  /// 今のペースを保った場合に、制限時間までに解き終えられる見込みの問題数。
  final int projectedTotal;

  /// [projectedTotal] が問題数以上か（このペースなら時間内に解き切れるか）。
  final bool onTrack;
}

/// 145問ペース走（型④の直前版、決定76）。採点は行わず、タイマー・旗（見直し
/// 候補）・ペース表示だけを提供し、時間配分の技能を練習する。
class PaceRunner {
  const PaceRunner(this.config);

  final PaceRunConfig config;

  /// [answeredCount] 問を [elapsed] で解いた時点のペース状態を計算する。
  PaceStatus statusAt({required int answeredCount, required Duration elapsed}) {
    final elapsedSec = elapsed.inSeconds;
    final expectedAnswered = config.timeLimitSec <= 0
        ? config.questionCount
        : (elapsedSec / config.timeLimitSec * config.questionCount).round();
    final projectedTotal = elapsedSec <= 0
        ? config.questionCount
        : (answeredCount / elapsedSec * config.timeLimitSec).round();
    return PaceStatus(
      expectedAnswered: expectedAnswered.clamp(0, config.questionCount),
      aheadBy: answeredCount - expectedAnswered,
      projectedTotal: projectedTotal,
      onTrack: projectedTotal >= config.questionCount,
    );
  }
}
