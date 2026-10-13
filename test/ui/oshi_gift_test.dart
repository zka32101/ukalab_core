import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

const _gifts = [
  OshiGift(
    id: 'bg_streak7',
    kind: OshiGiftKind.background,
    condition: OshiGiftCondition.streakDays(7),
    name: '夕焼けの背景',
  ),
  OshiGift(
    id: 'outfit_medal',
    kind: OshiGiftKind.outfit,
    condition: OshiGiftCondition.medal('streak7'),
    name: 'お祝いの衣装',
  ),
  OshiGift(
    id: 'outfit_mock',
    kind: OshiGiftKind.outfit,
    condition: OshiGiftCondition.mockPass(),
    name: '合格の衣装',
  ),
];

List<String> _ids(List<OshiGiftSpec> l) => [for (final g in l) g.id];

void main() {
  const engine = OshiGiftEngine();

  group('OshiGiftEngine', () {
    test('条件別に解放される', () {
      List<String> run(OshiGiftProgress p) =>
          _ids(engine.newlyUnlocked(progress: p, gifts: _gifts));
      expect(run(const OshiGiftProgress()), isEmpty);
      expect(run(const OshiGiftProgress(streakDays: 6)), isEmpty);
      expect(run(const OshiGiftProgress(streakDays: 7)), ['bg_streak7']);
      expect(run(const OshiGiftProgress(streakDays: 30)), ['bg_streak7']);
      expect(run(const OshiGiftProgress(earnedMedalIds: {'streak7'})), ['outfit_medal']);
      expect(run(const OshiGiftProgress(earnedMedalIds: {'other'})), isEmpty);
      expect(run(const OshiGiftProgress(mockPassed: true)), ['outfit_mock']);
      expect(
        run(const OshiGiftProgress(streakDays: 7, earnedMedalIds: {'streak7'}, mockPassed: true)),
        ['bg_streak7', 'outfit_medal', 'outfit_mock'],
      );
    });

    test('既解放IDは除外される', () {
      const p = OshiGiftProgress(streakDays: 7, mockPassed: true);
      final r = engine.newlyUnlocked(
        progress: p,
        gifts: _gifts,
        alreadyUnlocked: {'bg_streak7'},
      );
      expect(_ids(r), ['outfit_mock']);
    });

    test('冪等（同じ入力なら同じ結果、入力を変更しない）、重複idは1回だけ', () {
      const p = OshiGiftProgress(streakDays: 10, mockPassed: true);
      final seen = <String>{'x'};
      final a = engine.newlyUnlocked(progress: p, gifts: _gifts, alreadyUnlocked: seen);
      final b = engine.newlyUnlocked(progress: p, gifts: _gifts, alreadyUnlocked: seen);
      expect(_ids(a), _ids(b));
      expect(seen, {'x'});
      final dup = engine.newlyUnlocked(progress: p, gifts: [_gifts[0], _gifts[0]]);
      expect(dup.length, 1);
    });
  });

  group('OshiGiftService / store', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('check は新規だけ返し、再実行は空', () async {
      final svc = OshiGiftService(store: InMemoryOshiGiftStore());
      await svc.load();
      const p = OshiGiftProgress(streakDays: 7);
      expect(_ids(await svc.check(p, _gifts)), ['bg_streak7']);
      expect(await svc.check(p, _gifts), isEmpty);
      expect(svc.isUnlocked('bg_streak7'), isTrue);
    });

    test('SharedPreferences に保存して復元できる・アプリごとに別', () async {
      final a = OshiGiftService(store: SharedPreferencesOshiGiftStore('app1'));
      await a.load();
      await a.check(const OshiGiftProgress(streakDays: 7, mockPassed: true), _gifts);
      final b = OshiGiftService(store: SharedPreferencesOshiGiftStore('app1'));
      await b.load();
      expect(b.unlockedIds, {'bg_streak7', 'outfit_mock'});
      expect(
        _ids(await b.check(const OshiGiftProgress(streakDays: 7, mockPassed: true), _gifts)),
        isEmpty,
      );
      final other = OshiGiftService(store: SharedPreferencesOshiGiftStore('app2'));
      await other.load();
      expect(other.unlockedIds, isEmpty);
    });

    test('壊れた保存値は空として読む', () async {
      SharedPreferences.setMockInitialValues({'ukalab_oshi_gift_app1': 'not json'});
      expect(await SharedPreferencesOshiGiftStore('app1').read(), isEmpty);
    });
  });

  test('文言に責める表現・脅しを含めない（ja/en 全文言）と、全条件・種類の文言', () {
    for (final t in OshiGiftStrings.ja.allTexts) {
      for (final w in _banJa) {
        expect(t.contains(w), isFalse, reason: '"$t" contains "$w"');
      }
    }
    for (final t in OshiGiftStrings.en.allTexts) {
      for (final w in _banEn) {
        expect(t.toLowerCase().contains(w), isFalse, reason: '"$t" contains "$w"');
      }
    }
    for (final st in [OshiGiftStrings.ja, OshiGiftStrings.en]) {
      for (final g in _gifts) {
        expect(st.bodyOf(g), contains(g.name));
        expect(st.reasonOf(g), isNotEmpty);
        expect(st.reasonOf(g), isNot(contains('{')));
        expect(st.titleOf(g.kind), isNotEmpty);
      }
    }
    expect(OshiGiftStrings.ja.reasonOf(_gifts[0]), contains('7'));
  });

  test('copyWith で一部だけ上書きできる', () {
    final st = OshiGiftStrings.ja.copyWith(close: 'OK');
    expect(st.close, 'OK');
    expect(st.titleOutfit, OshiGiftStrings.ja.titleOutfit);
  });

  Widget host(void Function(BuildContext) onTap, {bool reduce = false, Widget? wrap}) =>
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: Builder(
            builder: (c) => Scaffold(
              body: TextButton(onPressed: () => onTap(c), child: const Text('open')),
            ),
          ),
        ),
      );

  testWidgets('背景ギフト: 画像なしでもダイアログが出て、閉じられる・Semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host((c) => showOshiGiftDialog(c, gift: _gifts[0])));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('背景のプレゼント'), findsOneWidget);
    expect(find.textContaining('夕焼けの背景'), findsOneWidget);
    expect(find.text('7日つづけたお祝いだよ。'), findsOneWidget);
    expect(find.text('仮の表示です'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('背景のプレゼント。.*夕焼けの背景')),
      findsOneWidget,
    );
    await tester.tap(find.text('ありがとう'));
    await tester.pumpAndSettle();
    expect(find.text('背景のプレゼント'), findsNothing);
    handle.dispose();
  });

  testWidgets('衣装ギフト: プレースホルダのアイコンと reduce motion', (tester) async {
    await tester.pumpWidget(host(
      (c) => showOshiGiftDialog(c, gift: _gifts[1]),
      reduce: true,
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('衣装のプレゼント'), findsOneWidget);
    expect(find.byIcon(Icons.checkroom), findsOneWidget);
    expect(find.text('メダル獲得のお祝いだよ。'), findsOneWidget);
  });

  testWidgets('en の言語と文言の上書き', (tester) async {
    await tester.pumpWidget(KitStringsScope(
      strings: KitStrings.en,
      child: host((c) => showOshiGiftDialog(c, gift: _gifts[2])),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('A gift: new outfit'), findsOneWidget);
    expect(find.text('Thank you'), findsOneWidget);
    await tester.tap(find.text('Thank you'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(host(
      (c) => showOshiGiftDialog(
        c,
        gift: _gifts[2],
        strings: OshiGiftStrings.ja.copyWith(titleOutfit: 'とどけもの', close: '閉じる'),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('とどけもの'), findsOneWidget);
    expect(find.text('閉じる'), findsOneWidget);
  });
}
