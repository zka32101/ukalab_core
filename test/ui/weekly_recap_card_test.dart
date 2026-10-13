import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

const _banJa = [
  'サボ', 'さぼ', '遅れ', '遅い', 'ダメ', 'だめ', '駄目', 'ないと', 'なければ', 'べき', '怠',
  '失敗', '焦', '急が', '急い', '間に合わ', '足りな', 'わずか', '危', '残念', '少な', '減',
  '先週', '前週', '比べ', '以下', '最後',
];
const _banEn = [
  'lazy', 'behind', 'slack', 'skipp', 'must', 'have to', 'should', 'fail', 'hurry', 'rush',
  'running out', 'too late', 'disappoint', 'only ', 'worry', 'deadline', 'fewer', 'less ',
  'last week', 'previous week', 'drop', 'decline', 'missed', 'compared',
];

final _full = WeeklyRecap(
  weekStart: DateTime(2026, 10, 12),
  answered: 42,
  correct: 30,
  studyDays: 5,
  streakDays: 3,
  topTopics: const [WeeklyRecapTopic(topicId: 't1', answered: 20, correct: 15)],
  improvedTopics: const ['t2'],
  medalsEarned: 2,
);

final _empty = WeeklyRecap(
  weekStart: DateTime(2026, 10, 12),
  answered: 0,
  correct: 0,
  studyDays: 0,
  streakDays: 0,
  topTopics: const [],
  improvedTopics: const [],
  medalsEarned: 0,
);

Widget _host(Widget child, {bool reduce = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  test('文言に責める表現・比較表現を含めない（ja/en 全文言）', () {
    for (final t in WeeklyRecapStrings.ja.allTexts) {
      for (final w in _banJa) {
        expect(t.contains(w), isFalse, reason: '"$t" contains "$w"');
      }
    }
    for (final t in WeeklyRecapStrings.en.allTexts) {
      for (final w in _banEn) {
        expect(t.toLowerCase().contains(w), isFalse, reason: '"$t" contains "$w"');
      }
    }
  });

  test('copyWith で一部だけ上書き、forLanguageCode', () {
    final st = WeeklyRecapStrings.ja.copyWith(title: 'やあ');
    expect(st.title, 'やあ');
    expect(st.answeredLabel, WeeklyRecapStrings.ja.answeredLabel);
    expect(WeeklyRecapStrings.forLanguageCode('en'), same(WeeklyRecapStrings.en));
    expect(WeeklyRecapStrings.forLanguageCode('ko'), same(WeeklyRecapStrings.ja));
  });

  testWidgets('値を表示し、message スロットと Semantics 要約が出る', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(WeeklyRecapCard(
      recap: _full,
      message: const Text('おつかれさま'),
      topicLabel: (id) => id == 't1' ? '第1章' : '第2章',
    )));
    await tester.pumpAndSettle();
    expect(find.text('今週のふりかえり'), findsOneWidget);
    expect(find.text('42問'), findsOneWidget);
    expect(find.text('5日'), findsOneWidget);
    expect(find.text('3日'), findsOneWidget);
    expect(find.text('2個'), findsOneWidget);
    expect(find.text('第1章'), findsOneWidget);
    expect(find.text('第2章'), findsOneWidget);
    expect(find.text('おつかれさま'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('解いた問題 42問')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('0件の週は穏やかな表示で、数値の行を出さない', (tester) async {
    await tester.pumpWidget(_host(WeeklyRecapCard(recap: _empty)));
    await tester.pumpAndSettle();
    expect(find.text(WeeklyRecapStrings.ja.emptyTitle), findsOneWidget);
    expect(find.text(WeeklyRecapStrings.ja.emptyBody), findsOneWidget);
    expect(find.text(WeeklyRecapStrings.ja.answeredLabel), findsNothing);
  });

  testWidgets('連続1日・メダル0は行を出さない / en / reduce motion', (tester) async {
    final r = WeeklyRecap(
      weekStart: DateTime(2026, 10, 12),
      answered: 3,
      correct: 2,
      studyDays: 1,
      streakDays: 1,
      topTopics: const [],
      improvedTopics: const [],
      medalsEarned: 0,
    );
    await tester.pumpWidget(KitStringsScope(
      strings: KitStrings.en,
      child: _host(WeeklyRecapCard(recap: r), reduce: true),
    ));
    expect(find.text(WeeklyRecapStrings.en.title), findsOneWidget);
    expect(find.text(WeeklyRecapStrings.en.streakLabel), findsNothing);
    expect(find.text(WeeklyRecapStrings.en.medalsLabel), findsNothing);
    expect(find.text('3'), findsNWidgets(1));
  });

  testWidgets('OshiMessageBubble を message に載せられる', (tester) async {
    await tester.pumpWidget(_host(WeeklyRecapCard(
      recap: _full,
      message: const OshiMessageBubble(situation: OshiMessageContext(streakDays: 5), seed: 1),
    )));
    await tester.pumpAndSettle();
    expect(find.byType(OshiMessageBubble), findsOneWidget);
  });
}
