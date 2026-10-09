import 'dart:math' as math;

import '../progress/progress_record.dart';
import '../progress/review_priority.dart';
import '../progress/weak_topics.dart';
import '../question/question.dart';
import 'weak_drill.dart';

/// 問題1問にかかる時間（秒）の目安を出す。
///
/// 同じ問題の過去の回答時間の平均 → 同じ章の回答時間の平均 → 問題タイプごとの
/// 既定値、の順に使う。10〜900秒に収める。
class QuestionTimeEstimator {
  QuestionTimeEstimator._(this._byQid, this._byTopic);

  factory QuestionTimeEstimator(List<ProgressRecord> records, List<Question> questions) {
    final topicOf = {for (final q in questions) q.qid: q.topicId};
    final qidMs = <String, List<int>>{};
    final topicMs = <String, List<int>>{};
    for (final r in records) {
      final ms = r.ms;
      if (ms == null || ms <= 0) continue;
      (qidMs[r.qid] ??= []).add(ms);
      final topic = r.topicId ?? topicOf[r.qid];
      if (topic != null) (topicMs[topic] ??= []).add(ms);
    }
    return QuestionTimeEstimator._(
      {for (final e in qidMs.entries) e.key: _averageSeconds(e.value)},
      {for (final e in topicMs.entries) e.key: _averageSeconds(e.value)},
    );
  }

  /// 回答の記録がないときの、問題タイプごとの既定値（秒）。
  static const Map<QuestionType, int> defaultSeconds = {
    QuestionType.choice: 45,
    QuestionType.journal: 120,
    QuestionType.worksheet: 300,
    QuestionType.ledger: 300,
  };

  static const minSeconds = 10;
  static const maxSeconds = 900;

  final Map<String, int> _byQid;
  final Map<String, int> _byTopic;

  int estimateSeconds(Question q) {
    final seconds = _byQid[q.qid] ?? _byTopic[q.topicId] ?? defaultSeconds[q.type] ?? 60;
    return math.min(maxSeconds, math.max(minSeconds, seconds));
  }

  static int _averageSeconds(List<int> ms) =>
      (ms.reduce((a, b) => a + b) / ms.length / 1000).round();
}

/// 空き時間に収まる問題セット。
class TimeBoxedPlan {
  const TimeBoxedPlan({
    required this.questions,
    required this.estimatedSeconds,
    required this.budgetSeconds,
  });

  final List<Question> questions;

  /// 問題セットにかかる時間の目安（秒）。[budgetSeconds] 以下。
  final int estimatedSeconds;

  /// 利用者が選んだ空き時間（秒）。
  final int budgetSeconds;
}

/// 空き時間（[minutes] 分）に収まる問題セットを組む（今日の10分プランなど）。
///
/// 優先順: [firstQids]（試験直前モードの出題など、呼び出し側が先に出したいもの）
/// → 弱点集中ドリルの問題 → 直近で間違えたままの問題 → まだ解いていない問題
/// （やさしい順）→ 残りの問題（やさしい順）。この順に、1問の時間の目安
/// （[QuestionTimeEstimator]）が残り時間に収まるものだけを入れる。
/// 収まらない問題は飛ばし、後ろの短い問題を入れる。無効な問題は入れない。
TimeBoxedPlan buildTimeBoxedPlan(
  List<Question> questions,
  List<ProgressRecord> records, {
  required DateTime now,
  int minutes = 10,
  List<String> firstQids = const [],
  WeakScoreConfig config = const WeakScoreConfig(),
}) {
  final budget = math.max(0, minutes) * 60;
  final active = [
    for (final q in questions)
      if (!q.disabled) q,
  ];
  if (budget == 0 || active.isEmpty) {
    return TimeBoxedPlan(questions: const [], estimatedSeconds: 0, budgetSeconds: budget);
  }

  final byQid = {for (final q in active) q.qid: q};
  final order = <String>[];
  final seen = <String>{};
  void add(String qid) {
    if (byQid.containsKey(qid) && seen.add(qid)) order.add(qid);
  }

  firstQids.forEach(add);
  for (final q in buildWeakDrill(active, records, now: now, size: active.length, config: config)) {
    add(q.qid);
  }
  reviewPriorityQids(records).forEach(add);

  final byDifficulty = [...active]..sort((a, b) {
      final d = a.difficulty.compareTo(b.difficulty);
      return d != 0 ? d : a.qid.compareTo(b.qid);
    });
  final answered = {for (final r in records) r.qid};
  for (final q in byDifficulty) {
    if (!answered.contains(q.qid)) add(q.qid);
  }
  for (final q in byDifficulty) {
    add(q.qid);
  }

  final estimator = QuestionTimeEstimator(records, active);
  final chosen = <Question>[];
  var total = 0;
  for (final qid in order) {
    final q = byQid[qid]!;
    final seconds = estimator.estimateSeconds(q);
    if (total + seconds > budget) continue;
    chosen.add(q);
    total += seconds;
  }
  return TimeBoxedPlan(questions: chosen, estimatedSeconds: total, budgetSeconds: budget);
}
