import '../progress/progress_record.dart';
import '../progress/weak_topics.dart';
import '../question/question.dart';

/// 試験直前モードに入る日数（試験日の何日前から）。
const examEveWindowDays = 3;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 今日以降で最も近い試験日（日付のみ）。無ければ null。
DateTime? nextExamDate(List<DateTime> examDates, DateTime now) {
  final today = _dateOnly(now);
  DateTime? best;
  for (final d in examDates) {
    final day = _dateOnly(d);
    if (day.isBefore(today)) continue;
    if (best == null || day.isBefore(best)) best = day;
  }
  return best;
}

/// 直近の試験日までの状況。
class ExamEveStatus {
  const ExamEveStatus({
    required this.examDate,
    required this.daysLeft,
    required this.active,
  });

  /// 直近の試験日（日付のみ）。
  final DateTime examDate;

  /// 今日から試験日までの日数（試験当日は 0）。
  final int daysLeft;

  /// 試験直前モードの期間内か。
  final bool active;
}

/// 試験直前モードの状況を返す。今日以降の試験日が無ければ null。
/// 時刻は無視し、日付だけで数える。
ExamEveStatus? examEveStatus(
  List<DateTime> examDates,
  DateTime now, {
  int windowDays = examEveWindowDays,
}) {
  final next = nextExamDate(examDates, now);
  if (next == null) return null;
  final daysLeft = DateTime.utc(next.year, next.month, next.day)
      .difference(DateTime.utc(now.year, now.month, now.day))
      .inDays;
  return ExamEveStatus(
    examDate: next,
    daysLeft: daysLeft,
    active: daysLeft <= windowDays,
  );
}

/// 試験直前モードで、その問題を出す理由。
enum ExamEveReason {
  /// 直近の誤答。
  recentWrong,

  /// 頻出（[QuestionTag.frequent]）。
  frequent,

  /// 計算式（[QuestionTag.formula]）。
  formula,
}

/// 試験直前モードの出題1問と、出す理由。
class ExamEveItem {
  const ExamEveItem({
    required this.question,
    required this.reasons,
    required this.priority,
  });

  final Question question;

  /// 出す理由（[ExamEveReason] の定義順）。
  final List<ExamEveReason> reasons;
  final double priority;
}

/// 試験直前モードの出題を組む。直近の誤答・頻出・計算式のいずれかに当たる問題だけを、
/// 優先度の高い順に [size] 問まで返す。
///
/// 優先度 = 直近の誤答 4 ＋ 頻出 2 ＋ 計算式 1 ＋ 章の弱点スコア（0〜1）。
/// 直近の誤答は、その問題の最新の解答が誤答で、[recentDays] 日以内のもの。
/// 無効化された問題（disabled）は出さない。
List<ExamEveItem> buildExamEveSet(
  List<Question> questions,
  List<ProgressRecord> records, {
  required DateTime now,
  int size = 20,
  int recentDays = 14,
  WeakScoreConfig config = const WeakScoreConfig(),
}) {
  if (size <= 0) return const [];

  final latest = <String, ProgressRecord>{};
  for (final r in records) {
    final existing = latest[r.qid];
    if (existing == null || r.at.isAfter(existing.at)) latest[r.qid] = r;
  }
  final cutoff = now.subtract(Duration(days: recentDays));
  final weakByChapter = {
    for (final t in computeWeakTopics(
      records,
      now: now,
      config: config,
      questions: questions,
      byChapter: true,
    ))
      t.chapterId: t.score,
  };

  final items = <ExamEveItem>[];
  for (final q in questions) {
    if (q.disabled) continue;
    final reasons = <ExamEveReason>[];
    final last = latest[q.qid];
    if (last != null && !last.correct && !last.at.isBefore(cutoff)) {
      reasons.add(ExamEveReason.recentWrong);
    }
    if (q.tags.contains(QuestionTag.frequent)) reasons.add(ExamEveReason.frequent);
    if (q.tags.contains(QuestionTag.formula)) reasons.add(ExamEveReason.formula);
    if (reasons.isEmpty) continue;

    var priority = weakByChapter[q.topicId] ?? 0.0;
    if (reasons.contains(ExamEveReason.recentWrong)) priority += 4;
    if (reasons.contains(ExamEveReason.frequent)) priority += 2;
    if (reasons.contains(ExamEveReason.formula)) priority += 1;
    items.add(ExamEveItem(question: q, reasons: reasons, priority: priority));
  }

  items.sort((a, b) {
    final byPriority = b.priority.compareTo(a.priority);
    return byPriority != 0 ? byPriority : a.question.qid.compareTo(b.question.qid);
  });
  return items.take(size).toList();
}
