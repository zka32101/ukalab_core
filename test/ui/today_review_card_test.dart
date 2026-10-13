import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

Widget host(Widget child, {double width = 800, double scale = 1.0, ThemeData? theme}) => MaterialApp(
      theme: theme,
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800), textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Align(alignment: Alignment.topLeft, child: SizedBox(width: width, child: child)),
          ),
        ),
      ),
    );

void main() {
  testWidgets('期限の件数と「やってみる」を出し、押すと onStart', (t) async {
    var starts = 0;
    await t.pumpWidget(host(TodayReviewCard(dueCount: 4, onStart: () => starts++)));
    expect(find.text('今日の復習'), findsOneWidget);
    expect(find.text('4問、見返せるよ'), findsOneWidget);
    expect(find.text(ReviewSchedulerStrings.ja.reassure), findsOneWidget);
    await t.tap(find.text('やってみる'));
    expect(starts, 1);
  });

  testWidgets('0件はおやすみ表示でボタンなし', (t) async {
    await t.pumpWidget(host(TodayReviewCard(dueCount: 0, onStart: () {})));
    expect(find.text('今日の復習はおやすみ'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('件数は赤字・エラー色にしない', (t) async {
    final theme = ThemeData(colorScheme: const ColorScheme.light(primary: Colors.blue, error: Colors.red));
    await t.pumpWidget(host(TodayReviewCard(dueCount: 99, onStart: () {}), theme: theme));
    final texts = t.widgetList<Text>(find.byType(Text));
    for (final x in texts) {
      expect(x.style?.color, isNot(Colors.red));
    }
    final count = t.widget<Text>(find.text('99問、見返せるよ'));
    expect(count.style?.color, Colors.blue);
  });

  testWidgets('英語の文言を渡せる', (t) async {
    await t.pumpWidget(host(TodayReviewCard(dueCount: 2, onStart: () {}, strings: ReviewSchedulerStrings.en)));
    expect(find.text('2 to revisit'), findsOneWidget);
    expect(find.text('Give it a try'), findsOneWidget);
  });

  for (final count in [0, 3]) {
    testWidgets('幅320・文字2倍でもあふれず、ボタンは48dp以上 (件数$count)', (t) async {
      await t.pumpWidget(host(TodayReviewCard(dueCount: count, onStart: () {}), width: 320, scale: 2.0));
      expect(t.takeException(), isNull);
      if (count > 0) {
        final size = t.getSize(find.byType(FilledButton));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(size.width, greaterThanOrEqualTo(48));
      }
    });
  }

  testWidgets('Semantics: 見出しとボタン', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(host(TodayReviewCard(dueCount: 2, onStart: () {})));
    expect(find.bySemanticsLabel('やってみる'), findsOneWidget);
    expect(t.getSemantics(find.text('今日の復習')), matchesSemantics(isHeader: true, label: '今日の復習'));
    h.dispose();
  });
}
