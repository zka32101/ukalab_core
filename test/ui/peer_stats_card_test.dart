import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

DateTime _clock() => DateTime(2026, 10, 14, 9);

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

PeerStatsSnapshot _snap(int n) => PeerStatsSnapshot(
      asOf: '2026-10-14',
      activeToday: n,
      participants: n,
      totalQuestions: 5000,
      medianQuestions: 40,
      streakCounts: {1: n - 20, 30: 20},
      examDateCounts: {'2026-12-06': n},
    );

void main() {
  testWidgets('100 人以下は何も描画しない', (tester) async {
    await tester.pumpWidget(_host(PeerStatsCard(snapshot: _snap(100), examDate: DateTime(2026, 12, 6), clock: _clock)));
    expect(find.byType(Card), findsNothing);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('null も何も描画しない', (tester) async {
    await tester.pumpWidget(_host(PeerStatsCard(snapshot: null, clock: _clock)));
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('101 人で表示（ja）', (tester) async {
    await tester.pumpWidget(_host(PeerStatsCard(
      snapshot: _snap(101),
      streakDays: 30,
      examDate: DateTime(2026, 12, 6),
      clock: _clock,
    )));
    expect(find.text('他にも頑張っている人がいます'), findsOneWidget);
    expect(find.text('今日、101人が学習しています'), findsOneWidget);
    expect(find.textContaining('あと53日'), findsOneWidget);
    expect(find.textContaining('中央値'), findsOneWidget);
    expect(find.textContaining('上位'), findsOneWidget);
  });

  testWidgets('strings を差し替えられる（en）', (tester) async {
    await tester.pumpWidget(_host(PeerStatsCard(snapshot: _snap(300), clock: _clock, strings: PeerStatsStrings.en)));
    expect(find.text('300 people studied today'), findsOneWidget);
  });
}
