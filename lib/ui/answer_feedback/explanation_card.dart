import 'package:flutter/material.dart';

import '../../experience/explanation_parts.dart';
import 'answer_feedback_strings.dart';

/// 解説を「結論／理由／間違えやすい点／別の場面」の型で出すカード。
///
/// 4項目はすべて任意で、無い項目は出さない。既存の1本文の解説は
/// [ExplanationCard.fromPlain] で従来どおり出せる（末尾の `【別の場面】` があれば
/// 「別の場面」欄に分け、分けられなければ全文をそのまま出す）。
/// ラベルは [AnswerFeedbackStrings]（`strings` 省略時は `KitStringsScope` の言語）。
class ExplanationCard extends StatelessWidget {
  const ExplanationCard({
    super.key,
    this.conclusion,
    this.reason,
    this.pitfall,
    this.otherScene,
    this.body,
    this.strings,
  });

  /// 従来の1本文の解説から作る。
  ExplanationCard.fromPlain(
    String text, {
    Key? key,
    AnswerFeedbackStrings? strings,
  }) : this.fromParts(
         ExplanationParts.fromPlain(text),
         key: key,
         strings: strings,
       );

  ExplanationCard.fromParts(ExplanationParts parts, {super.key, this.strings})
    : conclusion = parts.conclusion,
      reason = parts.reason,
      pitfall = parts.pitfall,
      otherScene = parts.otherScene,
      body = parts.body;

  final String? conclusion;
  final String? reason;
  final String? pitfall;
  final String? otherScene;

  /// ラベルなしで先頭に出す本文。
  final String? body;
  final AnswerFeedbackStrings? strings;

  @override
  Widget build(BuildContext context) {
    final parts = ExplanationParts(
      conclusion: conclusion,
      reason: reason,
      pitfall: pitfall,
      otherScene: otherScene,
      body: body,
    );
    if (parts.isEmpty) return const SizedBox.shrink();
    final s = strings ?? AnswerFeedbackStrings.of(context);
    final theme = Theme.of(context);
    final items = <Widget>[
      if (parts.hasBody) Text(parts.body!, style: theme.textTheme.bodyLarge),
      if (parts.hasConclusion)
        _item(theme, Icons.flag_outlined, s.explConclusion, parts.conclusion!),
      if (parts.hasReason)
        _item(theme, Icons.help_outline, s.explReason, parts.reason!),
      if (parts.hasPitfall)
        _item(
          theme,
          Icons.warning_amber_outlined,
          s.explPitfall,
          parts.pitfall!,
        ),
      if (parts.hasOtherScene)
        _item(theme, Icons.swap_horiz, s.explOtherScene, parts.otherScene!),
    ];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              items[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _item(ThemeData theme, IconData icon, String label, String text) {
    return Semantics(
      container: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(text, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
