import 'peer_stats.dart';

/// 匿名集計カードの文言。`UkalabStrings` とは別にして、既存アプリを壊さない。
///
/// 比べて焦らせない調子（励ます・煽らない）。ja・en は推敲済み。運営での文言確認は別途必要。
class PeerStatsStrings {
  const PeerStatsStrings({
    required this.title,
    required this.todayLearners,
    required this.examMates,
    required this.totalAndMedian,
    required this.streakTop,
    required this.anonymousNote,
  });

  final String title;
  final String Function(String n) todayLearners;
  final String Function(String n, int daysLeft) examMates;
  final String Function(String total, String median) totalAndMedian;
  final String Function(int percent) streakTop;
  final String anonymousNote;

  /// 3 桁区切り。
  static String fmt(int n) {
    final s = n.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return n < 0 ? '-$b' : '$b';
  }

  /// 表示する行（出さない項目は含まない）。
  List<String> lines(PeerStatsView v) => [
        if (v.todayLearners != null) todayLearners(fmt(v.todayLearners!)),
        if (v.examMates != null) examMates(fmt(v.examMates!.count), v.examMates!.daysLeft),
        if (v.totalQuestions != null && v.medianQuestions != null)
          totalAndMedian(fmt(v.totalQuestions!), fmt(v.medianQuestions!)),
        if (v.streakTopPercent != null) streakTop(v.streakTopPercent!),
      ];

  List<String> get allTexts => [
        title,
        todayLearners('1'), todayLearners('12,345'),
        examMates('101', 1), examMates('1,234', 90),
        totalAndMedian('1,000,000', '250'),
        streakTop(1), streakTop(50),
        anonymousNote,
      ];

  static final ja = PeerStatsStrings(
    title: '他にも頑張っている人がいます',
    todayLearners: (n) => '今日、$n人が学習しています',
    examMates: (n, d) => d == 0
        ? '同じ試験日を目指す仲間は$n人（今日が試験日）'
        : '同じ試験日を目指す仲間は$n人（あと$d日）',
    totalAndMedian: (t, m) => 'みんなで$t問を解きました。1人あたり（中央値）は$m問',
    streakTop: (p) => 'あなたの連続日数は、全体の上位$p%です',
    anonymousNote: '匿名の集計です。個人は特定されません。',
  );

  static final en = PeerStatsStrings(
    title: 'Others are working hard too',
    todayLearners: (n) => '$n people studied today',
    examMates: (n, d) => d == 0
        ? '$n people aiming for the same exam date (it\'s today)'
        : d == 1
            ? '$n people aiming for the same exam date (1 day to go)'
            : '$n people aiming for the same exam date ($d days to go)',
    totalAndMedian: (t, m) => 'Together we solved $t questions. Median per person: $m',
    streakTop: (p) => 'Your streak is in the top $p% of everyone',
    anonymousNote: 'Anonymous totals only. No one can be identified.',
  );

  static PeerStatsStrings forLanguageCode(String code) => switch (code) {
        'en' => en,
        _ => ja,
      };
}
