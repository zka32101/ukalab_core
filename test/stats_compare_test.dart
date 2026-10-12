import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('summary が null なら何も表示しない', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StatsCompareWidget(summary: null, myScore: 100)),
    ));
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('全国平均・あなたの点数・偏差値を表示する', (tester) async {
    const summary = ExamStatsSummary(sampleCount: 120, averageScore: 100, stdDev: 10);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StatsCompareWidget(summary: summary, myScore: 110)),
    ));

    expect(find.textContaining('全国平均点'), findsOneWidget);
    expect(find.text('あなたの点数 110点'), findsOneWidget);
    expect(find.text('偏差値 60.0'), findsOneWidget);
  });
}
