import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';


/// 今月のAI動向（画期的な機能10、決定41）の1件。
class AiNewsItemSpec {
  const AiNewsItemSpec({
    required this.summary,
    required this.sourceUrl,
    required this.sourceDate,
    required this.syllabusTag,
    required this.asOfDate,
    this.isExamRelevant = false,
  });

  /// 自分の言葉での1〜2文の要約（記事本文・見出しの転載はしない）。
  final String summary;

  final String sourceUrl;
  final DateTime sourceDate;

  /// シラバスの章タグ（表示用の文言。例: "2 人工知能をめぐる動向"）。
  final String syllabusTag;

  /// 「試験に出そう」印。
  final bool isExamRelevant;

  /// 「◯年◯月時点」の表示に使う基準日。
  final DateTime asOfDate;
}

/// 今月のAI動向（画期的な機能10）。ホームのカードに3〜5件表示する。
///
/// 毎週の収集・運営者確認・月次の差分更新はアプリの外（人・定期タスク）で
/// 行う。ここは配信済みのデータを表示するだけ。
class AiNewsCard extends StatelessWidget {
  const AiNewsCard({super.key, required this.items});

  final List<AiNewsItemSpec> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final asOf = items.map((i) => i.asOfDate).reduce((a, b) => a.isAfter(b) ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LabStrings.of(context).aiNewsTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              LabStrings.of(context).aiNewsAsOf(asOf.year, asOf.month),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(height: 24),
              _AiNewsRow(item: items[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _AiNewsRow extends StatelessWidget {
  const _AiNewsRow({required this.item});

  final AiNewsItemSpec item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.isExamRelevant) ...[
              Icon(Icons.flag, size: 16, color: theme.colorScheme.error),
              const SizedBox(width: 4),
            ],
            Expanded(child: Text(item.summary, style: theme.textTheme.bodyMedium)),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Chip(
              label: Text(item.syllabusTag, style: theme.textTheme.labelSmall),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
            if (item.isExamRelevant)
              Chip(
                label: Text(LabStrings.of(context).aiNewsExamLikely),
                labelStyle: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                backgroundColor: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
              ),
          ],
        ),
        const SizedBox(height: 4),
        SelectableText(
          item.sourceUrl,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
        ),
      ],
    );
  }
}
