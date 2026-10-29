import 'package:flutter/material.dart';

import '../../experience/chapter_reading.dart';
import 'answer_feedback_strings.dart';

/// 誤答後の「読み物でおさらい」だけを出すカード（原因選択欄などは含まない）。
///
/// 独自の結果表示を持つアプリ向け。[isCorrect] が true、[onOpenReading] が null、
/// 表示できる読み物（`disabled` 除く）が無いときは何も出さない。
/// 読み物は `readingsForQuestion` / `readingsForLevel` で絞って渡せる。
class RelatedReadingsCard extends StatelessWidget {
  const RelatedReadingsCard({
    super.key,
    required this.readings,
    required this.onOpenReading,
    this.isCorrect = false,
    this.strings,
  });

  final List<ChapterReading> readings;
  final ValueChanged<ChapterReading>? onOpenReading;

  /// 正解のとき true（何も出さない）。既定は false（誤答として出す）。
  final bool isCorrect;
  final AnswerFeedbackStrings? strings;

  @override
  Widget build(BuildContext context) {
    final onOpen = onOpenReading;
    final shown = [
      for (final r in readings)
        if (!r.disabled) r,
    ];
    if (isCorrect || onOpen == null || shown.isEmpty) {
      return const SizedBox.shrink();
    }
    final s = strings ?? AnswerFeedbackStrings.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.relatedReadingsTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final r in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: OutlinedButton(
                  onPressed: () => onOpen(r),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(r.title),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
