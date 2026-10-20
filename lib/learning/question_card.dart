import 'package:flutter/material.dart';

import 'package:app_common_kit/app_common_kit.dart' show KitStrings;

/// 問題文のカード。「第3問 / 10問」の進行表示つき。選択肢は [child] に並べる。
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.text,
    this.index,
    this.total,
    this.child,
    this.textWidget,
  });

  final String text;

  /// 1始まりの問題番号。
  final int? index;
  final int? total;
  final Widget? child;

  /// 問題文の表示を差し替える（例: [TappableTermText] で用語をタップ可能にする）。
  /// 指定しなければ [text] をそのまま表示する。
  final Widget? textWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  total == null
                      ? KitStrings.of(context).questionNo(index!)
                      : KitStrings.of(context).questionNoOfTotal(index!, total!),
                  style: theme.textTheme.labelMedium,
                ),
              ),
            DefaultTextStyle.merge(
              style: theme.textTheme.bodyLarge,
              child: textWidget ?? Text(text, style: theme.textTheme.bodyLarge),
            ),
            if (child != null) ...[const SizedBox(height: 16), child!],
          ],
        ),
      ),
    );
  }
}
