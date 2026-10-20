import 'package:flutter/material.dart';

import 'package:app_common_kit/app_common_kit.dart' show KitStrings;

/// 連続学習日数。罰を感じさせない表現（0日でも責めない）。
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.days, this.zeroText});

  final int days;
  /// null なら [KitStrings] の既定文言。
  final String? zeroText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = KitStrings.of(context);
    final zero = zeroText ?? strings.streakZero;
    final text = days <= 0 ? zero : strings.streakDays(days);
    return Semantics(
      label: days <= 0 ? zero : strings.streakSemantics(days),
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Flexible(child: Text(text, style: theme.textTheme.labelLarge)),
          ],
        ),
      ),
    );
  }
}
