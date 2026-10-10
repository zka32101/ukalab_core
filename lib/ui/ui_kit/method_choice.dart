import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';


import 'failure_gallery.dart' show FailureChoiceSpec;

/// 手法の選び方（事例仕分け、画期的な機能6）の1場面。
class MethodChoiceScenarioSpec {
  const MethodChoiceScenarioSpec({
    required this.title,
    required this.caseDescription,
    required this.options,
    required this.explanation,
  });

  final String title;
  final String caseDescription;

  /// 手法・モデル・評価指標の選択肢。ちょうど1つが正解。
  final List<FailureChoiceSpec> options;
  final String explanation;
}

/// 手法の選び方（事例仕分け、画期的な機能6）。
///
/// 体験: [MethodChoiceScenarioSpec.caseDescription] の事例に対して、適切な
/// 手法・モデル・評価指標を[MethodChoiceScenarioSpec.options]から選ぶ→
/// 正解すると[MethodChoiceScenarioSpec.explanation]で理由を見る。
/// コード描画のみ（AI呼び出しなし）。
class MethodChoiceWidget extends StatefulWidget {
  const MethodChoiceWidget({super.key, required this.scenario});

  final MethodChoiceScenarioSpec scenario;

  @override
  State<MethodChoiceWidget> createState() => _MethodChoiceWidgetState();
}

class _MethodChoiceWidgetState extends State<MethodChoiceWidget> {
  String? _wrongOptionId;
  bool _done = false;

  void _select(FailureChoiceSpec o) {
    setState(() {
      if (o.isCorrect) {
        _done = true;
        _wrongOptionId = null;
      } else {
        _wrongOptionId = o.optionId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.scenario;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(s.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(s.caseDescription, style: theme.textTheme.bodyLarge),
          ),
        ),
        const SizedBox(height: 12),
        if (!_done) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in s.options)
                ChoiceChip(
                  label: Text(o.text),
                  selected: o.optionId == _wrongOptionId,
                  onSelected: (_) => _select(o),
                ),
            ],
          ),
          if (_wrongOptionId != null) ...[
            const SizedBox(height: 8),
            Text(
              LabStrings.of(context).wrongTryAgain,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ],
        ] else
          Card(
            margin: EdgeInsets.zero,
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LabStrings.of(context).gotIt,
                    style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(s.explanation, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
