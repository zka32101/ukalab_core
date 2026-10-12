import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'lab_controls.dart';
import 'lab_strings.dart';

/// ニューラルネット組み立て（画期的な機能2）のデータ点1件。
class NnBuilderPointSpec {
  const NnBuilderPointSpec({required this.x, required this.y, required this.label});

  /// 座標（0〜10の範囲を想定）。
  final double x;
  final double y;

  /// クラス（0 または 1）。
  final int label;
}

enum NnActivation { sigmoid, relu, tanh }

/// ニューラルネット組み立て（画期的な機能2）。
///
/// 体験: 隠れ層の数・ユニット数・活性化関数・学習率を選び、[points]を
/// 分類する小さな全結合ニューラルネットを実際に学習させて、決定境界と
/// 学習曲線（訓練誤差）の変化を見る。順伝播・逆伝播（誤差逆伝播法）の
/// 計算はこのウィジェット内で行う（AI呼び出しなし、コード描画のみ）。
class NnBuilderWidget extends StatefulWidget {
  const NnBuilderWidget({
    super.key,
    required this.title,
    required this.description,
    required this.points,
  });

  final String title;
  final String description;
  final List<NnBuilderPointSpec> points;

  @override
  State<NnBuilderWidget> createState() => _NnBuilderWidgetState();
}

class _NnBuilderWidgetState extends State<NnBuilderWidget> {
  int _hiddenLayers = 1;
  int _units = 4;
  NnActivation _activation = NnActivation.relu;
  double _learningRate = 1.0;

  static const _epochs = 400;

