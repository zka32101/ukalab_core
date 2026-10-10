import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';


import '../outfit/readiness.dart';

/// 「準備完了まで」の進み具合を静かに見せるカード。責める表現は使わない。
class ReadinessProgressCard extends StatelessWidget {
  const ReadinessProgressCard({super.key, required this.progress});

  final ReadinessProgress progress;

  String _message(LabStrings l) {
    if (progress.isReady) return l.readinessReady;
    if (progress.masteryFraction >= 1.0) return l.readinessMasteryDone;
    final left = progress.masteryPercentLeft;
    return progress.mockNeeded ? l.readinessLeftWithMock(left) : l.readinessLeft(left);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LabStrings.of(context).readinessTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.masteryFraction,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 8),
            Text(_message(LabStrings.of(context)), style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
