import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/answer_feedback.dart';
import 'package:ukalab_core/ukalab_core.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

ChapterReading _r(String id, {bool disabled = false}) => ChapterReading(
  readingId: id,
  examId: 'sample',
  subjectId: 'math',
  title: '読み物$id',
  sections: const [ReadingSection(heading: 'h', body: 'b')],
  source: QuestionSource.original,
  sourceRef: '自作',
  contentVer: '1',
  disabled: disabled,
);

void main() {
  Future<void> settle(WidgetTester t) => t.pump(const Duration(seconds: 1));

  testWidgets('誤答: 見出しと読み物が出てタップで通知', (tester) async {
    ChapterReading? opened;
    await tester.pumpWidget(
      _app(
        RelatedReadingsCard(
          readings: [_r('1'), _r('2', disabled: true), _r('3')],
          onOpenReading: (r) => opened = r,
        ),
      ),
    );
    await settle(tester);
    expect(find.text('読み物でおさらい'), findsOneWidget);
    expect(find.text('読み物1'), findsOneWidget);
    expect(find.text('読み物2'), findsNothing);
    await tester.tap(find.text('読み物3'));
    expect(opened?.readingId, '3');
  });

  testWidgets('正解・空・コールバックなしは何も出さない', (tester) async {
    for (final w in <Widget>[
      RelatedReadingsCard(
        readings: [_r('1')],
        onOpenReading: (_) {},
        isCorrect: true,
      ),
      RelatedReadingsCard(readings: const [], onOpenReading: (_) {}),
      RelatedReadingsCard(readings: [_r('1', disabled: true)], onOpenReading: (_) {}),
      RelatedReadingsCard(readings: [_r('1')], onOpenReading: null),
    ]) {
      await tester.pumpWidget(_app(w));
      await settle(tester);
      expect(find.byType(Card), findsNothing);
      expect(find.text('読み物でおさらい'), findsNothing);
    }
  });

  testWidgets('strings を差し替えられる', (tester) async {
    await tester.pumpWidget(
      _app(
        RelatedReadingsCard(
          readings: [_r('1')],
          onOpenReading: (_) {},
          strings: AnswerFeedbackStrings.en,
        ),
      ),
    );
    await settle(tester);
    expect(find.text('Read to review'), findsOneWidget);
  });
}
