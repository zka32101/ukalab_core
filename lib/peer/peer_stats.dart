import '../engine/exam_countdown_engine.dart';

/// 「他にも頑張っている人がいる」のための匿名の集計値（純 Dart）。
///
/// 個人を特定する値は一切持たない。人数・合計・中央値・度数分布だけ。
/// 集計は Cloud Function などサーバ側で行い、端末はこの形の要約を読むだけ
/// （詳細は `docs/peer_stats.md`）。
class PeerStatsSnapshot {
  const PeerStatsSnapshot({
    required this.asOf,
    required this.activeToday,
    required this.participants,
    required this.totalQuestions,
    required this.medianQuestions,
    this.streakCounts = const {},
    this.examDateCounts = const {},
  });

  /// 集計日（`yyyy-MM-dd`）。
  final String asOf;

  /// 集計日に学習した人数。
  final int activeToday;

  /// 集計対象の人数（累計・中央値の母数）。
  final int participants;

  /// 全員の累計問題数。
  final int totalQuestions;

  /// 1人あたり累計問題数の中央値。
  final int medianQuestions;

  /// 連続日数ごとの人数（連続日数 -> 人数、1 以上）。
  final Map<int, int> streakCounts;

  /// 試験日（`yyyy-MM-dd`）ごとの人数。
  final Map<String, int> examDateCounts;

  static int _int(Object? v) => v is num ? v.toInt() : 0;

  /// 不正な値は 0 / 空として扱う（サーバの形が将来変わっても落とさない）。
  factory PeerStatsSnapshot.fromJson(Map<String, dynamic> json) {
    final streaks = <int, int>{};
    final rawStreaks = json['streakCounts'];
    if (rawStreaks is Map) {
      rawStreaks.forEach((k, v) {
        final day = int.tryParse('$k');
        final n = _int(v);
        if (day != null && day >= 1 && n > 0) streaks[day] = n;
      });
    }
    final dates = <String, int>{};
    final rawDates = json['examDateCounts'];
    if (rawDates is Map) {
      rawDates.forEach((k, v) {
        final n = _int(v);
        if (n > 0) dates['$k'] = n;
      });
    }
    return PeerStatsSnapshot(
      asOf: '${json['asOf'] ?? ''}',
      activeToday: _int(json['activeToday']),
      participants: _int(json['participants']),
      totalQuestions: _int(json['totalQuestions']),
      medianQuestions: _int(json['medianQuestions']),
      streakCounts: streaks,
      examDateCounts: dates,
    );
  }

  Map<String, dynamic> toJson() => {
        'asOf': asOf,
        'activeToday': activeToday,
        'participants': participants,
        'totalQuestions': totalQuestions,
        'medianQuestions': medianQuestions,
        'streakCounts': {for (final e in streakCounts.entries) '${e.key}': e.value},
        'examDateCounts': examDateCounts,
      };
}

/// 表示の判定と計算。閾値は「100 人を**超えたら**表示」（100 人ちょうどは非表示）。
class PeerStatsPolicy {
  const PeerStatsPolicy._();

  /// この人数を超えるまで表示しない。
  static const int minVisible = 100;

  /// 上位 % を出すのは、上位半分のときだけ（下位の人を落ち込ませない）。
  static const int maxTopPercentShown = 50;

  static bool isVisible(int count) => count > minVisible;

  /// 人数の昇順/順不同の値の中央値。偶数個なら中央2つの平均を切り捨て。空は 0。
  static int median(Iterable<int> values) {
    final v = values.toList()..sort();
    if (v.isEmpty) return 0;
    final mid = v.length ~/ 2;
    return v.length.isOdd ? v[mid] : (v[mid - 1] + v[mid]) ~/ 2;
  }

  /// 連続日数 [streakDays] が全体の上位何 % か（1〜100。同順位は同じ扱い＝自分以上の人の割合）。
  /// 連続日数が 0 以下、または母数が 0 なら null。
  static int? topPercent(int streakDays, Map<int, int> streakCounts) {
    if (streakDays < 1) return null;
    var total = 0;
    var atLeast = 0;
    streakCounts.forEach((day, n) {
      if (n <= 0) return;
      total += n;
      if (day >= streakDays) atLeast += n;
    });
    if (total == 0) return null;
    // 自分がまだ集計に入っていない（今日の分が未反映）場合も、最小でも自分の 1 人を数える。
    if (atLeast == 0) {
      atLeast = 1;
      total += 1;
    }
    final p = (atLeast * 100 + total - 1) ~/ total; // 切り上げ
    return p.clamp(1, 100);
  }
}

/// 同じ試験日を目指す仲間。
class PeerExamMates {
  const PeerExamMates({required this.count, required this.daysLeft});
  final int count;
  final int daysLeft;
}

/// 画面に出す値。閾値を満たさない項目は null（= 出さない）。
class PeerStatsView {
  const PeerStatsView({
    this.todayLearners,
    this.examMates,
    this.totalQuestions,
    this.medianQuestions,
    this.streakTopPercent,
  });

  final int? todayLearners;
  final PeerExamMates? examMates;
  final int? totalQuestions;
  final int? medianQuestions;
  final int? streakTopPercent;

  bool get isEmpty =>
      todayLearners == null &&
      examMates == null &&
      totalQuestions == null &&
      streakTopPercent == null;

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  factory PeerStatsView.from(
    PeerStatsSnapshot? snapshot, {
    int streakDays = 0,
    DateTime? examDate,
    required DateTime today,
  }) {
    if (snapshot == null) return const PeerStatsView();

    PeerExamMates? mates;
    if (examDate != null) {
      final c = const ExamCountdownEngine().compute(examDate, today: today);
      final n = snapshot.examDateCounts[dateKey(examDate)] ?? 0;
      final left = c.daysLeft;
      if (left != null && left >= 0 && PeerStatsPolicy.isVisible(n)) {
        mates = PeerExamMates(count: n, daysLeft: left);
      }
    }

    final streakTotal = snapshot.streakCounts.values.fold<int>(0, (a, b) => a + b);
    int? top;
    if (PeerStatsPolicy.isVisible(streakTotal)) {
      final p = PeerStatsPolicy.topPercent(streakDays, snapshot.streakCounts);
      if (p != null && p <= PeerStatsPolicy.maxTopPercentShown) top = p;
    }

    final showTotals = PeerStatsPolicy.isVisible(snapshot.participants);
    return PeerStatsView(
      todayLearners: PeerStatsPolicy.isVisible(snapshot.activeToday) ? snapshot.activeToday : null,
      examMates: mates,
      totalQuestions: showTotals ? snapshot.totalQuestions : null,
      medianQuestions: showTotals ? snapshot.medianQuestions : null,
      streakTopPercent: top,
    );
  }
}
