import 'package:flutter/material.dart';

/// 模擬試験1回分の結果（成長グラフ表示用）。
class MockExamTrendPoint {
  const MockExamTrendPoint({required this.pct, required this.passed});

  /// 得点率（%）。
  final double pct;
  final bool passed;
}

/// 模擬試験の成長グラフ（複数回分の得点率の推移）。プレミアム機能。
/// 2回未満では何も表示しない。直近10回分までを表示する。
class MockExamTrendChart extends StatelessWidget {
  const MockExamTrendChart({
    super.key,
    required this.points,
    this.passPct,
  });

  final List<MockExamTrendPoint> points;

  /// 合格ライン（%）。渡すと目安の横線を引く。
  final double? passPct;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final shown = points.length > 10 ? points.sublist(points.length - 10) : points;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 140.0;
        const maxPct = 100.0;
        final stepX = shown.length > 1 ? width / (shown.length - 1) : width;
        final offsets = [
          for (var i = 0; i < shown.length; i++)
            Offset(stepX * i, height - (shown[i].pct / maxPct) * height),
        ];
        return SizedBox(
          height: height + 24,
          width: width,
          child: CustomPaint(
            painter: _TrendPainter(
              offsets: offsets,
              passPct: passPct,
              height: height,
              lineColor: theme.colorScheme.primary,
              passColor: theme.colorScheme.error,
              passed: [for (final p in shown) p.passed],
            ),
            child: Semantics(
              label: '模擬試験の成長グラフ。直近${shown.length}回、得点率'
                  '${shown.map((p) => p.pct.round()).join('、')}パーセント。',
            ),
          ),
        );
      },
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.offsets,
    required this.passPct,
    required this.height,
    required this.lineColor,
    required this.passColor,
    required this.passed,
  });

  final List<Offset> offsets;
  final double? passPct;
  final double height;
  final Color lineColor;
  final Color passColor;
  final List<bool> passed;

  @override
  void paint(Canvas canvas, Size size) {
    if (passPct != null) {
      final y = height - (passPct! / 100) * height;
      final dashPaint = Paint()
        ..color = passColor.withValues(alpha: 0.6)
        ..strokeWidth = 1;
      const dashWidth = 6.0;
      var x = 0.0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), dashPaint);
        x += dashWidth * 2;
      }
    }

    if (offsets.length > 1) {
      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (final p in offsets.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    for (var i = 0; i < offsets.length; i++) {
      final dotPaint = Paint()..color = passed[i] ? lineColor : passColor;
      canvas.drawCircle(offsets[i], 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.offsets != offsets || oldDelegate.passPct != passPct;
}
