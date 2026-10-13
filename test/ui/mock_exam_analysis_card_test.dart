import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

final _answers = [
  for (var i = 0; i < 4; i++) MockExamAnswer(topicId: 't1', correct: i < 1),
  for (var i = 0; i < 4; i++) MockExamAnswer(topicId: 't2', correct: i < 2),
  for (var i = 0; i < 4; i++) MockExamAnswer(topicId: 't3', correct: true),
  for (var i = 0; i < 4; i++) MockExamAnswer(topicId: 't4', correct: i < 3),
];

String _name(String id) => 'ぶんや$id' * 6; // 長い分野名

Widget _host(Widget child, {double width = 400, double scale = 1}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800), textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  const engine = MockExamAnalysisEngine();

  testWidgets('分野名・次にやる分野・Semantics 要約が出る', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(MockExamAnalysisCard(
      analysis: engine.analyze(_answers),
      topicLabel: (id) => '第$id章',
    )));
    expect(find.text('模擬試験のふりかえり'), findsOneWidget);
    expect(find.text('今日はここを少しだけ'), findsOneWidget);
    expect(find.text('・第t1章'), findsOneWidget);
    expect(find.text('・第t2章'), findsOneWidget);
    expect(find.text('・第t4章'), findsOneWidget);
    expect(find.text('・第t3章'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('解いた問題 16問')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('空は穏やかな表示', (tester) async {
    await tester.pumpWidget(_host(MockExamAnalysisCard(analysis: engine.analyze(const []))));
    expect(find.text(MockExamAnalysisStrings.ja.emptyTitle), findsOneWidget);
    expect(find.text(MockExamAnalysisStrings.ja.nextLabel), findsNothing);
  });

  testWidgets('全分野が安定なら allGoodBody / en', (tester) async {
    await tester.pumpWidget(KitStringsScope(
      strings: KitStrings.en,
      child: _host(MockExamAnalysisCard(
        analysis: engine.analyze([for (var i = 0; i < 5; i++) const MockExamAnswer(topicId: 'a', correct: true)]),
      )),
    ));
    expect(find.text(MockExamAnalysisStrings.en.allGoodBody), findsOneWidget);
    expect(find.text('Mock exam review'), findsOneWidget);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('幅320・文字${scale}倍でオーバーフローしない', (tester) async {
      await tester.pumpWidget(_host(
        MockExamAnalysisCard(analysis: engine.analyze(_answers), topicLabel: _name),
        width: 320,
        scale: scale,
      ));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('画面: 回答リストを渡すだけで表示できる（幅320・文字2倍）', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(2)),
        child: MockExamAnalysisScreen(answers: _answers, topicLabel: _name),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('模擬試験のふりかえり'), findsWidgets);
  });
}
