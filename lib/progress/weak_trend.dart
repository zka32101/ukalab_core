import '../question/question.dart';
import 'progress_record.dart';
import 'weak_topics.dart';

/// 章ごとの弱点スコアの変化（自分の過去との比較のみ。他人とは比べない）。
class WeakTrend {
  const WeakTrend({
    required this.chapterId,
    required this.previousScore,
    required this.currentScore,
  });

  final String chapterId;

  /// [period] 前の時点の弱点スコア（0 は弱点なし）。
  final double previousScore;

  /// 今の弱点スコア（0 は弱点なし）。
  final double currentScore;

  /// 現在 − 過去。負なら改善、正なら悪化。
  double get delta => currentScore - previousScore;

  bool get improved => delta < 0;
}

/// 今週の弱点トップ（章単位）。[days] 日以内の解答だけで数え、弱い順に [limit] 件まで。
List<WeakTopic> weeklyWeakTop(
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
  return computeWeakTopics(
    recent,
    now: now,
    config: config,
    questions: questions,
    byChapter: true,
  ).take(limit).toList();
}

/// 章ごとの弱点スコアの推移。「今」と「[periodDays] 日前」の2時点を、それぞれその時点までの
/// 解答だけで計算して比べる。どちらかで弱点があった章だけを、改善が大きい順（差が小さい順）
/// に返す。
List<WeakTrend> weakTrend(
  List<ProgressRecord> records, {
  required DateTime now,
  int periodDays = 7,
  WeakScoreConfig config = const WeakScoreConfig(),
  List<Question> questions = const [],
}) {
  final before = now.subtract(Duration(days: periodDays));
  Map<String, double> scoresAt(DateTime at) => {
        for (final t in computeWeakTopics(
          [
            for (final r in records)
              if (!r.at.isAfter(at)) r,
          ],
          now: at,
          config: config,
          questions: questions,
          byChapter: true,
        ))
          t.chapterId: t.score,
      };

  final previous = scoresAt(before);
  final current = scoresAt(now);
  final chapters = {...previous.keys, ...current.keys}.toList();
  final trends = [
    for (final c in chapters)
      WeakTrend(
        chapterId: c,
        previousScore: previous[c] ?? 0,
        currentScore: current[c] ?? 0,
      ),
  ]..sort((a, b) {
      final byDelta = a.delta.compareTo(b.delta);
      return byDelta != 0 ? byDelta : a.chapterId.compareTo(b.chapterId);
    });
  return trends;
}
