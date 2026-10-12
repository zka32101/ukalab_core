import 'package:flutter/material.dart';

import 'lab_strings.dart';

import '../stats/exam_stats_models.dart';

/// 模擬試験結果に添える全国集計との比較。集計が無ければ何も表示しない。
class StatsCompareWidget extends StatelessWidget {
  const StatsCompareWidget({
    super.key,
    required this.summary,
    required this.myScore,
  });

  final ExamStatsSummary? summary;
  final int myScore;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    if (s == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final deviation = s.deviationScoreFor(myScore);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LabStrings.of(context).statsTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(LabStrings.of(context).statsAverage(s.averageScore.toStringAsFixed(1), s.sampleCount)),
            Text(LabStrings.of(context).statsMyScore(myScore)),
            if (deviation != null) ...[
              const SizedBox(height: 4),
              Text(
                LabStrings.of(context).statsDeviation(deviation.toStringAsFixed(1)),
                style: theme.textTheme.titleLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
