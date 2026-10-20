import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/learning.dart';

Widget _app(Widget child) => MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  group('StreakBadge', () {
    testWidgets('0日でも責めない文言、1日以上は日数', (tester) async {
      await tester.pumpWidget(_app(const Column(children: [
        StreakBadge(days: 0),
        StreakBadge(days: 7),
      ])));
      expect(find.text('今日から始めよう'), findsOneWidget);
      expect(find.text('7日連続'), findsOneWidget);
    });
  });

  group('ExplanationPanel', () {
    testWidgets('出典があれば確認日つきで出る。なければ出ない', (tester) async {
      await tester.pumpWidget(_app(const Column(children: [
        ExplanationPanel(body: '本文', sourceRef: '道路交通法第34条', checkedAt: '2026-10-02'),
        ExplanationPanel(body: '出典なし'),
      ])));
      expect(find.text('出典: 道路交通法第34条（2026-10-02 確認）'), findsOneWidget);
      expect(find.textContaining('出典:'), findsOneWidget);
    });

    testWidgets('bodyWidget を渡すと body の代わりにそれが表示される', (tester) async {
      await tester.pumpWidget(_app(const ExplanationPanel(
        body: '使われない本文',
        bodyWidget: Text('差し替えた本文'),
      )));
      expect(find.text('差し替えた本文'), findsOneWidget);
      expect(find.text('使われない本文'), findsNothing);
    });
  });

  group('QuestionCard', () {
    testWidgets('textWidget を渡すと text の代わりにそれが表示される', (tester) async {
      await tester.pumpWidget(_app(const QuestionCard(
        text: '使われない問題文',
        textWidget: Text('差し替えた問題文'),
      )));
      expect(find.text('差し替えた問題文'), findsOneWidget);
      expect(find.text('使われない問題文'), findsNothing);
    });
  });

  group('ResultSummary', () {
    testWidgets('合格ライン到達と未到達で文言が変わる（アイコンも併用）', (tester) async {
      await tester.pumpWidget(_app(const ResultSummary(correct: 8, total: 10, passRatio: 0.7)));
      expect(find.text('合格ライン到達'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('8 / 10 問正解'), findsOneWidget);

      await tester.pumpWidget(_app(const ResultSummary(correct: 5, total: 10, passRatio: 0.7)));
      expect(find.text('あと少し。弱点を復習しよう'), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    });

    testWidgets('問題数0でも落ちない', (tester) async {
      await tester.pumpWidget(_app(const ResultSummary(correct: 0, total: 0)));
      expect(find.text('0%'), findsOneWidget);
    });
  });

}
