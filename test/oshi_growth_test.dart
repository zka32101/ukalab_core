import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

OshiGrowthProgress p(int a, int d) => OshiGrowthProgress(totalAnswered: a, studyDays: d);

const _banned = [
  'サボ', '遅れ', '遅い', 'ないと', 'ダメ', '焦', 'もっと', 'まだ', '途切れ', 'リセット', '無駄',
  '少なかった', '減った', '先週より', '急い', '早く', 'あと{n}', '失', '怠',
  'lazy', 'behind', 'must', 'hurry', 'only', 'lost', 'broke', 'reset', 'less than', 'fall',
];

void main() {
  const engine = OshiGrowthEngine();

  group('stage', () {
    test('回答数と学習日数の進んでいる方で決まる', () {
      expect(OshiGrowthEngine.stageOf(p(0, 0)), OshiGrowthStage.newcomer);
      expect(OshiGrowthEngine.stageOf(p(9, 6)), OshiGrowthStage.newcomer);
      expect(OshiGrowthEngine.stageOf(p(10, 0)), OshiGrowthStage.budding);
      expect(OshiGrowthEngine.stageOf(p(0, 7)), OshiGrowthStage.budding);
      expect(OshiGrowthEngine.stageOf(p(99, 29)), OshiGrowthStage.budding);
      expect(OshiGrowthEngine.stageOf(p(100, 0)), OshiGrowthStage.growing);
      expect(OshiGrowthEngine.stageOf(p(0, 30)), OshiGrowthStage.growing);
      expect(OshiGrowthEngine.stageOf(p(300, 0)), OshiGrowthStage.blooming);
      expect(OshiGrowthEngine.stageOf(p(0, 100)), OshiGrowthStage.blooming);
      expect(OshiGrowthEngine.stageOf(p(999, 99)), OshiGrowthStage.blooming);
      expect(OshiGrowthEngine.stageOf(p(1000, 0)), OshiGrowthStage.radiant);
    });

    test('負の値は 0 として扱う', () {
      expect(OshiGrowthEngine.stageOf(p(-5, -1)), OshiGrowthStage.newcomer);
      expect(p(-5, -1).totalAnswered, 0);
    });

    test('累計は増えるだけなので段階は下がらない（休んでも変わらない）', () {
      var prev = 0;
      for (var a = 0; a <= 1200; a += 7) {
        final i = OshiGrowthEngine.stageOf(p(a, a ~/ 20)).index;
        expect(i, greaterThanOrEqualTo(prev));
        prev = i;
      }
    });
  });

  group('reaction', () {
    test('同じ seed で同じ結果、salt で別の言い回し', () {
      final a = engine.reaction(p(120, 10), seed: 20261013);
      final b = engine.reaction(p(120, 10), seed: 20261013);
      expect(a.id, b.id);
      expect(a.text, b.text);
      expect(a.stage, OshiGrowthStage.growing);
      final c = engine.reaction(p(120, 10), seed: 20261013, salt: 1);
      expect(c.text, isNot(a.text));
      expect(a.emoji, isNotEmpty);
      expect(a.label, isNotEmpty);
    });

    test('全段階に 3 件以上の言い回しと表情がある（ja・en）', () {
      for (final s in [OshiGrowthStrings.ja, OshiGrowthStrings.en]) {
        for (final st in OshiGrowthStage.values) {
          final t = s.stageText(st);
          expect(t.messages.length, greaterThanOrEqualTo(3), reason: '$st');
          expect(t.emoji, isNotEmpty);
          expect(t.label, isNotEmpty);
        }
      }
    });
  });

  group('milestones', () {
    test('ID は固定', () {
      expect([for (final m in OshiGrowthEngine.defaultMilestones) m.id], [
        'answered_10', 'days_7', 'answered_50', 'days_30',
        'answered_100', 'days_100', 'answered_300', 'answered_1000',
      ]);
    });

    test('境界: 9問は未到達、10問で到達', () {
      expect(engine.newlyReached(p(9, 0)), isEmpty);
      expect([for (final m in engine.newlyReached(p(10, 0))) m.id], ['answered_10']);
      expect(engine.newlyReached(p(0, 6)), isEmpty);
      expect([for (final m in engine.newlyReached(p(0, 7))) m.id], ['days_7']);
    });

    test('既出は除外され、冪等', () {
      final first = engine.newlyReached(p(60, 8));
      expect([for (final m in first) m.id], ['answered_10', 'days_7', 'answered_50']);
      final done = {for (final m in first) m.id};
      expect(engine.newlyReached(p(60, 8), alreadyCelebrated: done), isEmpty);
      expect([for (final m in engine.newlyReached(p(100, 8), alreadyCelebrated: done)) m.id],
          ['answered_100']);
    });

    test('headlineOf は定義の中で最後のもの、空なら null', () {
      final all = engine.reached(p(1000, 100));
      expect(engine.headlineOf(all)!.id, 'answered_1000');
      expect(engine.headlineOf(engine.reached(p(10, 7)))!.id, 'days_7');
      expect(engine.headlineOf(const []), isNull);
    });

    test('独自の節目も使え、専用文言が無ければ既定の本文に {n} が入る', () {
      const e = OshiGrowthEngine(milestones: [OshiGrowthMilestone.answered(25)]);
      final c = e.celebrate(e.newlyReached(p(25, 0)).single);
      expect(c.title, '25問に到達');
      expect(c.body, contains('25'));
      expect(c.body, isNot(contains('{n}')));
    });

    test('celebrate は節目ごとの文言を返す（{n} 残りなし）', () {
      for (final s in [OshiGrowthStrings.ja, OshiGrowthStrings.en]) {
        final e = OshiGrowthEngine(strings: s);
        for (final m in OshiGrowthEngine.defaultMilestones) {
          final c = e.celebrate(m);
          expect(c.title, contains('${m.threshold}'));
          expect(c.title, isNot(contains('{n}')));
          expect(c.body, isNotEmpty);
          expect(c.body, isNot(contains('{n}')));
          expect(s.milestoneBodies.containsKey(m.id), isTrue, reason: m.id);
        }
      }
    });
  });

  group('strings', () {
    test('責める・煽る語を含まない', () {
      for (final s in [OshiGrowthStrings.ja, OshiGrowthStrings.en]) {
        for (final t in s.allTexts) {
          for (final w in _banned) {
            expect(t.toLowerCase().contains(w.toLowerCase()), isFalse, reason: '"$t" has "$w"');
          }
        }
      }
    });

    test('copyWith で一部だけ差し替え、forLanguageCode', () {
      final s = OshiGrowthStrings.ja.copyWith(close: 'OK');
      expect(s.close, 'OK');
      expect(s.tapHint, OshiGrowthStrings.ja.tapHint);
      expect(OshiGrowthStrings.forLanguageCode('en'), same(OshiGrowthStrings.en));
      expect(OshiGrowthStrings.forLanguageCode('ko'), same(OshiGrowthStrings.ja));
    });
  });

  group('service', () {
    test('一度だけ祝い、再度呼ぶと空', () async {
      final svc = OshiGrowthService(store: InMemoryOshiGrowthStore());
      await svc.load();
      expect([for (final m in await svc.check(p(10, 0))) m.id], ['answered_10']);
      expect(svc.isCelebrated('answered_10'), isTrue);
      expect(await svc.check(p(10, 0)), isEmpty);
      expect(await svc.check(p(49, 6)), isEmpty);
      expect([for (final m in await svc.check(p(50, 7))) m.id], ['days_7', 'answered_50']);
    });

    test('複数同時到達は全て記録し、見せるのは 1 件', () async {
      final store = InMemoryOshiGrowthStore();
      final svc = OshiGrowthService(store: store);
      await svc.load();
      final head = await svc.checkHeadline(p(300, 30));
      expect(head!.id, 'answered_300');
      expect(await store.read(), containsAll(['answered_10', 'days_7', 'answered_50', 'days_30', 'answered_100', 'answered_300']));
      expect(await svc.checkHeadline(p(300, 30)), isNull);
    });

    test('保存済みを load で復元（再起動後も再度祝わない）', () async {
      final store = InMemoryOshiGrowthStore();
      final a = OshiGrowthService(store: store);
      await a.load();
      await a.check(p(100, 0));
      final b = OshiGrowthService(store: store);
      await b.load();
      expect(await b.check(p(100, 0)), isEmpty);
    });

    test('保存に失敗したら記録せず、次回また祝える', () async {
      final store = _FailingStore();
      final svc = OshiGrowthService(store: store);
      await svc.load();
      await expectLater(svc.check(p(10, 0)), throwsStateError);
      expect(svc.isCelebrated('answered_10'), isFalse);
      store.fail = false;
      expect([for (final m in await svc.check(p(10, 0))) m.id], ['answered_10']);
    });

    test('SharedPreferences 実装: 保存・復元・アプリ別キー・壊れた値', () async {
      SharedPreferences.setMockInitialValues({});
      final a = SharedPreferencesOshiGrowthStore('app_a');
      expect(await a.read(), isEmpty);
      await a.write({'answered_10', 'days_7'});
      expect(await SharedPreferencesOshiGrowthStore('app_a').read(), {'answered_10', 'days_7'});
      expect(await SharedPreferencesOshiGrowthStore('app_b').read(), isEmpty);
      SharedPreferences.setMockInitialValues({'ukalab_oshi_growth_app_a': 'not json'});
      expect(await a.read(), isEmpty);
    });
  });
}

class _FailingStore implements OshiGrowthStore {
  bool fail = true;
  Set<String> _ids = {};

  @override
  Future<Set<String>> read() async => {..._ids};

  @override
  Future<void> write(Set<String> ids) async {
    if (fail) throw StateError('disk full');
    _ids = {...ids};
  }
}
