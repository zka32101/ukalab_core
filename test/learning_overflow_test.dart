// 狭い幅（320 / 280dp）× 大きい文字倍率（1 / 2 / 3）で、学習向けの部品が
// RenderFlex overflow などを起こさないことを確かめる（キットから移した検査）。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/learning.dart';

const _long = 'とても長い文言のサンプルです。文字が大きくなっても、はみ出したり切れたりしないことを確認します。';
const _sizes = [Size(320, 568), Size(280, 480)];
const _scales = [1.0, 2.0, 3.0];

Future<List<String>> _errorsFor(WidgetTester tester, Widget Function() build) async {
  final errors = <String>[];
  final prev = FlutterError.onError;
  FlutterError.onError = (d) {
    final lines = d.toString().split('\n');
    final i = lines.indexWhere((l) => l.contains('error-causing widget'));
    final where = i >= 0 && i + 1 < lines.length ? lines[i + 1].trim() : '';
    errors.add('${d.exceptionAsString().split('\n').first} $where');
  };
  try {
    for (final size in _sizes) {
      for (final scale in _scales) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        final before = errors.length;
        await tester.pumpWidget(
          MaterialApp(
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(body: SafeArea(child: SingleChildScrollView(child: build()))),
          ),
        );
        await tester.pump();
        for (var i = before; i < errors.length; i++) {
          errors[i] = '${size.width.toInt()}dp x$scale: ${errors[i]}';
        }
        await tester.pumpWidget(const SizedBox());
      }
    }
  } finally {
    FlutterError.onError = prev;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
  return errors;
}

void main() {
  testWidgets('StreakBadge / ResultSummary', (t) async {
    final e = await _errorsFor(
      t,
      () => Column(
        children: [
          const StreakBadge(days: 123),
          const StreakBadge(days: 0, zeroText: _long),
          ResultSummary(
            correct: 7,
            total: 10,
            passRatio: 0.6,
            passedText: _long,
            notPassedText: _long,
            onRetry: () {},
            retryLabel: _long,
            onClose: () {},
            closeLabel: _long,
          ),
        ],
      ),
    );
    if (e.isNotEmpty) fail(e.join('\n'));
  });

  testWidgets('QuestionCard / ExplanationPanel', (t) async {
    final e = await _errorsFor(
      t,
      () => const Column(
        children: [
          QuestionCard(text: _long, index: 12, total: 100),
          ExplanationPanel(title: _long, body: _long, sourceRef: _long, checkedAt: '2026-10-14'),
        ],
      ),
    );
    if (e.isNotEmpty) fail(e.join('\n'));
  });

  testWidgets('MockExamTrendChart', (t) async {
    final e = await _errorsFor(
      t,
      () => const MockExamTrendChart(
        points: [
          MockExamTrendPoint(pct: 60, passed: false),
          MockExamTrendPoint(pct: 80, passed: true),
        ],
        passPct: 70,
      ),
    );
    if (e.isNotEmpty) fail(e.join('\n'));
  });
}
