import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _eraOrder = {
  'boom1': '第1次AIブーム',
  'deep_learning': '深層学習の時代',
  'generative_ai': '生成AIの時代',
};

Widget _app(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  testWidgets('系譜図は時代ごとにグループ化して表示する', (tester) async {
    await tester.pumpWidget(_app(const TermMapWidget(
      nodes: [
        TermMapNodeSpec(termId: 't1', label: 'ELIZA', era: 'boom1'),
        TermMapNodeSpec(termId: 't2', label: 'ResNet', era: 'deep_learning'),
        TermMapNodeSpec(termId: 't3', label: '生成AI', era: 'generative_ai'),
      ],
      eraOrder: _eraOrder,
      onNodeTap: _noop,
    )));

    expect(find.text('AIの歴史（系譜図）'), findsOneWidget);
    expect(find.text('第1次AIブーム'), findsOneWidget);
    expect(find.text('深層学習の時代'), findsOneWidget);
    expect(find.text('生成AIの時代'), findsOneWidget);
    expect(find.text('ELIZA'), findsOneWidget);
    expect(find.text('ResNet'), findsOneWidget);
    expect(find.text('生成AI'), findsOneWidget);
  });

  testWidgets('era のない用語は用語マップ側に表示する', (tester) async {
    await tester.pumpWidget(_app(const TermMapWidget(
      nodes: [
        TermMapNodeSpec(termId: 't1', label: '過学習', relatedTermIds: ['t2']),
        TermMapNodeSpec(termId: 't2', label: '正則化', relatedTermIds: ['t1']),
      ],
      eraOrder: _eraOrder,
      onNodeTap: _noop,
    )));

    expect(find.text('AIの歴史（系譜図）'), findsNothing);
    expect(find.text('用語マップ（関連でつながる用語）'), findsOneWidget);
    expect(find.text('過学習'), findsOneWidget);
    expect(find.text('正則化'), findsOneWidget);
  });

  testWidgets('ノードをタップすると onNodeTap が呼ばれる', (tester) async {
    String? tapped;
    await tester.pumpWidget(_app(TermMapWidget(
      nodes: const [
        TermMapNodeSpec(termId: 't1', label: 'ELIZA', era: 'boom1'),
      ],
      eraOrder: _eraOrder,
      onNodeTap: (id) => tapped = id,
    )));

    await tester.tap(find.text('ELIZA'));
    expect(tapped, 't1');
  });

  testWidgets('習得度でアイコンが変わる(色だけに頼らない)', (tester) async {
    await tester.pumpWidget(_app(const TermMapWidget(
      nodes: [
        TermMapNodeSpec(termId: 't1', label: '過学習', mastery: TermMastery.mastered),
        TermMapNodeSpec(termId: 't2', label: '正則化', mastery: TermMastery.weak),
      ],
      eraOrder: _eraOrder,
      onNodeTap: _noop,
    )));

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.priority_high), findsOneWidget);
  });
}

void _noop(String _) {}
