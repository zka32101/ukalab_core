import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'lab_controls.dart';
import 'lab_strings.dart';

/// 機械学習ラボ（画期的な機能1）のデータ点1件。
class MlLabPointSpec {
  const MlLabPointSpec({required this.x, required this.y, required this.label});

  /// 座標（0〜10の範囲を想定）。
  final double x;
  final double y;

  /// クラス（0 または 1）。
  final int label;
}

enum MlMethod { knn, decisionTree, linear }

/// 機械学習ラボ（画期的な機能1）。
///
/// 体験: [points] を2クラスの点として表示し、k近傍法・決定木・線形分類の
/// 3手法を切り替えながら決定境界（背景の塗り分け）を見る。ハイパーパラメータ
/// （k、深さ、正則化）のスライダーで過学習・未学習を体験する。
/// コード描画のみ（AI呼び出しなし）。
class MlLabWidget extends StatefulWidget {
  const MlLabWidget({
    super.key,
    required this.title,
    required this.description,
    required this.points,
  });

  final String title;
  final String description;
  final List<MlLabPointSpec> points;

  @override
  State<MlLabWidget> createState() => _MlLabWidgetState();
}

class _MlLabWidgetState extends State<MlLabWidget> {
  MlMethod _method = MlMethod.knn;
  int _k = 3;
  int _maxDepth = 3;
  double _regularization = 0.1;

  int Function(double x, double y) _classifierFor(MlMethod method) {
    switch (method) {
      case MlMethod.knn:
        return (x, y) => _classifyKnn(widget.points, _k, x, y);
      case MlMethod.decisionTree:
        final tree = _buildTree(widget.points, _maxDepth, 0);
        return (x, y) => _classifyTree(tree, x, y);
      case MlMethod.linear:
        final (wx, wy, b) = _trainLinear(widget.points, _regularization);
        return (x, y) => (wx * x / 10 + wy * y / 10 + b) >= 0 ? 1 : 0;
    }
  }

