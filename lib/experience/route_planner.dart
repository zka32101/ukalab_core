import '../config/exam_config.dart';

/// 最短ルートプランナー（型④、決定76・77）に渡す、1科目ぶんの学習進捗。
class SubjectProgress {
  const SubjectProgress({required this.subjectId, required this.accuracy});

  final String subjectId;

  /// 正答率（0.0〜1.0）。
  final double accuracy;
}

/// 最短ルートプランナーが「今日やる3つ」として選んだ1科目。
class RouteTask {
  const RouteTask({
    required this.subjectId,
    required this.score,
    required this.belowPassLine,
  });

  final String subjectId;

  /// 伸びしろ×配点（1分あたりの得点の伸びの近似。決定77で判定式を統一）。
  final double score;

  /// 足切り（科目別の最低得点率）を下回っているか。下回っていれば最優先（決定77）。
  final bool belowPassLine;
}

/// 残り日数・弱点・配点から「今日やる3つ」を出す（決定76）。
///
/// 判定は「伸びしろ(1-正答率)×配点」（決定77）。配点は
/// [LevelConfig.subjectQuestionCounts] があれば出題数の割合で近似し、
/// なければ科目を均等とみなす（1問あたりの配点が同じ前提）。所要時間は
/// 科目間で同程度と仮定し、最小実装では判定式から省く。
/// 足切り・科目合格のある資格（[PassRule.subjectMinPct]）は、
/// 合格ラインを下回る科目を他のどの科目よりも優先する（決定77）。
class RoutePlanner {
  const RoutePlanner();

  /// [progress] に挙がっていない科目は正答率0として扱う（未着手＝伸びしろ最大）。
  List<RouteTask> plan({
    required ExamConfig exam,
    required LevelConfig level,
    required List<SubjectProgress> progress,
    int taskCount = 3,
  }) {
    final accuracyBySubject = {
      for (final p in progress) p.subjectId: p.accuracy,
    };
    final counts = level.subjectQuestionCounts;
    final totalCount = counts?.values.fold(0, (a, b) => a + b);
    final minPct = level.passRule.subjectMinPct;

    final tasks = [
      for (final s in exam.subjects)
        _taskFor(s, accuracyBySubject[s.subjectId] ?? 0, counts, totalCount, minPct),
    ];

    tasks.sort((a, b) {
      if (a.belowPassLine != b.belowPassLine) {
        return a.belowPassLine ? -1 : 1;
      }
      return b.score.compareTo(a.score);
    });
    return tasks.take(taskCount).toList();
  }

  RouteTask _taskFor(
    SubjectConfig subject,
    double accuracy,
    Map<String, int>? counts,
    int? totalCount,
    double? minPct,
  ) {
    final weight = counts == null || totalCount == null || totalCount == 0
        ? 1.0
        : (counts[subject.subjectId] ?? 0) / totalCount;
    final growth = 1.0 - accuracy.clamp(0.0, 1.0);
    final belowPassLine = minPct != null && accuracy * 100 < minPct;
    return RouteTask(
      subjectId: subject.subjectId,
      score: growth * weight,
      belowPassLine: belowPassLine,
    );
  }
}
