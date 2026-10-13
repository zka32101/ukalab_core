import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

MistakeNoteEntry note(String qid, int day, {bool overcome = false}) => MistakeNoteEntry(
      qid: qid,
      firstMissedAt: DateTime(2026, 10, day, 9),
      lastMissedAt: DateTime(2026, 10, day, 9),
      missCount: 1,
      overcome: overcome,
      lastAnsweredAt: DateTime(2026, 10, day, 9),
    );

void main() {
  const engine = ReviewSchedulerEngine();
  final now = DateTime(2026, 10, 10, 8);

  group('ReviewSchedulerEngine', () {
    test('新しく載った問題は段0で、間違えた翌日の0時から出る', () {
      final items = engine.sync(const [], [note('a', 10)]);
      expect(items.single.stage, 0);
      expect(items.single.dueAt, DateTime(2026, 10, 11));
      expect(engine.dueCount(items, DateTime(2026, 10, 10, 23, 59)), 0);
      expect(engine.dueCount(items, DateTime(2026, 10, 11)), 1);
    });

    test('正解で 1/3/7/14/30 日の順に進み、最後の段の正解で卒業する', () {
      var item = engine.sync(const [], [note('a', 1)]).single;
      final expectedDays = [3, 7, 14, 30];
      var t = DateTime(2026, 10, 2, 10);
      for (var i = 0; i < expectedDays.length; i++) {
        final reviewedOn = t;
        item = engine.review(item, correct: true, now: reviewedOn);
        expect(item.stage, i + 1);
        expect(item.dueAt, DateTime(reviewedOn.year, reviewedOn.month, reviewedOn.day + expectedDays[i]));
        expect(item.graduated, isFalse);
        t = item.dueAt.add(const Duration(hours: 9));
      }
      item = engine.review(item, correct: true, now: t);
      expect(item.graduated, isTrue);
      expect(engine.isDue(item, DateTime(2030)), isFalse);
    });

    test('不正解で1段戻る（段0は段0のまま）', () {
      var item = ReviewItem(
        qid: 'a', stage: 3, dueAt: DateTime(2026, 10, 1), lastReviewedAt: DateTime(2026, 9, 24),
      );
      item = engine.review(item, correct: false, now: now);
      expect(item.stage, 2);
      expect(item.dueAt, DateTime(2026, 10, 17)); // 段2=7日後
      item = engine.review(item.copyWith(stage: 0), correct: false, now: now);
      expect(item.stage, 0);
      expect(item.dueAt, DateTime(2026, 10, 11));
    });

    test('期限を過ぎていても出せる（超過は罰にならず、順序だけ古い順）', () {
      final items = [
        ReviewItem(qid: 'b', stage: 1, dueAt: DateTime(2026, 9, 1), lastReviewedAt: DateTime(2026, 8, 29)),
        ReviewItem(qid: 'a', stage: 0, dueAt: DateTime(2026, 10, 9), lastReviewedAt: DateTime(2026, 10, 8)),
      ];
      expect(engine.due(items, now).map((i) => i.qid), ['b', 'a']);
    });

    test('今日の期限分を最大N問。同順位は段の低い順→qid順で決定的', () {
      final d = DateTime(2026, 10, 10);
      final items = [
        ReviewItem(qid: 'c', stage: 2, dueAt: d, lastReviewedAt: d),
        ReviewItem(qid: 'b', stage: 0, dueAt: d, lastReviewedAt: d),
        ReviewItem(qid: 'a', stage: 0, dueAt: d, lastReviewedAt: d),
        ReviewItem(qid: 'z', stage: 0, dueAt: DateTime(2026, 10, 12), lastReviewedAt: d),
      ];
      expect(engine.due(items, now, max: 2).map((i) => i.qid), ['a', 'b']);
      expect(engine.due(items, now, max: 10).map((i) => i.qid), ['a', 'b', 'c']);
      expect(engine.due(items, now, max: 0), isEmpty);
      expect(engine.due(items.reversed, now).map((i) => i.qid), ['a', 'b', 'c']);
      expect(engine.dueCount(items, now), 3);
    });

    test('sync: 克服した問題・ノートから消えた問題は外れ、進行中の段は保たれる', () {
      var items = engine.sync(const [], [note('a', 1), note('b', 1)]);
      items = engine.applyResult(items, 'a', correct: true, now: DateTime(2026, 10, 2, 9));
      final again = engine.sync(items, [note('a', 1), note('b', 1, overcome: true)]);
      expect(again.map((i) => i.qid), ['a']);
      expect(again.single.stage, 1);
      expect(engine.sync(again, [note('a', 1)]), again); // 冪等
    });

    test('sync: 復習より後に間違えたら段0からやり直し、卒業後でも戻る', () {
      var item = engine.sync(const [], [note('a', 1)]).single;
      item = item.copyWith(stage: 4, graduated: true, lastReviewedAt: DateTime(2026, 10, 5, 9));
      final back = engine.sync([item], [note('a', 8)]).single;
      expect(back.stage, 0);
      expect(back.graduated, isFalse);
      expect(back.dueAt, DateTime(2026, 10, 9));
      // 卒業のまま、新しい間違いが無ければ再登場しない
      final kept = engine.sync([item], [note('a', 1)]).single;
      expect(kept.graduated, isTrue);
      expect(engine.dueCount([kept], DateTime(2027)), 0);
    });

    test('applyResult は対象外の qid を変えない', () {
      final items = engine.sync(const [], [note('a', 1), note('b', 1)]);
      final out = engine.applyResult(items, 'a', correct: true, now: now);
      expect(out.firstWhere((i) => i.qid == 'b'), items.firstWhere((i) => i.qid == 'b'));
      expect(out.firstWhere((i) => i.qid == 'a').stage, 1);
    });

    test('間隔はアプリ側で変えられる', () {
      const e = ReviewSchedulerEngine(intervals: [2, 5]);
      var item = e.sync(const [], [note('a', 1)]).single;
      expect(item.dueAt, DateTime(2026, 10, 3));
      item = e.review(item, correct: true, now: DateTime(2026, 10, 3, 9));
      expect(item.dueAt, DateTime(2026, 10, 8));
      expect(e.review(item, correct: true, now: DateTime(2026, 10, 8)).graduated, isTrue);
    });
  });

  group('ReviewItem JSON / Store', () {
    test('JSON は往復でき、壊れた入力は null', () {
      final i = ReviewItem(
        qid: 'a', stage: 2, dueAt: DateTime(2026, 10, 17), lastReviewedAt: DateTime(2026, 10, 10, 9),
        topicId: 't1', graduated: true,
      );
      expect(ReviewItem.fromJson(i.toJson()), i);
      expect(ReviewItem.fromJson(null), isNull);
      expect(ReviewItem.fromJson({'qid': 'a', 'stage': -1, 'dueAt': 'x'}), isNull);
      expect(ReviewItem.fromJson({'qid': '', 'stage': 0, 'dueAt': '2026-10-01', 'lastReviewedAt': '2026-10-01'}), isNull);
    });

    test('decode は壊れた値・不正な要素を無視する', () {
      expect(decodeReviewItems(null), isEmpty);
      expect(decodeReviewItems('not json'), isEmpty);
      final good = ReviewItem(qid: 'a', stage: 0, dueAt: DateTime(2026, 10, 11), lastReviewedAt: DateTime(2026, 10, 10));
      final enc = encodeReviewItems([good]);
      final raw = '[${enc.substring(1, enc.length - 1)},{"bad":1},5]';
      expect(decodeReviewItems(raw), [good]);
    });

    test('InMemory 実装', () async {
      final s = InMemoryReviewSchedulerStore();
      expect(await s.read(), isEmpty);
      final i = ReviewItem(qid: 'a', stage: 1, dueAt: DateTime(2026, 10, 13), lastReviewedAt: DateTime(2026, 10, 10));
      await s.write([i]);
      expect(await s.read(), [i]);
    });

    test('SharedPreferences 実装はアプリID別のキーに保存し、壊れた値は空', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SharedPreferencesReviewSchedulerStore('myapp');
      final i = ReviewItem(qid: 'a', stage: 1, dueAt: DateTime(2026, 10, 13), lastReviewedAt: DateTime(2026, 10, 10));
      await s.write([i]);
      expect(await s.read(), [i]);
      expect(await SharedPreferencesReviewSchedulerStore('other').read(), isEmpty);
      final p = await SharedPreferences.getInstance();
      expect(p.getString('ukalab_myapp_review_schedule'), isNotNull);
      await p.setString('ukalab_myapp_review_schedule', '{broken');
      expect(await s.read(), isEmpty);
    });

    testWidgets('DataPart: export / restore / reset', (t) async {
      final s = InMemoryReviewSchedulerStore();
      var changed = 0;
      final part = reviewSchedulerDataPart(s, onChanged: () => changed++);
      expect(part.id, 'reviewSchedule');
      final i = ReviewItem(qid: 'a', stage: 1, dueAt: DateTime(2026, 10, 13), lastReviewedAt: DateTime(2026, 10, 10));
      late WidgetRef ref;
      await t.pumpWidget(ProviderScope(
        child: Consumer(builder: (c, r, _) {
          ref = r;
          return const SizedBox();
        }),
      ));
      await t.runAsync(() async {
        await s.write([i]);
        final exported = (await part.export(ref)) as List;
        expect(exported.length, 1);
        await s.write(const []);
        await part.restore(ref, exported);
        expect(await s.read(), [i]);
        await part.restore(ref, 'broken');
        expect(await s.read(), isEmpty);
        await s.write([i]);
        await part.reset(ref);
        expect(await s.read(), isEmpty);
      });
      expect(changed, 3);
    });
  });

  group('ReviewSchedulerStrings', () {
    const banJa = [
      'サボ', 'さぼ', '遅れ', '遅い', 'ダメ', 'だめ', '駄目', 'ないと', 'なければ', 'べき', '怠',
      '失敗', '焦', '急が', '急い', '間に合わ', '足りな', 'わずか', '危', '残念', '少な', '減',
      'ワースト', '苦手ばかり', 'また間違', '最後', '多い', '順位', 'ランキング',
      '期限', '残り', '溜', '超過', '今すぐ',
    ];
    const banEn = [
      'lazy', 'behind', 'slack', 'skipp', 'must', 'have to', 'should', 'fail', 'hurry', 'rush',
      'running out', 'too late', 'disappoint', 'only ', 'worry', 'deadline', 'fewer', 'less ',
      'worst', 'again and again', 'missed', 'ranking', 'most ', 'overdue', 'left',
    ];

    test('禁止語を含まない', () {
      for (final t in ReviewSchedulerStrings.ja.allTexts) {
        for (final w in banJa) {
          expect(t.contains(w), isFalse, reason: '$t / $w');
        }
      }
      for (final t in ReviewSchedulerStrings.en.allTexts) {
        for (final w in banEn) {
          expect(t.toLowerCase().contains(w), isFalse, reason: '$t / $w');
        }
      }
    });

    test('件数の差し込みと言語切替、copyWith', () {
      expect(ReviewSchedulerStrings.ja.dueText(4), '4問、見返せるよ');
      expect(ReviewSchedulerStrings.forLanguageCode('en'), ReviewSchedulerStrings.en);
      expect(ReviewSchedulerStrings.forLanguageCode('ko'), ReviewSchedulerStrings.ja);
      expect(ReviewSchedulerStrings.ja.copyWith(start: 'GO').start, 'GO');
    });
  });
}
