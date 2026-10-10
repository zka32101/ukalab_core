import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';


/// 境界線スライダー（型①、決定76・77）の二値条件1つ。
///
/// ukalab_core の `BoundaryCondition` と同じ構造を持つ、UI 層の軽量な
/// 写し。アプリ側がデータモデルから詰め替えて渡す（TermCard と同じ構成）。
class BoundaryConditionSpec {
  const BoundaryConditionSpec({
    required this.conditionId,
    required this.label,
    required this.trueLabel,
    required this.falseLabel,
  });

  final String conditionId;
  final String label;
  final String trueLabel;
  final String falseLabel;
}

/// 条件の組み合わせに対する結論の表示内容。
class BoundaryConclusion {
  const BoundaryConclusion({required this.text, required this.lawReference});

  /// 判定結果（例: "対象外（目安）"）。
  final String text;

  /// 根拠条文・資料（例: "著作権法30条の4"）。
  final String lawReference;
}

/// 条件を1つずつ切り替え、判定が切り替わる「境目」を体験するウィジェット
/// （決定76「条件を1つずつ動かし、判定(許可/届出/違法/区分)が切り替わる
/// 「ちょうど境目」を体験」）。
///
/// 判定はアプリ側のルール表評価を [evaluate] コールバックに渡すだけで、
/// このウィジェット自体はルール表を持たない。判定結果は参考用の「目安」
/// であり法的な助言ではないことを常に明示する（決定77）。
class BoundarySliderWidget extends StatefulWidget {
  const BoundarySliderWidget({
    super.key,
    required this.title,
    required this.conditions,
    required this.evaluate,
    this.initialValues = const {},
  });

  final String title;
  final List<BoundaryConditionSpec> conditions;

  /// 全条件の現在値（conditionId → true/false）から結論を得る。
  /// マッチする結論がなければ null（ルール表の不備として空欄表示にする）。
  final BoundaryConclusion? Function(Map<String, bool> values) evaluate;

  /// 条件の初期値。指定のない条件は false から始まる。
  final Map<String, bool> initialValues;

  @override
  State<BoundarySliderWidget> createState() => _BoundarySliderWidgetState();
}

class _BoundarySliderWidgetState extends State<BoundarySliderWidget> {
  late Map<String, bool> _values;

  @override
  void initState() {
    super.initState();
    _values = {
      for (final c in widget.conditions) c.conditionId: widget.initialValues[c.conditionId] ?? false,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conclusion = widget.evaluate(_values);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final c in widget.conditions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _BoundaryConditionRow(
              condition: c,
              value: _values[c.conditionId]!,
              onChanged: (v) => setState(() => _values[c.conditionId] = v),
            ),
          ),
        const SizedBox(height: 12),
        _BoundaryConclusionCard(conclusion: conclusion),
        const SizedBox(height: 8),
        Text(
          LabStrings.of(context).boundaryDisclaimer,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
        ),
      ],
    );
  }
}

class _BoundaryConditionRow extends StatelessWidget {
  const _BoundaryConditionRow({
    required this.condition,
    required this.value,
    required this.onChanged,
  });

  final BoundaryConditionSpec condition;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(condition.label, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      value ? condition.trueLabel : condition.falseLabel,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoundaryConclusionCard extends StatelessWidget {
  const _BoundaryConclusionCard({required this.conclusion});

  final BoundaryConclusion? conclusion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conclusion = this.conclusion;
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: conclusion == null
            ? Text(LabStrings.of(context).boundaryUnset, style: theme.textTheme.bodyMedium)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(conclusion.text, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    LabStrings.of(context).boundaryBasis(conclusion.lawReference),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
      ),
    );
  }
}
