import 'package:flutter/material.dart';

import '../../experience/comparison_view.dart';
import 'answer_feedback_strings.dart';

/// 違いの比較表示（[ComparisonView]）の画面。答えの用語を先に、紛らわしい用語を後に並べ、
/// 1つずつ「ひとことで言うと／よくある間違い・違い」を見せる。色だけに頼らず、
/// 「答え」「紛らわしい用語」のラベルを付ける。
class ComparisonCard extends StatelessWidget {
  const ComparisonCard({super.key, required this.view, this.strings});

  final ComparisonView view;
  final AnswerFeedbackStrings? strings;

  @override
  Widget build(BuildContext context) {
    final s = strings ?? AnswerFeedbackStrings.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.comparisonTitle, style: theme.textTheme.titleSmall),
            for (final row in view.rows) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    row.isAnswer ? Icons.check_circle_outline : Icons.compare_arrows,
                    size: 18,
                    color: row.isAnswer
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      row.term.term,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    row.isAnswer ? s.comparisonAnswer : s.comparisonOther,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Text(row.differenceLine, style: theme.textTheme.bodyMedium),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
