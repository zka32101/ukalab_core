import 'dart:math' as math;

import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';


/// 画像認識の中身を見る（画期的な機能4）の1画像。
class ConvLabImageSpec {
  const ConvLabImageSpec({
    required this.title,
    required this.description,
    required this.grid,
  });

  final String title;
  final String description;

  /// 手書き風の数字・図形を表すグレースケールの格子（0.0〜1.0）。
  final List<List<double>> grid;
}

enum ConvFilter { verticalEdge, horizontalEdge, blur, sharpen }

const Map<ConvFilter, List<List<double>>> _kernels = {
  ConvFilter.verticalEdge: [
    [-1, 0, 1],
    [-2, 0, 2],
    [-1, 0, 1],
  ],
  ConvFilter.horizontalEdge: [
    [-1, -2, -1],
    [0, 0, 0],
    [1, 2, 1],
  ],
  ConvFilter.blur: [
    [1 / 9, 1 / 9, 1 / 9],
    [1 / 9, 1 / 9, 1 / 9],
    [1 / 9, 1 / 9, 1 / 9],
  ],
  ConvFilter.sharpen: [
    [0, -1, 0],
    [-1, 5, -1],
    [0, -1, 0],
  ],
};

String _filterLabel(LabStrings l, ConvFilter f) => switch (f) {
      ConvFilter.verticalEdge => l.convVerticalEdge,
      ConvFilter.horizontalEdge => l.convHorizontalEdge,
      ConvFilter.blur => l.convBlur,
      ConvFilter.sharpen => l.convSharpen,
    };

String _filterHint(LabStrings l, ConvFilter f) => switch (f) {
      ConvFilter.verticalEdge => l.convVerticalEdgeHint,
      ConvFilter.horizontalEdge => l.convHorizontalEdgeHint,
      ConvFilter.blur => l.convBlurHint,
      ConvFilter.sharpen => l.convSharpenHint,
    };

/// 画像認識の中身を見る（画期的な機能4）。
///
/// 体験: [image] に畳み込みフィルタ（エッジ検出など）を当て、特徴マップの
/// 変化を見る。プーリング（2x2 max pooling）での縮小も段階表示する。
/// 畳み込み・プーリングの計算自体はこのウィジェットで行う（AI呼び出しなし、
/// コード描画のみ）。
class ConvLabWidget extends StatefulWidget {
  const ConvLabWidget({super.key, required this.image});

  final ConvLabImageSpec image;

  @override
  State<ConvLabWidget> createState() => _ConvLabWidgetState();
}

class _ConvLabWidgetState extends State<ConvLabWidget> {
  ConvFilter _filter = ConvFilter.verticalEdge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = LabStrings.of(context);
    final grid = widget.image.grid;
    final featureMap = _convolve(grid, _kernels[_filter]!);
    final pooled = _maxPool2x2(featureMap);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.image.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(widget.image.description, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        SegmentedButton<ConvFilter>(
          segments: [
            for (final f in ConvFilter.values)
              ButtonSegment(value: f, label: Text(_filterLabel(l, f))),
          ],
          selected: {_filter},
          onSelectionChanged: (s) => setState(() => _filter = s.first),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _Stage(label: l.convInput, grid: grid, normalize: false)),
            const SizedBox(width: 8),
            Expanded(child: _Stage(label: l.convFeatureMap, grid: featureMap, normalize: true)),
            const SizedBox(width: 8),
            Expanded(child: _Stage(label: l.convPooled, grid: pooled, normalize: true)),
          ],
        ),
        const SizedBox(height: 8),
        Text(_filterHint(l, _filter), style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          l.convPoolingNote,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.label, required this.grid, required this.normalize});

  final String label;
  final List<List<double>> grid;

  /// true なら最小〜最大を0.0〜1.0に正規化して表示する（特徴マップ用）。
  /// false ならそのままの値をグレースケールとして表示する（入力画像用）。
  final bool normalize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(painter: _GridPainter(grid: grid, normalize: normalize)),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.grid, required this.normalize});

  final List<List<double>> grid;
  final bool normalize;

  @override
  void paint(Canvas canvas, Size size) {
    final rows = grid.length;
    final cols = grid.first.length;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    var minV = double.infinity, maxV = -double.infinity;
    if (normalize) {
      for (final row in grid) {
        for (final v in row) {
          if (v < minV) minV = v;
          if (v > maxV) maxV = v;
        }
      }
    }

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final raw = grid[r][c];
        final gray = normalize
            ? (maxV > minV ? (raw - minV) / (maxV - minV) : 0.5)
            : raw.clamp(0.0, 1.0);
        final channel = (gray.clamp(0.0, 1.0) * 255).round();
        final paint = Paint()..color = Color.fromRGBO(channel, channel, channel, 1);
        canvas.drawRect(Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => true;
}

/// 3x3カーネルの畳み込み（ゼロパディングで入力と同じ大きさを保つ）。
List<List<double>> _convolve(List<List<double>> grid, List<List<double>> kernel) {
  final rows = grid.length;
  final cols = grid.first.length;
  return List.generate(rows, (r) {
    return List.generate(cols, (c) {
      var sum = 0.0;
      for (var kr = -1; kr <= 1; kr++) {
        for (var kc = -1; kc <= 1; kc++) {
          final rr = r + kr;
          final cc = c + kc;
          final v = (rr >= 0 && rr < rows && cc >= 0 && cc < cols) ? grid[rr][cc] : 0.0;
          sum += v * kernel[kr + 1][kc + 1];
        }
      }
      return sum;
    });
  });
}

/// 2x2 max pooling（ストライド2）。奇数サイズの端は切り捨てる。
List<List<double>> _maxPool2x2(List<List<double>> grid) {
  final rows = grid.length ~/ 2;
  final cols = grid.first.length ~/ 2;
  return List.generate(rows, (r) {
    return List.generate(cols, (c) {
      final a = grid[r * 2][c * 2];
      final b = grid[r * 2][c * 2 + 1];
      final cc = grid[r * 2 + 1][c * 2];
      final d = grid[r * 2 + 1][c * 2 + 1];
      return [a, b, cc, d].reduce(math.max);
    });
  });
}
