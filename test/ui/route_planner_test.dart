import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
      theme: UkalabTheme.light(field: UkalabField.ai, cert: UkalabCert.gKentei),
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  testWidgets('タスク数と各科目名を表示する', (tester) async {
    await tester.pumpWidget(_app(const RoutePlannerWidget(tasks: [
      RouteTaskSpec(subjectId: 'a', subjectName: '機械学習の概要', belowPassLine: false),
      RouteTaskSpec(subjectId: 'b', subjectName: 'AIに関する法律と契約', belowPassLine: true),
    ])));

    expect(find.text('今日やる2つ'), findsOneWidget);
    expect(find.text('機械学習の概要'), findsOneWidget);
    expect(find.text('AIに関する法律と契約'), findsOneWidget);
  });

  testWidgets('足切りの科目には警告ラベルが出る', (tester) async {
    await tester.pumpWidget(_app(const RoutePlannerWidget(tasks: [
      RouteTaskSpec(subjectId: 'a', subjectName: '機械学習の概要', belowPassLine: false),
      RouteTaskSpec(subjectId: 'b', subjectName: 'AIに関する法律と契約', belowPassLine: true),
    ])));

    expect(find.text('足切りライン未達'), findsOneWidget);
  });

  testWidgets('タスクが空なら完了メッセージを出す', (tester) async {
    await tester.pumpWidget(_app(const RoutePlannerWidget(tasks: [])));
    expect(find.textContaining('よくできました'), findsOneWidget);
  });

  testWidgets('タップすると subjectId を渡す', (tester) async {
    String? tapped;
    await tester.pumpWidget(_app(RoutePlannerWidget(
      tasks: const [
        RouteTaskSpec(subjectId: 'a', subjectName: '機械学習の概要', belowPassLine: false),
      ],
      onTapTask: (id) => tapped = id,
    )));

    await tester.tap(find.text('機械学習の概要'));
    expect(tapped, 'a');
  });
}
