import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

const _banJa = [
  'サボ', 'さぼ', '遅れ', '遅い', 'ダメ', 'だめ', '駄目', 'ないと', 'なければ', 'べき', '怠',
  '失敗', '焦', '急が', '急い', '間に合わ', '足りな', 'わずか', '危', '残念', '最後',
];
const _banEn = [
  'lazy', 'behind', 'slack', 'skipp', 'must', 'have to', 'should', 'fail', 'hurry', 'rush',
  'running out', 'too late', 'disappoint', 'only ', 'worry', 'deadline',
];

void main() {
  const engine = OshiMessageEngine();
  OshiSituation s(OshiMessageContext c) => OshiMessageEngine.situationOf(c);

  test('状況別の選択', () {
    expect(s(const OshiMessageContext(daysSinceLastStudy: 5)), OshiSituation.welcomeBack);
    expect(
      s(const OshiMessageContext(todayAnswered: 10, todayCorrectRate: 0.3, streakDays: 9)),
      OshiSituation.struggling,
    );
    expect(s(const OshiMessageContext(streakDays: 4)), OshiSituation.streak);
    expect(
      s(const OshiMessageContext(todayAnswered: 5, todayCorrectRate: 0.9)),
      OshiSituation.praise,
    );
    expect(s(const OshiMessageContext(examDaysLeft: 30)), OshiSituation.examPace);
    expect(s(const OshiMessageContext(examDaysLeft: 0)), OshiSituation.greeting);
    expect(s(const OshiMessageContext(hasWeakTopics: true)), OshiSituation.weakTopic);
    expect(s(const OshiMessageContext(todayAnswered: 1)), OshiSituation.praise);
    expect(s(const OshiMessageContext()), OshiSituation.greeting);
  });

  test('seed が同じなら同じ結果、日付で日替わり、salt で別の言い回し', () {
    const c = OshiMessageContext(streakDays: 5);
    final a = engine.pick(c, seed: 20261013);
    expect(engine.pick(c, seed: 20261013).id, a.id);
    final ids = {
      for (var d = 1; d <= 6; d++)
        engine.pick(c, seed: OshiMessageEngine.seedFromDate(DateTime(2026, 10, d))).id,
    };
    expect(ids.length, greaterThan(1));
    expect(engine.pick(c, seed: 20261013, salt: 1).id, isNot(a.id));
    expect(OshiMessageEngine.seedFromDate(DateTime(2026, 1, 2)), 20260102);
  });

  test('全状況・全 mood を網羅し、examPace は日数が入る', () {
    final moods = <OshiMood>{};
    for (final sit in OshiSituation.values) {
      for (final st in [OshiMessageStrings.ja, OshiMessageStrings.en]) {
        expect(st.variants(sit).length, greaterThanOrEqualTo(3), reason: '$sit');
      }
      moods.add(OshiMessageEngine.moodOf(sit));
    }
    expect(moods, OshiMood.values.toSet());
    final m = engine.pick(const OshiMessageContext(examDaysLeft: 42), seed: 1);
    expect(m.text, contains('42'));
    expect(m.text, isNot(contains('{n}')));
  });

  test('文言に責める表現・脅しを含めない（ja/en 全文言）', () {
    for (final t in OshiMessageStrings.ja.allTexts) {
      for (final w in _banJa) {
        expect(t.contains(w), isFalse, reason: '"$t" contains "$w"');
      }
    }
    for (final t in OshiMessageStrings.en.allTexts) {
      for (final w in _banEn) {
        expect(t.toLowerCase().contains(w), isFalse, reason: '"$t" contains "$w"');
      }
    }
  });

  test('copyWith で一部だけ上書きできる', () {
    final st = OshiMessageStrings.ja.copyWith(messages: {
      OshiSituation.greeting: ['やあ'],
    });
    expect(OshiMessageEngine(strings: st).pick(const OshiMessageContext(), seed: 3).text, 'やあ');
    expect(st.variants(OshiSituation.streak), OshiMessageStrings.ja.variants(OshiSituation.streak));
  });

  testWidgets('表示してタップで別の一言に切り替わる・Semantics', (tester) async {
    final handle = tester.ensureSemantics();
    OshiMessage? changed;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OshiMessageBubble(
          situation: const OshiMessageContext(streakDays: 5),
          seed: 100,
          onChanged: (m) => changed = m,
        ),
      ),
    ));
    final first = OshiMessageStrings.ja.variants(OshiSituation.streak)[100 % 3];
    expect(find.text(first), findsOneWidget);
    expect(find.text('🌟'), findsOneWidget);
    final node = tester.getSemantics(find.byType(OshiMessageBubble));
    expect(node.label, first);
    expect(node.hint, OshiMessageStrings.ja.tapHint);
    await tester.tap(find.byType(OshiMessageBubble));
    await tester.pumpAndSettle();
    expect(find.text(first), findsNothing);
    expect(changed, isNotNull);
    expect(find.text(changed!.text), findsOneWidget);
    handle.dispose();
  });

  testWidgets('en の言語と reduce motion', (tester) async {
    await tester.pumpWidget(KitStringsScope(
      strings: KitStrings.en,
      child: const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: OshiMessageBubble(situation: OshiMessageContext(), seed: 0),
          ),
        ),
      ),
    ));
    expect(find.text(OshiMessageStrings.en.variants(OshiSituation.greeting)[0]), findsOneWidget);
  });
}
