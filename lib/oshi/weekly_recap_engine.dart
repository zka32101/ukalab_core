import '../progress/progress_record.dart';

/// 週間ふりかえりの入力（日別・分野別の記録）。個人情報・問題IDは持たない。
class WeeklyRecapDay {
  const WeeklyRecapDay({
    required this.date,
    required this.answered,
    required this.correct,
    this.topicId,
  });

  /// 日付（時刻は無視して年月日で扱う）。
  final DateTime date;
  final int answered;
  final int correct;

  /// 分野（章）ID。不明なら null。
  final String? topicId;
}

/// 解答記録（[ProgressRecord]）から [WeeklyRecapDay] を作る（日付×分野ごとに1件）。
/// 問題ID・原因ラベル・回答時間は引き継がない。
List<WeeklyRecapDay> weeklyRecapDaysFromRecords(Iterable<ProgressRecord> records) {
  final answered = <(DateTime, String?), int>{};
  final correct = <(DateTime, String?), int>{};
  for (final r in records) {
    final key = (DateTime(r.at.year, r.at.month, r.at.day), r.topicId);
    answered[key] = (answered[key] ?? 0) + 1;
    if (r.correct) correct[key] = (correct[key] ?? 0) + 1;
  }
  final keys = answered.keys.toList()
    ..sort((a, b) {
      final c = a.$1.compareTo(b.$1);
      return c != 0 ? c : (a.$2 ?? '').compareTo(b.$2 ?? '');
    });
  return [
    for (final k in keys)
      WeeklyRecapDay(
        date: k.$1,
        answered: answered[k]!,
        correct: correct[k] ?? 0,
        topicId: k.$2,
      ),
  ];
}

/// 分野ごとの週の集計。
class WeeklyRecapTopic {
  const WeeklyRecapTopic({required this.topicId, required this.answered, required this.correct});

  final String topicId;
  final int answered;
  final int correct;

  double get accuracy => answered == 0 ? 0 : correct / answered;
}

/// 1週間の「できたこと」のまとめ。前週との比較は持たない。
class WeeklyRecap {
  const WeeklyRecap({
    required this.weekStart,
    required this.answered,
    required this.correct,
    required this.studyDays,
    required this.streakDays,
    required this.topTopics,
    required this.improvedTopics,
    required this.medalsEarned,
  });

  /// 週の最初の日（0時）。
  final DateTime weekStart;
  final int answered;
  final int correct;

  /// 解いた日の数（0〜7）。
  final int studyDays;

  /// 週の中で続いた日数の最長（解いた日が無ければ 0）。
  final int streakDays;

  /// よく解いた分野（解いた数の多い順）。
  final List<WeeklyRecapTopic> topTopics;

  /// 正答率が上がった分野のID。表示は「伸びた分野」とだけ伝え、差は見せない。
  final List<String> improvedTopics;
  final int medalsEarned;

  /// 今週は解いていない。責めずに穏やかな表示にする。
  bool get isEmpty => answered == 0;

  double get accuracy => answered == 0 ? 0 : correct / answered;
}

/// 日別記録から週間ふりかえりを作る（純 Dart）。
class WeeklyRecapEngine {
  const WeeklyRecapEngine({
    this.weekStartsOn = DateTime.monday,
    this.topCount = 3,
    this.minSampleForImprovement = 3,
  }) : assert(weekStartsOn >= DateTime.monday && weekStartsOn <= DateTime.sunday);

  /// 週の起点の曜日（[DateTime.monday]〜[DateTime.sunday]）。既定は月曜始まり。
  final int weekStartsOn;
  final int topCount;

  /// 「伸びた」と判定するのに、今週・前週それぞれで必要な最低解答数。
  final int minSampleForImprovement;

  /// [date] を含む週の最初の日。
  DateTime weekStartOf(DateTime date) {
    final diff = (date.weekday - weekStartsOn + 7) % 7;
    return DateTime(date.year, date.month, date.day - diff);
  }

  /// [weekOf] を含む週の集計。[medalsEarned] はアプリが数えた今週のメダル数。
  WeeklyRecap build(
    List<WeeklyRecapDay> days, {
    required DateTime weekOf,
    int medalsEarned = 0,
  }) {
    final start = weekStartOf(weekOf);
    final end = DateTime(start.year, start.month, start.day + 7);
    final prevStart = DateTime(start.year, start.month, start.day - 7);

    final thisWeek = <DateTime, int>{}; // 日 -> 解答数
    final topics = <String, List<int>>{};
    final prevTopics = <String, List<int>>{};
    var answered = 0;
    var correct = 0;

    for (final d in days) {
      final a = d.answered < 0 ? 0 : d.answered;
      if (a == 0) continue;
      final c = d.correct < 0 ? 0 : (d.correct > a ? a : d.correct);
      final day = DateTime(d.date.year, d.date.month, d.date.day);
      final inThis = !day.isBefore(start) && day.isBefore(end);
      final inPrev = !day.isBefore(prevStart) && day.isBefore(start);
      if (inThis) {
        answered += a;
        correct += c;
        thisWeek[day] = (thisWeek[day] ?? 0) + a;
      }
      final t = d.topicId;
      if (t == null) continue;
      final target = inThis ? topics : (inPrev ? prevTopics : null);
      if (target == null) continue;
      final v = target.putIfAbsent(t, () => [0, 0]);
      v[0] += a;
      v[1] += c;
    }

    final studied = thisWeek.keys.toList()..sort();
    var longest = 0;
    var run = 0;
    DateTime? prev;
    for (final day in studied) {
      run = (prev != null && day == DateTime(prev.year, prev.month, prev.day + 1)) ? run + 1 : 1;
      if (run > longest) longest = run;
      prev = day;
    }

    final top = [
      for (final e in topics.entries)
        WeeklyRecapTopic(topicId: e.key, answered: e.value[0], correct: e.value[1]),
    ]..sort((a, b) {
        final c = b.answered.compareTo(a.answered);
        if (c != 0) return c;
        final c2 = b.correct.compareTo(a.correct);
        return c2 != 0 ? c2 : a.topicId.compareTo(b.topicId);
      });

    final improved = <String>[
      for (final e in topics.entries)
        if (e.value[0] >= minSampleForImprovement &&
            (prevTopics[e.key]?[0] ?? 0) >= minSampleForImprovement &&
            e.value[1] / e.value[0] > prevTopics[e.key]![1] / prevTopics[e.key]![0])
          e.key,
    ]..sort();

    return WeeklyRecap(
      weekStart: start,
      answered: answered,
      correct: correct,
      studyDays: studied.length,
      streakDays: longest,
      topTopics: top.take(topCount < 0 ? 0 : topCount).toList(),
      improvedTopics: improved,
      medalsEarned: medalsEarned < 0 ? 0 : medalsEarned,
    );
  }
}