  String _hint(LabStrings l) {
    if (_units <= 2) return l.nnFewUnitsHint;
    if (_units >= 7) return l.nnManyUnitsHint;
    if (_learningRate >= 2.5) return l.nnHighRateHint;
    if (_learningRate <= 0.2) return l.nnLowRateHint;
    return l.nnMidHint;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = LabStrings.of(context);
    final layerSizes = [
      2,
      for (var i = 0; i < _hiddenLayers; i++) _units,
      1,
    ];
    final net = _Mlp(layerSizes, _activation, math.Random(42));
    final lossHistory = <double>[];
    for (var e = 0; e < _epochs; e++) {
      lossHistory.add(net.trainEpoch(widget.points, _learningRate));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(widget.description, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        Text(l.nnHiddenLayers, style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 1, label: Text(l.nnLayerCount(1))),
            ButtonSegment(value: 2, label: Text(l.nnLayerCount(2))),
          ],
          selected: {_hiddenLayers},
          onSelectionChanged: (s) => setState(() => _hiddenLayers = s.first),
        ),
        const SizedBox(height: 12),
        HyperParamSlider(
          label: l.nnUnits,
          value: _units.toDouble(),
          min: 2,
          max: 8,
          divisions: 6,
          onChanged: (v) => setState(() => _units = v.round()),
        ),
        const SizedBox(height: 8),
        Text(l.nnActivation, style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        SegmentedButton<NnActivation>(
          segments: [
            ButtonSegment(value: NnActivation.sigmoid, label: Text(l.nnSigmoid)),
            const ButtonSegment(value: NnActivation.relu, label: Text('ReLU')),
            const ButtonSegment(value: NnActivation.tanh, label: Text('tanh')),
          ],
          selected: {_activation},
          onSelectionChanged: (s) => setState(() => _activation = s.first),
        ),
        const SizedBox(height: 12),
        HyperParamSlider(
          label: l.nnLearningRate,
          value: _learningRate,
          min: 0.1,
          max: 3.0,
          divisions: 29,
          valueLabel: _learningRate.toStringAsFixed(1),
          onChanged: (v) => setState(() => _learningRate = v),
        ),
        const SizedBox(height: 16),
        Text(l.nnBoundary, style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: _BoundaryPainter(points: widget.points, net: net, theme: theme),
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
        const SizedBox(height: 16),
        Text(l.nnLossCurve, style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          width: double.infinity,
          child: CustomPaint(painter: _LossCurvePainter(lossHistory: lossHistory, theme: theme)),
        ),
        const SizedBox(height: 4),
        Text(
          l.nnLossSummary(
            lossHistory.first.toStringAsFixed(3),
            lossHistory.last.toStringAsFixed(3),
            _epochs,
          ),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(_hint(l), style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _BoundaryPainter extends CustomPainter {
  const _BoundaryPainter({required this.points, required this.net, required this.theme});

  final List<NnBuilderPointSpec> points;
  final _Mlp net;
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
        final p = net.predict(x, y);
        final paint = Paint()..color = p >= 0.5 ? bg1 : bg0;
        canvas.drawRect(Rect.fromLTWH(col * cellW, row * cellH, cellW, cellH), paint);
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
  bool shouldRepaint(covariant _BoundaryPainter oldDelegate) => true;
}

class _LossCurvePainter extends CustomPainter {
  const _LossCurvePainter({required this.lossHistory, required this.theme});

  final List<double> lossHistory;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final maxLoss = lossHistory.reduce(math.max);
    final minLoss = lossHistory.reduce(math.min);
    final range = (maxLoss - minLoss).abs() < 1e-9 ? 1.0 : maxLoss - minLoss;

    final path = Path();
    for (var i = 0; i < lossHistory.length; i++) {
      final x = i / (lossHistory.length - 1) * size.width;
      final y = size.height - ((lossHistory[i] - minLoss) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LossCurvePainter oldDelegate) => true;
}

/// 小さな全結合ニューラルネット（隠れ層は[activation]、出力層はシグモイド・
/// 二値分類）。順伝播・誤差逆伝播法による学習をこのクラス内で行う。
class _Mlp {
  _Mlp(List<int> layerSizes, this._activation, math.Random rng) {
    for (var l = 0; l < layerSizes.length - 1; l++) {
      final inSize = layerSizes[l];
      final outSize = layerSizes[l + 1];
      _weights.add(List.generate(
        inSize,
        (_) => List.generate(outSize, (_) => (rng.nextDouble() - 0.5)),
      ));
      _biases.add(List.filled(outSize, 0.0));
    }
  }

  final NnActivation _activation;
  final List<List<List<double>>> _weights = [];
  final List<List<double>> _biases = [];

  double predict(double x, double y) => _forwardAll([x / 10, y / 10]).last[0];

  /// 1エポック分の全データに対するフルバッチ勾配降下法。平均損失(交差
  /// エントロピー)を返す。
  double trainEpoch(List<NnBuilderPointSpec> points, double lr) {
    final n = points.length;
    final gradW = [for (final w in _weights) [for (final row in w) List.filled(row.length, 0.0)]];
    final gradB = [for (final b in _biases) List.filled(b.length, 0.0)];
    var totalLoss = 0.0;

    for (final p in points) {
      final activations = _forwardAll([p.x / 10, p.y / 10]);
      final yTrue = p.label.toDouble();
      final yPred = activations.last[0].clamp(1e-7, 1 - 1e-7);
      totalLoss += -(yTrue * math.log(yPred) + (1 - yTrue) * math.log(1 - yPred));

      var delta = [yPred - yTrue];
      for (var l = _weights.length - 1; l >= 0; l--) {
        final aPrev = activations[l];
        for (var i = 0; i < aPrev.length; i++) {
          for (var j = 0; j < delta.length; j++) {
            gradW[l][i][j] += aPrev[i] * delta[j];
          }
        }
        for (var j = 0; j < delta.length; j++) {
          gradB[l][j] += delta[j];
        }
        if (l > 0) {
          final newDelta = List.filled(aPrev.length, 0.0);
          for (var i = 0; i < aPrev.length; i++) {
            var sum = 0.0;
            for (var j = 0; j < delta.length; j++) {
              sum += _weights[l][i][j] * delta[j];
            }
            newDelta[i] = sum * _activateDeriv(aPrev[i]);
          }
          delta = newDelta;
        }
      }
    }

    for (var l = 0; l < _weights.length; l++) {
      for (var i = 0; i < _weights[l].length; i++) {
        for (var j = 0; j < _weights[l][i].length; j++) {
          _weights[l][i][j] -= lr * gradW[l][i][j] / n;
        }
      }
      for (var j = 0; j < _biases[l].length; j++) {
        _biases[l][j] -= lr * gradB[l][j] / n;
      }
    }

    return totalLoss / n;
  }

  List<List<double>> _forwardAll(List<double> input) {
    final activations = <List<double>>[input];
    var current = input;
    for (var l = 0; l < _weights.length; l++) {
      final isOutput = l == _weights.length - 1;
      final outSize = _weights[l][0].length;
      final z = List.generate(outSize, (j) {
        var sum = _biases[l][j];
        for (var i = 0; i < current.length; i++) {
          sum += current[i] * _weights[l][i][j];
        }
        return sum.clamp(-30.0, 30.0);
      });
      final a = z.map((v) => isOutput ? _sigmoid(v) : _activate(v)).toList();
      activations.add(a);
      current = a;
    }
    return activations;
  }

  double _activate(double z) {
    switch (_activation) {
      case NnActivation.sigmoid:
        return _sigmoid(z);
      case NnActivation.relu:
        return z > 0 ? z : 0;
      case NnActivation.tanh:
        final e2z = math.exp(2 * z);
        return (e2z - 1) / (e2z + 1);
    }
  }

  double _activateDeriv(double a) {
    switch (_activation) {
      case NnActivation.sigmoid:
        return a * (1 - a);
      case NnActivation.relu:
        return a > 0 ? 1 : 0;
      case NnActivation.tanh:
        return 1 - a * a;
    }
  }

  double _sigmoid(double z) => 1 / (1 + math.exp(-z));
}