  String _hint(LabStrings l) => switch (_method) {
        MlMethod.knn => _k <= 2
            ? l.mlKnnSmallHint
            : _k >= 10
                ? l.mlKnnLargeHint
                : l.mlKnnMidHint,
        MlMethod.decisionTree => _maxDepth <= 1
            ? l.mlTreeShallowHint
            : _maxDepth >= 5
                ? l.mlTreeDeepHint
                : l.mlTreeMidHint,
        MlMethod.linear => _regularization <= 0.05
            ? l.mlLinearWeakHint
            : _regularization >= 1.0
                ? l.mlLinearStrongHint
                : l.mlLinearMidHint,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = LabStrings.of(context);
    final classify = _classifierFor(_method);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(widget.description, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        SegmentedButton<MlMethod>(
          segments: [
            ButtonSegment(value: MlMethod.knn, label: Text(l.mlKnn)),
            ButtonSegment(value: MlMethod.decisionTree, label: Text(l.mlDecisionTree)),
            ButtonSegment(value: MlMethod.linear, label: Text(l.mlLinear)),
          ],
          selected: {_method},
          onSelectionChanged: (s) => setState(() => _method = s.first),
        ),
        const SizedBox(height: 12),
        switch (_method) {
          MlMethod.knn => HyperParamSlider(
              label: 'k',
              value: _k.toDouble(),
              min: 1,
              max: 15,
              divisions: 14,
              labelWidth: 56,
              onChanged: (v) => setState(() => _k = v.round()),
            ),
          MlMethod.decisionTree => HyperParamSlider(
              label: l.mlDepth,
              value: _maxDepth.toDouble(),
              min: 1,
              max: 6,
              divisions: 5,
              labelWidth: 56,
              onChanged: (v) => setState(() => _maxDepth = v.round()),
            ),
          MlMethod.linear => HyperParamSlider(
              label: l.mlRegularization,
              value: _regularization,
              min: 0,
              max: 2,
              divisions: 20,
              valueLabel: _regularization.toStringAsFixed(2),
              labelWidth: 56,
              onChanged: (v) => setState(() => _regularization = v),
            ),
        },
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: _MlLabPainter(points: widget.points, classify: classify, theme: theme),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            LegendMark(color: theme.colorScheme.primary, shape: BoxShape.circle, label: l.class0),
            const SizedBox(width: 16),
            LegendMark(color: theme.colorScheme.error, shape: BoxShape.rectangle, label: l.class1),
          ],
        ),
        const SizedBox(height: 8),
        Text(_hint(l), style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _MlLabPainter extends CustomPainter {
  const _MlLabPainter({required this.points, required this.classify, required this.theme});

  final List<MlLabPointSpec> points;
  final int Function(double x, double y) classify;
  final ThemeData theme;

  static const _gridCells = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final bg0 = theme.colorScheme.primaryContainer;
    final bg1 = theme.colorScheme.errorContainer;
    final cellW = size.width / _gridCells;
    final cellH = size.height / _gridCells;
    for (var row = 0; row < _gridCells; row++) {
      for (var col = 0; col < _gridCells; col++) {
        final x = (col + 0.5) / _gridCells * 10;
        final y = 10 - (row + 0.5) / _gridCells * 10;
        final label = classify(x, y);
        final paint = Paint()..color = label == 1 ? bg1 : bg0;
        canvas.drawRect(
          Rect.fromLTWH(col * cellW, row * cellH, cellW, cellH),
          paint,
        );
      }
    }

    for (final p in points) {
      final dx = p.x / 10 * size.width;
      final dy = (1 - p.y / 10) * size.height;
      final paint = Paint()
        ..color = p.label == 1 ? theme.colorScheme.error : theme.colorScheme.primary;
      if (p.label == 1) {
        final path = Path()
          ..moveTo(dx, dy - 7)
          ..lineTo(dx - 7, dy + 6)
          ..lineTo(dx + 7, dy + 6)
          ..close();
        canvas.drawPath(path, paint);
      } else {
        canvas.drawCircle(Offset(dx, dy), 6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MlLabPainter oldDelegate) => true;
}

int _classifyKnn(List<MlLabPointSpec> points, int k, double x, double y) {
  final sorted = [...points]
    ..sort((a, b) {
      final da = (a.x - x) * (a.x - x) + (a.y - y) * (a.y - y);
      final db = (b.x - x) * (b.x - x) + (b.y - y) * (b.y - y);
      return da.compareTo(db);
    });
  final nearest = sorted.take(math.min(k, sorted.length));
  final ones = nearest.where((p) => p.label == 1).length;
  return ones * 2 >= nearest.length ? 1 : 0;
}

class _TreeNode {
  _TreeNode.leaf(int label)
      : label = label,
        isX = null,
        threshold = null,
        left = null,
        right = null;

  _TreeNode.split(bool isX, double threshold, _TreeNode left, _TreeNode right)
      : label = null,
        isX = isX,
        threshold = threshold,
        left = left,
        right = right;

  final int? label;
  final bool? isX;
  final double? threshold;
  final _TreeNode? left;
  final _TreeNode? right;
}

double _gini(List<MlLabPointSpec> points) {
  if (points.isEmpty) return 0;
  final p1 = points.where((p) => p.label == 1).length / points.length;
  return 1 - p1 * p1 - (1 - p1) * (1 - p1);
}

int _majorityLabel(List<MlLabPointSpec> points) {
  final ones = points.where((p) => p.label == 1).length;
  return ones * 2 >= points.length ? 1 : 0;
}

_TreeNode _buildTree(List<MlLabPointSpec> points, int maxDepth, int depth) {
  final labels = points.map((p) => p.label).toSet();
  if (depth >= maxDepth || labels.length <= 1 || points.length <= 1) {
    return _TreeNode.leaf(_majorityLabel(points));
  }

  var bestGini = double.infinity;
  bool? bestIsX;
  double? bestThreshold;
  for (final isX in [true, false]) {
    final values = points.map((p) => isX ? p.x : p.y).toSet().toList()..sort();
    for (var i = 0; i < values.length - 1; i++) {
      final threshold = (values[i] + values[i + 1]) / 2;
      final left = points.where((p) => (isX ? p.x : p.y) <= threshold).toList();
      final right = points.where((p) => (isX ? p.x : p.y) > threshold).toList();
      if (left.isEmpty || right.isEmpty) continue;
      final weighted =
          (_gini(left) * left.length + _gini(right) * right.length) / points.length;
      if (weighted < bestGini) {
        bestGini = weighted;
        bestIsX = isX;
        bestThreshold = threshold;
      }
    }
  }

  if (bestIsX == null || bestThreshold == null) {
    return _TreeNode.leaf(_majorityLabel(points));
  }
  final left = points.where((p) => (bestIsX! ? p.x : p.y) <= bestThreshold!).toList();
  final right = points.where((p) => (bestIsX! ? p.x : p.y) > bestThreshold!).toList();
  return _TreeNode.split(
    bestIsX,
    bestThreshold,
    _buildTree(left, maxDepth, depth + 1),
    _buildTree(right, maxDepth, depth + 1),
  );
}

int _classifyTree(_TreeNode node, double x, double y) {
  final label = node.label;
  if (label != null) return label;
  final v = node.isX! ? x : y;
  return v <= node.threshold! ? _classifyTree(node.left!, x, y) : _classifyTree(node.right!, x, y);
}

(double, double, double) _trainLinear(List<MlLabPointSpec> points, double regularization) {
  var wx = 0.0, wy = 0.0, b = 0.0;
  const lr = 0.5;
  const epochs = 400;
  final n = points.length;
  if (n == 0) return (wx, wy, b);
  for (var epoch = 0; epoch < epochs; epoch++) {
    var gwx = 0.0, gwy = 0.0, gb = 0.0;
    for (final p in points) {
      final nx = p.x / 10;
      final ny = p.y / 10;
      final z = wx * nx + wy * ny + b;
      final pred = 1 / (1 + math.exp(-z));
      final error = pred - p.label;
      gwx += error * nx;
      gwy += error * ny;
      gb += error;
    }
    wx -= lr * (gwx / n + regularization * wx);
    wy -= lr * (gwy / n + regularization * wy);
    b -= lr * (gb / n);
  }
  return (wx, wy, b);
}
