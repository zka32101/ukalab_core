import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'lab_strings.dart';

/// 用語の習得度（決定29の学習ログから計算してアプリ側が渡す）。色だけに頼らず
/// アイコンでも区別する。
enum TermMastery { none, weak, mastered }

/// 用語マップ・AI系譜図（画期的な機能9）のノード1件。
class TermMapNodeSpec {
  const TermMapNodeSpec({
    required this.termId,
    required this.label,
    this.era,
    this.relatedTermIds = const [],
    this.mastery = TermMastery.none,
  });

  final String termId;
  final String label;

  /// 系譜図（タイムライン）側に出す時代区分。null なら用語マップ側のみ。
  final String? era;

  /// 用語マップ側で線を引く相手（存在しない termId は無視される）。
  final List<String> relatedTermIds;

  final TermMastery mastery;
}

/// 用語マップ・AI系譜図（決定41・画期的な機能9）。
///
/// [eraOrder] に挙げた時代区分の用語を時系列の横一列（タイムライン）で、
/// それ以外の用語を関連でつながる地図（円形配置）で表示する。どちらもタップで
/// [onNodeTap] を呼ぶ（用語カードを開くのはアプリ側）。
class TermMapWidget extends StatelessWidget {
  const TermMapWidget({
    super.key,
    required this.nodes,
    required this.eraOrder,
    required this.onNodeTap,
  });

  final List<TermMapNodeSpec> nodes;

  /// 時代区分IDの表示順（先頭が古い時代）。値は表示ラベル。
  final Map<String, String> eraOrder;

  final ValueChanged<String> onNodeTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byEra = <String, List<TermMapNodeSpec>>{};
    final mapNodes = <TermMapNodeSpec>[];
    for (final n in nodes) {
      final era = n.era;
      if (era != null && eraOrder.containsKey(era)) {
        byEra.putIfAbsent(era, () => []).add(n);
      } else {
        mapNodes.add(n);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (byEra.isNotEmpty) ...[
          Text(LabStrings.of(context).termMapHistory, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            LabStrings.of(context).termMapEraNote,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final era in eraOrder.keys)
                  if (byEra[era] != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: _EraGroup(
                        label: eraOrder[era]!,
                        nodes: byEra[era]!,
                        onTap: onNodeTap,
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (mapNodes.isNotEmpty) ...[
          Text(LabStrings.of(context).termMapTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _TermNetwork(nodes: mapNodes, onTap: onNodeTap),
        ],
      ],
    );
  }
}

class _EraGroup extends StatelessWidget {
  const _EraGroup({required this.label, required this.nodes, required this.onTap});

  final String label;
  final List<TermMapNodeSpec> nodes;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
        const SizedBox(height: 8),
        SizedBox(
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final n in nodes) _TermNodeChip(node: n, onTap: onTap),
            ],
          ),
        ),
      ],
    );
  }
}

class _TermNodeChip extends StatelessWidget {
  const _TermNodeChip({required this.node, required this.onTap});

  final TermMapNodeSpec node;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg, icon) = switch (node.mastery) {
      TermMastery.mastered => (
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer,
          Icons.check_circle,
        ),
      TermMastery.weak => (
          theme.colorScheme.errorContainer,
          theme.colorScheme.onErrorContainer,
          Icons.priority_high,
        ),
      TermMastery.none => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
          null,
        ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onTap(node.termId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: fg),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    node.label,
                    style: theme.textTheme.bodySmall?.copyWith(color: fg),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 関連用語でつながるネットワーク。ノードを円周上に配置し、
/// [TermMapNodeSpec.relatedTermIds] に沿って線を引く。
class _TermNetwork extends StatelessWidget {
  const _TermNetwork({required this.nodes, required this.onTap});

  final List<TermMapNodeSpec> nodes;
  final ValueChanged<String> onTap;

  List<Offset> _positions(Size size) {
    final n = nodes.length;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 36;
    if (n == 1) return [center];
    return [
      for (var i = 0; i < n; i++)
        center +
            Offset(
              radius * math.cos(2 * math.pi * i / n - math.pi / 2),
              radius * math.sin(2 * math.pi * i / n - math.pi / 2),
            ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final positions = _positions(size);
          final indexOf = {
            for (var i = 0; i < nodes.length; i++) nodes[i].termId: i,
          };
          return Stack(
            children: [
              CustomPaint(
                size: size,
                painter: _TermEdgesPainter(
                  nodes: nodes,
                  positions: positions,
                  indexOf: indexOf,
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              for (var i = 0; i < nodes.length; i++)
                Positioned(
                  left: positions[i].dx - 40,
                  top: positions[i].dy - 16,
                  width: 80,
                  child: _TermNodeChip(node: nodes[i], onTap: onTap),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TermEdgesPainter extends CustomPainter {
  const _TermEdgesPainter({
    required this.nodes,
    required this.positions,
    required this.indexOf,
    required this.color,
  });

  final List<TermMapNodeSpec> nodes;
  final List<Offset> positions;
  final Map<String, int> indexOf;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (var i = 0; i < nodes.length; i++) {
      for (final relatedId in nodes[i].relatedTermIds) {
        final j = indexOf[relatedId];
        if (j == null || j <= i) continue;
        canvas.drawLine(positions[i], positions[j], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TermEdgesPainter oldDelegate) =>
      oldDelegate.nodes != nodes || oldDelegate.color != color;
}
