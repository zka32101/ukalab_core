import 'package:app_common_kit/app_common_kit.dart' show KitStrings;
import 'package:flutter/material.dart';

import '../../progress/review_scheduler_strings.dart';

/// ホームに置く「今日の復習」カード。期限の件数と「やってみる」だけを出す。
///
/// 出題画面は持たない。[onStart] で各アプリの既存クイズ（`ReviewSchedulerEngine.due` の問題ID）に接続する。
/// [dueCount] が 0 以下なら、静かな「おやすみ」表示でボタンは出さない。件数は赤字・警告色にしない。
/// 文言は [strings]、無ければ `KitStringsScope` の言語（ja・en。他は日本語）。
class TodayReviewCard extends StatelessWidget {
  const TodayReviewCard({
    super.key,
    required this.dueCount,
    required this.onStart,
    this.strings,
  });

  final int dueCount;
  final VoidCallback onStart;
  final ReviewSchedulerStrings? strings;

  @override
  Widget build(BuildContext context) {
    final lang = KitStrings.of(context).languageCode;
    final s = strings ?? ReviewSchedulerStrings.forLanguageCode(lang);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final has = dueCount > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(s.title, style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 4),
            Text(
              has ? s.dueText(dueCount) : s.emptyTitle,
              style: theme.textTheme.titleLarge?.copyWith(color: cs.primary),
            ),
            const SizedBox(height: 4),
            Text(has ? s.dueHint : s.emptyBody, style: theme.textTheme.bodyMedium),
            if (has) ...[
              const SizedBox(height: 4),
              Text(
                s.reassure,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Semantics(
                button: true,
                excludeSemantics: true,
                label: s.start,
                hint: s.startHint,
                onTap: onStart,
                child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: onStart,
                  child: Text(s.start),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
