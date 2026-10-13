import 'package:flutter/material.dart';

import '../../policy/premium_features.dart';
import '../../progress/progress_record.dart';
import '../../progress/weak_summary.dart';
import '../../progress/weak_topics.dart';
import '../../progress/weak_trend.dart';
import '../../question/question.dart';
import 'answer_feedback_strings.dart';

/// 弱点まとめ（今週の弱点トップ・原因別の内訳・自分の先週との推移）を使えるか。
/// premium 判定は呼び出し側が行い、結果を [isPremium] に渡す。
bool canShowWeakSummary({required bool isPremium}) =>
    canUsePremiumFeature(PremiumFeature.weakDrill, isPremium: isPremium);

/// 「今週の弱点トップ3」・原因別の集計・自分の過去との推移を出すカード。他人とは比べない。
///
/// premium 機能（[PremiumFeature.weakDrill]）なので、出すかどうかは呼び出し側が
/// [canShowWeakSummary] で決める。章の表示名は [chapterLabel]（省略時は章ID）。
class WeakSummaryCard extends StatelessWidget {
  const WeakSummaryCard({
    super.key,
    required this.records,
    this.now,
    this.questions = const [],
    this.chapterLabel,
    this.limit = 3,
    this.days = 7,
    this.includeCalculation = true,
    this.config = const WeakScoreConfig(),
    this.strings,
  });

  final List<ProgressRecord> records;

  /// 基準時刻。省略時は現在時刻（テスト用に固定できる）。
  final DateTime? now;

  /// 記録に論点が無い旧データを補う問題データ。
  final List<Question> questions;

  /// 章ID → 表示名。
  final String Function(String chapterId)? chapterLabel;

  final int limit;
  final int days;

  /// false なら原因の内訳に「計算ミス」を出さない。
  final bool includeCalculation;

  final WeakScoreConfig config;
  final AnswerFeedbackStrings? strings;

  static const _trendEpsilon = 0.02;

  @override
  Widget build(BuildContext context) {
    final s = strings ?? AnswerFeedbackStrings.of(context);
    final theme = Theme.of(context);
    final label = chapterLabel ?? (String id) => id;
    final summary = buildWeakSummary(
      records,
      now: now ?? DateTime.now(),
      days: days,
      limit: limit,
      config: config,
      questions: questions,
    );

    final children = <Widget>[
      Text(s.weakTitle, style: theme.textTheme.titleMedium),
    ];

    if (summary.isEmpty) {
      children
        ..add(const SizedBox(height: 8))
        ..add(Text(s.weakEmpty));
    } else {
      children
        ..add(const SizedBox(height: 12))
        ..add(Text(s.weakTopTitle(summary.top.length), style: theme.textTheme.titleSmall));
      for (var i = 0; i < summary.top.length; i++) {
        children.add(_topRow(context, s, i + 1, summary.top[i], label));
      }

      children
        ..add(const SizedBox(height: 16))
        ..add(Text(s.weakCauseTitle, style: theme.textTheme.titleSmall))
        ..add(const SizedBox(height: 4));
      final causes = [
        for (final c in WrongCause.values)
          if ((includeCalculation || c != WrongCause.calculation) &&
              (summary.causeCounts[c] ?? 0) > 0)
            c,
      ];
      if (causes.isEmpty) {
        children.add(Text(s.weakCauseEmpty, style: theme.textTheme.bodySmall));
      } else {
        for (final c in causes) {
          children.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(child: Text(s.causeLabel(c))),
                Text('${summary.causeCounts[c]}'),
              ],
            ),
          ));
        }
      }

      children
        ..add(const SizedBox(height: 16))
        ..add(Text(s.weakTrendTitle, style: theme.textTheme.titleSmall))
        ..add(Text(s.weakTrendNote, style: theme.textTheme.bodySmall))
        ..add(const SizedBox(height: 4));
      for (final t in summary.trends.take(5)) {
        children.add(_trendRow(s, t, label));
      }
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }

  Widget _topRow(
    BuildContext context,
    AnswerFeedbackStrings s,
    int rank,
    WeakTopic t,
    String Function(String) label,
  ) {
    final theme = Theme.of(context);
    final dominant = t.dominantCause;
    final cause =
        (!includeCalculation && dominant == WrongCause.calculation) ? null : dominant;
    final prescription = prescriptionFor(cause);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$rank. ', style: theme.textTheme.titleSmall),
              Expanded(child: Text(label(t.chapterId), style: theme.textTheme.titleSmall)),
              Text(s.weakAttempts(t.attempts, t.misses), style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: t.score.clamp(0.0, 1.0).toDouble()),
          if (cause != null && prescription != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${s.causeLabel(cause)}: ${s.prescriptionText(prescription)}',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _trendRow(
    AnswerFeedbackStrings s,
    WeakTrend t,
    String Function(String) label,
  ) {
    final (icon, text) = t.delta < -_trendEpsilon
        ? (Icons.trending_down, s.trendBetter)
        : t.delta > _trendEpsilon
            ? (Icons.trending_up, s.trendWorse)
            : (Icons.trending_flat, s.trendSame);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Expanded(child: Text(label(t.chapterId))),
          Text(text),
        ],
      ),
    );
  }
}
