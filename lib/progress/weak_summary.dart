import '../question/question.dart';
import 'progress_record.dart';
import 'weak_topics.dart';
import 'weak_trend.dart';

/// 「今週の弱点」の表示用まとめ（[WeakSummaryCard] の元データ）。
/// 自分の過去との比較だけで、他の利用者とは比べない。
class WeakSummary {
  const WeakSummary({
    required this.top,
    required this.causeCounts,
    required this.trends,
    required this.answered,
    required this.missed,
  });

  /// 今週の弱点トップ（章単位、弱い順）。
  final List<WeakTopic> top;

  /// 今週の誤答を原因ラベル別に数えたもの（ラベルを付けた誤答のみ）。
  final Map<WrongCause, int> causeCounts;

  /// 章ごとの弱点スコアの推移（改善が大きい順）。
  final List<WeakTrend> trends;

  /// 今週の解答数と誤答数。
  final int answered;
  final int missed;

  /// 表示するものが何もない（今週の弱点が無い）。
  bool get isEmpty => top.isEmpty;
}

/// 解答記録から [WeakSummary] を作る。[days] 日以内の解答で、上位 [limit] 章まで。
/// 推移は「今」と「[days] 日前」の比較（[weakTrend]）。
WeakSummary buildWeakSummary(
  List<ProgressRecord> records, {
  required DateTime now,
  int days = 7,
  int limit = 3,
  WeakScoreConfig config = const WeakScoreConfig(),
  List<Question> questions = const [],
}) {
  final cutoff = now.subtract(Duration(days: days));
  final recent = [
    for (final r in records)
      if (!r.at.isBefore(cutoff) && !r.at.isAfter(now)) r,
  ];
  final causes = <WrongCause, int>{};
  var missed = 0;
  for (final r in recent) {
    if (r.correct) continue;
    missed++;
    final c = r.cause;
    if (c != null) causes[c] = (causes[c] ?? 0) + 1;
  }
  return WeakSummary(
    top: weeklyWeakTop(
      records,
      now: now,
      days: days,
      limit: limit,
      config: config,
      questions: questions,
    ),
    causeCounts: Map.unmodifiable(causes),
    trends: weakTrend(
      records,
      now: now,
      periodDays: days,
      config: config,
      questions: questions,
    ),
    answered: recent.length,
    missed: missed,
  );
}
