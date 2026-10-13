import 'package:flutter/material.dart';

import '../../progress/progress_record.dart';
import 'answer_feedback_strings.dart';

/// 誤答の直後に、間違えた理由（原因ラベル）を自分で選ぶ小さな UI。
///
/// 選ぶのは任意（選ばなくてよい）。選んだラベルをもう一度押すと取り消し、
/// [onSelected] に null を返す。計算を使わない資格では [includeCalculation] を false にして
/// 「計算ミス」を出さない。
class WrongCauseSelector extends StatelessWidget {
  const WrongCauseSelector({
    super.key,
    required this.onSelected,
    this.selected,
    this.includeCalculation = true,
    this.strings,
  });

  /// 選択（または取り消し＝null）のたびに呼ぶ。
  final ValueChanged<WrongCause?> onSelected;

  /// 今選ばれているラベル（親が持つ）。
  final WrongCause? selected;

  /// false なら「計算ミス」を選択肢に出さない。
  final bool includeCalculation;

  /// 文言。省略時は言語に合う内蔵の文言。
  final AnswerFeedbackStrings? strings;

  @override
  Widget build(BuildContext context) {
    final s = strings ?? AnswerFeedbackStrings.of(context);
    final theme = Theme.of(context);
    final causes = [
      for (final c in WrongCause.values)
        if (includeCalculation || c != WrongCause.calculation) c,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.selectorTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(s.selectorHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final c in causes)
              ChoiceChip(
                key: ValueKey('wrong-cause-${c.name}'),
                label: Text(s.causeLabel(c)),
                selected: selected == c,
                onSelected: (_) => onSelected(selected == c ? null : c),
              ),
          ],
        ),
      ],
    );
  }
}
