import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

DateTime _clock() => DateTime(2026, 10, 13, 15, 0);

Widget _host(Widget child, {bool reduce = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  group('ExamCountdownChip', () {
    testWidgets('日数を表示し、タップでコールバック', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(ExamCountdownChip(
        examDate: DateTime(2026, 10, 23),
        clock: _clock,
        onTap: () => taps++,
      )));
      await tester.pumpAndSettle();
      expect(find.text('あと10日'), findsOneWidget);
      await tester.tap(find.byType(ActionChip));
      expect(taps, 1);
    });

    testWidgets('onTap なしはタップ不要の Chip', (tester) async {
      await tester.pumpWidget(_host(ExamCountdownChip(examDate: DateTime(2026, 10, 14), clock: _clock)));
      await tester.pumpAndSettle();
      expect(find.text('あと1日'), findsOneWidget);
      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('未設定は何も出さない', (tester) async {
      await tester.pumpWidget(_host(ExamCountdownChip(examDate: null, clock: _clock)));
      expect(find.byType(Chip), findsNothing);
      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('当日と終了後', (tester) async {
      await tester.pumpWidget(_host(ExamCountdownChip(examDate: DateTime(2026, 10, 13), clock: _clock)));
      await tester.pumpAndSettle();
      expect(find.text('今日が試験日'), findsOneWidget);
      await tester.pumpWidget(_host(ExamCountdownChip(examDate: DateTime(2026, 10, 1), clock: _clock)));
      await tester.pumpAndSettle();
      expect(find.text('おつかれさまでした'), findsOneWidget);
      expect(find.textContaining('日'), findsNothing);
    });

    testWidgets('Semantics に日数とタップ案内、en 文言', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(ExamCountdownChip(
        examDate: DateTime(2026, 10, 23),
        clock: _clock,
        onTap: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('あと10日。タップして試験日を設定')), findsOneWidget);
      await tester.pumpWidget(_host(ExamCountdownChip(
        examDate: DateTime(2026, 10, 23),
        clock: _clock,
        strings: ExamCountdownStrings.en,
      )));
      await tester.pumpAndSettle();
      expect(find.text('10 days to go'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('動きを減らす設定でも即時に表示', (tester) async {
      await tester.pumpWidget(_host(
        ExamCountdownChip(examDate: DateTime(2026, 10, 23), clock: _clock),
        reduce: true,
      ));
      expect(find.text('あと10日'), findsOneWidget);
      final o = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(o.opacity, 1);
    });
  });

  group('ExamCountdownCard', () {
    testWidgets('見出し・気持ち・今日できること', (tester) async {
      await tester.pumpWidget(_host(ExamCountdownCard(examDate: DateTime(2026, 10, 20), clock: _clock)));
      await tester.pumpAndSettle();
      expect(find.text('試験まで7日'), findsOneWidget);
      expect(find.text('いつもどおりで大丈夫。'), findsOneWidget);
      expect(find.textContaining('今日できること'), findsOneWidget);
    });

    testWidgets('終了後は日数を消し、今日できることも出さない', (tester) async {
      await tester.pumpWidget(_host(ExamCountdownCard(examDate: DateTime(2026, 9, 1), clock: _clock)));
      await tester.pumpAndSettle();
      expect(find.text('おつかれさまでした'), findsOneWidget);
      expect(find.textContaining('今日できること'), findsNothing);
      expect(find.textContaining(RegExp(r'\d')), findsNothing);
    });

    testWidgets('未設定は何も出さない', (tester) async {
      await tester.pumpWidget(_host(ExamCountdownCard(examDate: null, clock: _clock)));
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('タップでコールバック、Semantics はボタン', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(_host(ExamCountdownCard(
        examDate: DateTime(2026, 12, 31),
        clock: _clock,
        onTap: () => taps++,
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InkWell));
      expect(taps, 1);
      expect(find.bySemanticsLabel(RegExp('試験まで79日。.*タップして試験日を設定')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('全 phase で描画できる（reduce motion）', (tester) async {
      for (final d in [200, 100, 30, 7, 0, -1]) {
        await tester.pumpWidget(_host(
          ExamCountdownCard(examDate: DateTime(2026, 10, 13 + d), clock: _clock),
          reduce: true,
        ));
        expect(find.byType(Card), findsOneWidget, reason: '$d');
      }
    });
  });
}
