import 'package:app_common_kit/app_common_kit.dart' show KitStrings;
import 'package:flutter/material.dart';

import '../../oshi/weekly_recap_engine.dart';
import '../../oshi/weekly_recap_strings.dart';

/// 週間ふりかえりカード。解いた問題・学習した日・続いた日・メダル・よく解いた/伸びた分野を見せる。
///
/// 前週との比較は出さない。解いていない週は [WeeklyRecapStrings.emptyTitle] の穏やかな表示。
/// [message] に `OshiMessageBubble` などを渡すと、カード下部に推しのひとことを置ける。
/// 文言は [strings]、無ければ `KitStringsScope` の言語（ja・en。他は日本語）。
/// 将来の共有用カード（`WeeklyRecapShareCard`）は、同じ [WeeklyRecap] を受け取る別ウィジェットとして足す。
class WeeklyRecapCard extends StatelessWidget {
  const WeeklyRecapCard({
    super.key,
    required this.recap,
    this.strings,
    this.message,
    this.topicLabel,
  });

  final WeeklyRecap recap;
  final WeeklyRecapStrings? strings;

  /// 推しのひとことなど。null なら出さない。
  final Widget? message;

  /// 分野IDの表示名。省略時はIDをそのまま出す。
  final String Function(String topicId)? topicLabel;

  /// 読み上げ用の要約。
  static String summaryOf(
    WeeklyRecap r,
    WeeklyRecapStrings s, {
    String Function(String topicId)? topicLabel,
  }) {
    final label = topicLabel ?? (String id) => id;
    if (r.isEmpty) return '${s.title}。${s.emptyTitle}。${s.emptyBody}';
    final parts = <String>[
      s.title,
      '${s.answeredLabel} ${r.answered}${s.questionsUnit}',
      '${s.studyDaysLabel} ${r.studyDays}${s.daysUnit}',
      if (r.streakDays >= 2) '${s.streakLabel} ${r.streakDays}${s.daysUnit}',
      if (r.medalsEarned > 0) '${s.medalsLabel} ${r.medalsEarned}${s.medalsUnit}',
      if (r.topTopics.isNotEmpty)
        '${s.topTopicsLabel} ${r.topTopics.map((t) => label(t.topicId)).join(', ')}',
      if (r.improvedTopics.isNotEmpty)
        '${s.improvedLabel} ${r.improvedTopics.map(label).join(', ')}',
    ];
    return parts.join('。');
  }

  @override
  Widget build(BuildContext context) {
    final s = strings ?? WeeklyRecapStrings.forLanguageCode(KitStrings.of(context).languageCode);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final label = topicLabel ?? (String id) => id;

    final body = recap.isEmpty
        ? [
            Text(s.emptyTitle, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(s.emptyBody, style: textTheme.bodyMedium),
          ]
        : [
            _Stat(label: s.answeredLabel, value: '${recap.answered}${s.questionsUnit}'),
            _Stat(label: s.studyDaysLabel, value: '${recap.studyDays}${s.daysUnit}'),
            if (recap.streakDays >= 2)
              _Stat(label: s.streakLabel, value: '${recap.streakDays}${s.daysUnit}'),
            if (recap.medalsEarned > 0)
              _Stat(label: s.medalsLabel, value: '${recap.medalsEarned}${s.medalsUnit}'),
            if (recap.topTopics.isNotEmpty)
              _Topics(label: s.topTopicsLabel, names: [for (final t in recap.topTopics) label(t.topicId)]),
            if (recap.improvedTopics.isNotEmpty)
              _Topics(label: s.improvedLabel, names: recap.improvedTopics.map(label).toList()),
          ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? 1 : 0, end: 1),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 300),
      builder: (context, v, child) => Opacity(opacity: v, child: child),
      child: Card(
        color: scheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                container: true,
                label: summaryOf(recap, s, topicLabel: topicLabel),
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title, style: textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ...body,
                  ],
                ),
              ),
              if (message != null) ...[const SizedBox(height: 12), message!],
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: t.bodyMedium)),
          Text(value, style: t.titleMedium),
        ],
      ),
    );
  }
}

class _Topics extends StatelessWidget {
  const _Topics({required this.label, required this.names});

  final String label;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.bodySmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [for (final n in names) Chip(label: Text(n))],
          ),
        ],
      ),
    );
  }
}
