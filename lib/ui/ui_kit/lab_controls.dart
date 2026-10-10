import 'package:flutter/material.dart';

/// ハイパーパラメータ用のスライダー（ラベル＋スライダー＋現在値）。
/// 機械学習ラボ・ニューラルネット組み立てなど、ラボ系ウィジェットで共用する。
class HyperParamSlider extends StatelessWidget {
  const HyperParamSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.valueLabel,
    this.labelWidth = 64,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String? valueLabel;
  final ValueChanged<double> onChanged;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final text = valueLabel ?? value.round().toString();
    return Row(
      children: [
        SizedBox(width: labelWidth, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: text,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 40, child: Text(text, textAlign: TextAlign.end)),
      ],
    );
  }
}

/// 凡例（色付きマーク＋ラベル）。ラボ系ウィジェットで共用する。
class LegendMark extends StatelessWidget {
  const LegendMark({super.key, required this.color, required this.shape, required this.label});

  final Color color;
  final BoxShape shape;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: shape)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
