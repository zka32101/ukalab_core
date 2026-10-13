import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

const _banJa = [
  'サボ', 'さぼ', '遅れ', '遅い', 'ダメ', 'だめ', '駄目', 'ないと', 'なければ', 'べき', '怠',
  '失敗', '焦', '急が', '急い', '間に合わ', '足りな', 'わずか', '危', '残念', '少な', '減',
  'ワースト', '苦手ばかり', 'また間違', '最後', '多い', '順位', 'ランキング',
];
const _banEn = [
  'lazy', 'behind', 'slack', 'skipp', 'must', 'have to', 'should', 'fail', 'hurry', 'rush',
  'running out', 'too late', 'disappoint', 'only ', 'worry', 'deadline', 'fewer', 'less ',
  'worst', 'again and again', 'missed', 'ranking', 'most ',
];

MistakeNoteEntry e(String qid, int day, {bool overcome = false, WrongCause? cause, String? topic, int miss = 1}) =>
    MistakeNoteEntry(
      qid: qid,
      firstMissedAt: DateTime(2026, 10, day),
      lastMissedAt: DateTime(2026, 10, day),
      missCount: miss,
      overcome: overcome,
      lastCause: cause,
      topicId: topic,
      lastAnsweredAt: DateTime(2026, 10, day),
    );

Widget host(Widget child, {bool reduce = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(body: child),
      ),
    );

Widget view(
  List<MistakeNoteEntry> entries, {
  void Function(MistakeNoteEntry)? onRetry,
  Set<String> celebrate = const {},
  MistakeNoteFilter filter = MistakeNoteFilter.upcoming,
}) =>
    host(MistakeNoteView(
      entries: entries,
      questionBuilder: (c, x) => Text('問題 ${x.qid}'),
      onRetry: onRetry ?? (_) {},
      celebrateQids: celebrate,
      initialFilter: filter,
      topicLabel: (id) => '分野$id',
    ));

void main() {
  test('文言に責める表現・件数で圧をかける表現を含めない（ja/en 全文言）', () {
    for (final t in MistakeNoteStrings.ja.allTexts) {
      for (final w in _banJa) {
        expect(t.contains(w), isFalse, reason: '"$t" contains "$w"');
      }
    }
    for (final t in MistakeNoteStrings.en.allTexts) {
      for (final w in _banEn) {
        expect(t.toLowerCase().contains(w), isFalse, reason: '"$t" contains "$w"');
      }
    }
  });

  test('copyWith で一部だけ上書き、forLanguageCode', () {
    final st = MistakeNoteStrings.ja.copyWith(title: 'ノート');
    expect(st.title, 'ノート');
    expect(st.retry, MistakeNoteStrings.ja.retry);
    expect(MistakeNoteStrings.forLanguageCode('en'), same(MistakeNoteStrings.en));
    expect(MistakeNoteStrings.forLanguageCode('ko'), same(MistakeNoteStrings.ja));
  });

  testWidgets('「これから」は未克服だけ、直近の間違い順（件数順にしない）', (tester) async {
    await tester.pumpWidget(view([
      e('many', 1, miss: 9),
      e('new', 5),
      e('done', 6, overcome: true),
    ]));
    expect(find.text('問題 done'), findsNothing);
    final newY = tester.getTopLeft(find.text('問題 new')).dy;
    final manyY = tester.getTopLeft(find.text('問題 many')).dy;
    expect(newY, lessThan(manyY));
    expect(find.text('間違いノート'), findsOneWidget);
  });

  testWidgets('「克服」に切り替えると克服済みだけが出る', (tester) async {
    await tester.pumpWidget(view([e('a', 1), e('done', 6, overcome: true)]));
    await tester.tap(find.text('克服').first);
    await tester.pumpAndSettle();
    expect(find.text('問題 a'), findsNothing);
    expect(find.text('問題 done'), findsOneWidget);
  });

  testWidgets('分野・原因・日付が出る', (tester) async {
    await tester.pumpWidget(view([e('a', 12, cause: WrongCause.trap, topic: 't1')]));
    expect(find.text('分野t1'), findsOneWidget);
    expect(find.text('ひっかけ'), findsOneWidget);
    expect(find.text('見つけた日 10/12'), findsOneWidget);
  });

  testWidgets('「解き直す」でコールバックに該当項目が渡る', (tester) async {
    final got = <String>[];
    await tester.pumpWidget(view([e('a', 1), e('b', 2)], onRetry: (x) => got.add(x.qid)));
    await tester.tap(find.text('解き直す').first);
    expect(got, ['b']);
  });

  testWidgets('空のときは穏やかな表示', (tester) async {
    await tester.pumpWidget(view(const []));
    expect(find.text('いまは見返すものはありません'), findsOneWidget);
    await tester.tap(find.text('克服').first);
    await tester.pumpAndSettle();
    expect(find.text('克服した問題がここに並びます'), findsOneWidget);
  });

  testWidgets('克服したときは祝う表示（Semantics 付き）、無ければ出さない', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(view([e('a', 1)]));
    expect(find.text('克服したよ！'), findsNothing);
    await tester.pumpWidget(view([e('a', 1, overcome: true)], celebrate: {'a'}, filter: MistakeNoteFilter.overcome));
    await tester.pumpAndSettle();
    expect(find.text('克服したよ！'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('克服したよ！')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('動きを減らす設定では祝う表示がすぐ完全に出る', (tester) async {
    await tester.pumpWidget(host(
      MistakeNoteView(
        entries: [e('a', 1, overcome: true)],
        questionBuilder: (c, x) => const Text('q'),
        onRetry: (_) {},
        celebrateQids: const {'a'},
      ),
      reduce: true,
    ));
    final o = tester.widget<Opacity>(find.ancestor(of: find.text('克服したよ！'), matching: find.byType(Opacity)).first);
    expect(o.opacity, 1);
  });

  testWidgets('strings を上書きできる', (tester) async {
    await tester.pumpWidget(host(MistakeNoteView(
      entries: [e('a', 1)],
      questionBuilder: (c, x) => const Text('q'),
      onRetry: (_) {},
      strings: MistakeNoteStrings.en,
    )));
    expect(find.text('Try again'), findsOneWidget);
  });
}
