import 'oshi_growth_strings.dart';
import 'oshi_message_engine.dart';

/// 推しの成長段階。累計の学習量だけで決まり、休んでも下がらない。
enum OshiGrowthStage { newcomer, budding, growing, blooming, radiant }

/// 節目が数える量。
enum OshiGrowthMetric { answered, studyDays }

/// 成長演出に使う累計の学習量（アプリが渡す）。個人情報は含めない。負の値は 0 に直す。
class OshiGrowthProgress {
  const OshiGrowthProgress({int totalAnswered = 0, int studyDays = 0})
      : totalAnswered = totalAnswered < 0 ? 0 : totalAnswered,
        studyDays = studyDays < 0 ? 0 : studyDays;

  /// 累計の回答数。
  final int totalAnswered;

  /// 学習した日の合計（連続日数ではない）。
  final int studyDays;

  int valueOf(OshiGrowthMetric m) => switch (m) {
        OshiGrowthMetric.answered => totalAnswered,
        OshiGrowthMetric.studyDays => studyDays,
      };
}

/// 節目 1 件。[id] は既出判定の保存に使うので変えない（`answered_10` / `days_7`）。
class OshiGrowthMilestone {
  const OshiGrowthMilestone(this.metric, this.threshold);

  const OshiGrowthMilestone.answered(int n) : this(OshiGrowthMetric.answered, n);
  const OshiGrowthMilestone.days(int n) : this(OshiGrowthMetric.studyDays, n);

  final OshiGrowthMetric metric;
  final int threshold;

  String get id => switch (metric) {
        OshiGrowthMetric.answered => 'answered_$threshold',
        OshiGrowthMetric.studyDays => 'days_$threshold',
      };

  bool isReached(OshiGrowthProgress p) => p.valueOf(metric) >= threshold;

  @override
  bool operator ==(Object other) => other is OshiGrowthMilestone && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// 推しの今の反応（表情の絵文字・ラベル・一言）。
class OshiGrowthReaction {
  const OshiGrowthReaction({
    required this.id,
    required this.stage,
    required this.emoji,
    required this.label,
    required this.text,
  });

  /// `<段階名>_<言い回し番号>`。
  final String id;
  final OshiGrowthStage stage;
  final String emoji;
  final String label;
  final String text;
}

/// 節目到達を祝うための表示内容。
class OshiGrowthCelebration {
  const OshiGrowthCelebration({
    required this.milestone,
    required this.emoji,
    required this.title,
    required this.body,
  });

  final OshiGrowthMilestone milestone;
  final String emoji;
  final String title;
  final String body;
}

/// 累計の学習量から、推しの反応と節目の祝福を決める（純 Dart・冪等）。
///
/// 次の節目までの残りを数えて促す仕組みは持たない（到達した分だけを返す）。
class OshiGrowthEngine {
  const OshiGrowthEngine({
    this.strings = OshiGrowthStrings.ja,
    this.milestones = defaultMilestones,
  });

  final OshiGrowthStrings strings;

  /// 節目の定義。小さい順（同程度は回答数→日数）。最後のものが最も大きな節目として扱われる。
  final List<OshiGrowthMilestone> milestones;

  static const List<OshiGrowthMilestone> defaultMilestones = [
    OshiGrowthMilestone.answered(10),
    OshiGrowthMilestone.days(7),
    OshiGrowthMilestone.answered(50),
    OshiGrowthMilestone.days(30),
    OshiGrowthMilestone.answered(100),
    OshiGrowthMilestone.days(100),
    OshiGrowthMilestone.answered(300),
    OshiGrowthMilestone.answered(1000),
  ];

  /// 成長段階。回答数と学習日数のうち進んでいる方で決まる。
  /// 回答 10/100/300/1000 問、学習 7/30/100 日で 1 段ずつ上がる。
  static OshiGrowthStage stageOf(OshiGrowthProgress p) {
    final a = p.totalAnswered;
    final d = p.studyDays;
    final byAnswered = a >= 1000 ? 4 : a >= 300 ? 3 : a >= 100 ? 2 : a >= 10 ? 1 : 0;
    final byDays = d >= 100 ? 3 : d >= 30 ? 2 : d >= 7 ? 1 : 0;
    return OshiGrowthStage.values[byAnswered > byDays ? byAnswered : byDays];
  }

  /// 今の反応。[seed] が同じなら同じ結果。[salt] を変えると同じ段階で別の言い回し（タップ切替用）。
  OshiGrowthReaction reaction(OshiGrowthProgress p, {required int seed, int salt = 0}) {
    final stage = stageOf(p);
    final t = strings.stageText(stage);
    final i = t.messages.isEmpty ? 0 : (seed + salt).abs() % t.messages.length;
    return OshiGrowthReaction(
      id: '${stage.name}_$i',
      stage: stage,
      emoji: t.emoji,
      label: t.label,
      text: t.messages.isEmpty ? '' : t.messages[i],
    );
  }

  /// 日付から seed を作る（同じ日は同じ値で、日替わり）。
  static int seedFromDate(DateTime d) => OshiMessageEngine.seedFromDate(d);

  /// 到達済みの節目（定義の順）。
  List<OshiGrowthMilestone> reached(OshiGrowthProgress p) =>
      [for (final m in milestones) if (m.isReached(p)) m];

  /// 到達していて、かつ [alreadyCelebrated]（節目 ID）に無い節目（定義の順）。同じ入力なら同じ結果。
  List<OshiGrowthMilestone> newlyReached(
    OshiGrowthProgress p, {
    Set<String> alreadyCelebrated = const {},
  }) {
    final seen = <String>{...alreadyCelebrated};
    final out = <OshiGrowthMilestone>[];
    for (final m in milestones) {
      if (seen.contains(m.id) || !m.isReached(p)) continue;
      seen.add(m.id);
      out.add(m);
    }
    return out;
  }

  /// 複数の節目を同時に迎えたとき、一度に見せる 1 件（定義の中で最後のもの）。
  OshiGrowthMilestone? headlineOf(Iterable<OshiGrowthMilestone> reached) {
    OshiGrowthMilestone? best;
    var bestIndex = -1;
    for (final m in reached) {
      final i = milestones.indexOf(m);
      if (i > bestIndex) {
        best = m;
        bestIndex = i;
      }
    }
    return best;
  }

  /// 節目の表示内容。
  OshiGrowthCelebration celebrate(OshiGrowthMilestone m) {
    final isAnswered = m.metric == OshiGrowthMetric.answered;
    final n = '${m.threshold}';
    final title = (isAnswered ? strings.answeredTitle : strings.daysTitle).replaceAll('{n}', n);
    final body = (strings.milestoneBodies[m.id] ??
            (isAnswered ? strings.answeredFallbackBody : strings.daysFallbackBody))
        .replaceAll('{n}', n);
    return OshiGrowthCelebration(
      milestone: m,
      emoji: isAnswered ? strings.answeredEmoji : strings.daysEmoji,
      title: title,
      body: body,
    );
  }
}
