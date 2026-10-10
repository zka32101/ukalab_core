import 'dart:math' as math;

import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';


/// Transformerの注意の可視化（画期的な機能5）の1場面。
class AttentionVizSpec {
  const AttentionVizSpec({
    required this.title,
    required this.description,
    required this.tokens,
    required this.attention,
  });

  final String title;
  final String description;

  /// 文を分割した単語（トークン）。
  final List<String> tokens;

  /// `attention[i][j]`: トークンi（クエリ）がトークンj（キー）に向ける
  /// 注意の強さ（0.0〜1.0）。教育用に用意した固定データ。
  final List<List<double>> attention;
}

/// Transformerの注意の可視化（画期的な機能5）。
///
/// 体験: 注目する単語（クエリ）を選び、他の単語への注意（Attention）の
/// 強さを線の太さ・濃さで見る。値は教育用に用意した固定データで、実際の
/// モデルの出力ではない（画面上に明記する）。コード描画のみ（AI呼び出し
/// なし）。
class AttentionVizWidget extends StatefulWidget {
  const AttentionVizWidget({super.key, required this.scenario});

  final AttentionVizSpec scenario;

  @override
  State<AttentionVizWidget> createState() => _AttentionVizWidgetState();
}

class _AttentionVizWidgetState extends State<AttentionVizWidget> {
  int _query = 0;

  @override
  void didUpdateWidget(AttentionVizWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_query >= widget.scenario.tokens.length) {
      _query = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = widget.scenario.tokens;
    final weights = widget.scenario.attention[_query];

    final ranked = [for (var i = 0; i < tokens.length; i++) i]
      ..sort((a, b) => weights[b].compareTo(weights[a]));
    final topKey = ranked.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.scenario.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(widget.scenario.description, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          LabStrings.of(context).attentionNote,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 12),
        Text(LabStrings.of(context).attentionPickQuery, style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < tokens.length; i++)
              ChoiceChip(
                label: Text(tokens[i]),
                selected: _query == i,
                onSelected: (_) => setState(() => _query = i),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          width: double.infinity,
          child: CustomPaint(
            size: Size.infinite,
            painter: _AttentionPainter(
              tokens: tokens,
              weights: weights,
              query: _query,
              topKey: topKey,
              theme: theme,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          LabStrings.of(context).attentionSummary(
            tokens[_query],
            tokens[topKey],
            (weights[topKey] * 100).round(),
          ),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _AttentionPainter extends CustomPainter {
  const _AttentionPainter({
    required this.tokens,
    required this.weights,
    required this.query,
    required this.topKey,
    required this.theme,
  });

  final List<String> tokens;
  final List<double> weights;
  final int query;
  final int topKey;
  final ThemeData theme;

  static const _boxHeight = 32.0;
  static const _topY = 36.0;

  @override
  void paint(Canvas canvas, Size size) {
    final n = tokens.length;
    final slotW = size.width / n;
    final bottomY = size.height - _topY;
    final xs = [for (var i = 0; i < n; i++) (i + 0.5) * slotW];

    for (var j = 0; j < n; j++) {
      final w = weights[j];
      final paint = Paint()
        ..color = theme.colorScheme.primary.withValues(alpha: 0.15 + w * 0.7)
        ..strokeWidth = 1 + w * 10
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(xs[query], _topY + _boxHeight / 2),
        Offset(xs[j], bottomY - _boxHeight / 2),
        paint,
      );
    }

    for (var i = 0; i < n; i++) {
      _drawToken(canvas, xs[i], _topY, tokens[i], isSelected: i == query, isTop: true);
      _drawToken(canvas, xs[i], bottomY, tokens[i], isSelected: i == topKey, isTop: false);
    }
  }

  void _drawToken(
    Canvas canvas,
    double x,
    double y,
    String text, {
    required bool isSelected,
    required bool isTop,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final boxW = tp.width + 20;
    final rect = Rect.fromCenter(center: Offset(x, y), width: boxW, height: _boxHeight);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    final fillPaint = Paint()
      ..color = isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest;
    canvas.drawRRect(rrect, fillPaint);

    if (isSelected) {
      final borderPaint = Paint()
        ..color = theme.colorScheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(rrect, borderPaint);
    }

    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));

    if (isSelected) {
      final markerPaint = Paint()..color = theme.colorScheme.primary;
      if (isTop) {
        final path = Path()
          ..moveTo(x - 6, y - _boxHeight / 2 - 10)
          ..lineTo(x + 6, y - _boxHeight / 2 - 10)
          ..lineTo(x, y - _boxHeight / 2 - 2)
          ..close();
        canvas.drawPath(path, markerPaint);
      } else {
        _drawStar(canvas, Offset(x, y + _boxHeight / 2 + 10), 6, markerPaint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / 5;
      final outer = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      final innerAngle = angle + math.pi / 5;
      final inner = Offset(
        center.dx + (r / 2) * math.cos(innerAngle),
        center.dy + (r / 2) * math.sin(innerAngle),
      );
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AttentionPainter oldDelegate) => true;
}
