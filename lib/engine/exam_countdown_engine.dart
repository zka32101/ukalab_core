import 'exam_date.dart';

/// 試験日までの段階。煽らず、気持ちの向け方を変えるためだけに使う。
enum ExamCountdownPhase {
  /// 試験日が未設定。
  none,

  /// 100日を超える。
  farAway,

  /// 31〜100日。
  approaching,

  /// 8〜30日。
  close,

  /// 1〜7日（`final` は予約語のため finalDays）。
  finalDays,

  /// 当日。
  today,

  /// 試験日を過ぎた。
  done,
}

/// [ExamCountdownEngine] の結果。[daysLeft] は暦日差（当日 0、過去は負、未設定は null）。
class ExamCountdown {
  const ExamCountdown({required this.daysLeft, required this.phase});

  final int? daysLeft;
  final ExamCountdownPhase phase;

  /// カウントを見せる段階か（未設定・終了後は見せない）。
  bool get showsCount => switch (phase) {
        ExamCountdownPhase.farAway ||
        ExamCountdownPhase.approaching ||
        ExamCountdownPhase.close ||
        ExamCountdownPhase.finalDays =>
          true,
        _ => false,
      };

  @override
  bool operator ==(Object other) =>
      other is ExamCountdown && other.daysLeft == daysLeft && other.phase == phase;

  @override
  int get hashCode => Object.hash(daysLeft, phase);

  @override
  String toString() => 'ExamCountdown($daysLeft, $phase)';
}

/// 試験日までの日数と段階を求める（純 Dart）。
///
/// 日数は [daysUntilExam]（年月日だけを UTC に置き直した暦日差）で数えるので、
/// 時刻やタイムゾーン・夏時間の切り替えで 1 日ずれない。
class ExamCountdownEngine {
  const ExamCountdownEngine();

  /// [examDate] が null なら [ExamCountdownPhase.none]。[today] はテスト用の基準日（省略時は現在）。
  ExamCountdown compute(DateTime? examDate, {DateTime? today}) {
    if (examDate == null) {
      return const ExamCountdown(daysLeft: null, phase: ExamCountdownPhase.none);
    }
    final days = daysUntilExam(examDate, today ?? DateTime.now());
    return ExamCountdown(daysLeft: days, phase: phaseFor(days));
  }

  /// 残り日数から段階を決める。
  static ExamCountdownPhase phaseFor(int daysLeft) {
    if (daysLeft < 0) return ExamCountdownPhase.done;
    if (daysLeft == 0) return ExamCountdownPhase.today;
    if (daysLeft <= 7) return ExamCountdownPhase.finalDays;
    if (daysLeft <= 30) return ExamCountdownPhase.close;
    if (daysLeft <= 100) return ExamCountdownPhase.approaching;
    return ExamCountdownPhase.farAway;
  }
}

/// 未習得問題に掛ける安全マージン。解き直しが発生する前提で、単純な
/// 「残り問題数÷残り日数」より少し多めに見積もる（bike の ExamPlanService と同じ 1.3）。
const double kDailyGoalBufferFactor = 1.3;

/// 試験日から逆算した「1日あたりに解く問題数」の目安（純 Dart）。
///
/// 式: `ceil(unmasteredCount × bufferFactor ÷ 残り日数)`。残り日数は [daysUntilExam]
/// （年月日だけの暦日差。時刻は無視）で、試験当日は 1 日として数える。
/// - 試験日が過去なら null（呼び出し側で「試験日を過ぎています」等を出す）
/// - [unmasteredCount] が 0 以下なら 0
///
/// 受験日の保存は既存の `ExamDateStore`（`package:ukalab_core/exam_date.dart`）を使う。
/// [now] を省略すると現在時刻。
int? dailyGoal({
  required DateTime examDate,
  required int unmasteredCount,
  DateTime? now,
  double bufferFactor = kDailyGoalBufferFactor,
}) {
  final daysLeft = daysUntilExam(examDate, now ?? DateTime.now());
  if (daysLeft < 0) return null;
  if (unmasteredCount <= 0) return 0;
  final effectiveDays = daysLeft == 0 ? 1 : daysLeft;
  return (unmasteredCount * bufferFactor / effectiveDays).ceil();
}
