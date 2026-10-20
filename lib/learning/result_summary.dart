import 'package:flutter/material.dart';

import 'package:app_common_kit/app_common_kit.dart' show KitStrings, ProgressRing;

/// 結果画面。得点と合格ラインを数字で示し、合否は✓／文言でも伝える。
class ResultSummary extends StatelessWidget {
  const ResultSummary({
    super.key,
    required this.correct,
    required this.total,
    this.passRatio,
    this.passedText,
    this.notPassedText,
    this.onRetry,
    this.retryLabel,
    this.onClose,
    this.closeLabel,
  });

  final int correct;
  final int total;

  /// 合格ライン（0〜1）。null なら合否表示なし。
  final double? passRatio;
  /// 文言は null なら [KitStrings] の既定。
  final String? passedText;
  final String? notPassedText;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final VoidCallback? onClose;
  final String? closeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = KitStrings.of(context);
    final ratio = total <= 0 ? 0.0 : correct / total;
    final line = passRatio;
    final passed = line != null && ratio >= line;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProgressRing(value: ratio, size: 128, label: strings.accuracy),
        const SizedBox(height: 16),
        Text(strings.correctOfTotal(correct, total), style: theme.textTheme.titleMedium),
        if (line != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(passed ? Icons.check_circle : Icons.flag_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Flexible(child: Text(passed ? (passedText ?? strings.passLineReached) : (notPassedText ?? strings.passLineNotYet), style: theme.textTheme.bodyMedium)),
            ],
          ),
          Text(strings.passLine((line * 100).round()), style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 24),
        if (onRetry != null) FilledButton(onPressed: onRetry, child: Text(retryLabel ?? strings.again)),
        if (onClose != null) ...[
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onClose, child: Text(closeLabel ?? strings.close)),
        ],
      ],
    );
  }
}
