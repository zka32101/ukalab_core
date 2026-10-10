import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';


/// 予測→実行（型②、決定76）: 先に答えを予測してから、計算結果とのズレを見て
/// 学ぶウィジェット。ukalab_core の `PredictRunScenario` には依存せず、
/// 呼び出し側が `compute()` の結果を詰め替えて渡す（`BoundarySliderWidget`
/// と同じ構成）。
///
/// [min]・[max] は予測スライダーの範囲、[correctAnswer] は実際の計算結果。
/// [valueLabel] を渡さなければ 0〜1 の値をパーセント表示する。
class PredictRunWidget extends StatefulWidget {
  const PredictRunWidget({
    super.key,
    required this.title,
    required this.question,
    required this.correctAnswer,
    required this.explanation,
    this.min = 0,
    this.max = 1,
    this.valueLabel,
  });

  final String title;

  /// 予測を促す問い（例: "陽性なら本当に病気の確率は?"）。
  final String question;

  /// 実際の計算結果。
  final double correctAnswer;

  /// 予測とのズレの解説。
  final String explanation;
  final double min;
  final double max;
  final String Function(double value)? valueLabel;

  @override
  State<PredictRunWidget> createState() => _PredictRunWidgetState();
}

class _PredictRunWidgetState extends State<PredictRunWidget> {
  late double _prediction;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _prediction = (widget.min + widget.max) / 2;
  }

  String _format(double v) => widget.valueLabel?.call(v) ?? '${(v * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(widget.question, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _prediction,
                min: widget.min,
                max: widget.max,
                label: _format(_prediction),
                onChanged: _revealed ? null : (v) => setState(() => _prediction = v),
              ),
            ),
            SizedBox(
              width: 56,
              child: Text(
                _format(_prediction),
                textAlign: TextAlign.end,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!_revealed)
          FilledButton(
            onPressed: () => setState(() => _revealed = true),
            child: Text(LabStrings.of(context).predictButton),
          )
        else
          _PredictRunResult(
            prediction: _prediction,
            correctAnswer: widget.correctAnswer,
            explanation: widget.explanation,
            format: _format,
            onReset: () => setState(() => _revealed = false),
          ),
      ],
    );
  }
}

class _PredictRunResult extends StatelessWidget {
  const _PredictRunResult({
    required this.prediction,
    required this.correctAnswer,
    required this.explanation,
    required this.format,
    required this.onReset,
  });

  final double prediction;
  final double correctAnswer;
  final String explanation;
  final String Function(double) format;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _Stat(label: LabStrings.of(context).predictYours, value: format(prediction), theme: theme),
                ),
                Expanded(
                  child: _Stat(label: LabStrings.of(context).predictCorrect, value: format(correctAnswer), theme: theme),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(explanation, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onReset, child: Text(LabStrings.of(context).predictAgain)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.theme});

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        Text(value, style: theme.textTheme.headlineSmall),
      ],
    );
  }
}
