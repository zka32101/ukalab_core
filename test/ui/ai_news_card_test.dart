import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  testWidgets('項目が空ならなにも表示しない', (tester) async {
    await tester.pumpWidget(_app(const AiNewsCard(items: [])));
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('要約・章タグ・「◯年◯月時点」を表示する', (tester) async {
    await tester.pumpWidget(_app(AiNewsCard(items: [
      AiNewsItemSpec(
        summary: '生成AIの新しい基盤モデルが発表された。',
        sourceUrl: 'https://example.com/news/1',
        sourceDate: DateTime(2026, 9, 1),
        syllabusTag: '2 人工知能をめぐる動向',
        asOfDate: DateTime(2026, 10, 1),
      ),
    ])));

    expect(find.text('今月のAI動向'), findsOneWidget);
    expect(find.text('2026年10月時点'), findsOneWidget);
    expect(find.text('生成AIの新しい基盤モデルが発表された。'), findsOneWidget);
    expect(find.text('2 人工知能をめぐる動向'), findsOneWidget);
    expect(find.text('https://example.com/news/1'), findsOneWidget);
  });

  testWidgets('「試験に出そう」印は色だけに頼らずアイコン・バッジで示す', (tester) async {
    await tester.pumpWidget(_app(AiNewsCard(items: [
      AiNewsItemSpec(
        summary: '要約',
        sourceUrl: 'https://example.com/news/1',
        sourceDate: DateTime(2026, 9, 1),
        syllabusTag: '2',
        asOfDate: DateTime(2026, 10, 1),
        isExamRelevant: true,
      ),
    ])));

    expect(find.byIcon(Icons.flag), findsOneWidget);
    expect(find.text('試験に出そう'), findsOneWidget);
  });

  testWidgets('複数件を区切って表示する', (tester) async {
    await tester.pumpWidget(_app(AiNewsCard(items: [
      AiNewsItemSpec(
        summary: '要約1',
        sourceUrl: 'https://example.com/1',
        sourceDate: DateTime(2026, 9, 1),
        syllabusTag: '2',
        asOfDate: DateTime(2026, 10, 1),
      ),
      AiNewsItemSpec(
        summary: '要約2',
        sourceUrl: 'https://example.com/2',
        sourceDate: DateTime(2026, 9, 2),
        syllabusTag: '6',
        asOfDate: DateTime(2026, 10, 1),
      ),
    ])));

    expect(find.text('要約1'), findsOneWidget);
    expect(find.text('要約2'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
  });
}
