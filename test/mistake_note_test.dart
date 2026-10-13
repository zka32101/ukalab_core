import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

ProgressRecord r(String qid, bool ok, int day, {WrongCause? cause, String? topic, int hour = 9}) =>
    ProgressRecord(
      qid: qid,
      subjectId: 's',
      correct: ok,
      at: DateTime(2026, 10, day, hour),
      cause: cause,
      topicId: topic,
    );

void main() {
  const engine = MistakeNoteEngine();

  group('MistakeNoteEngine', () {
    test('間違えた問題だけが載り、正解のみの問題は載らない', () {
      final n = engine.build([r('a', true, 1), r('b', false, 2)]);
      expect(n.map((e) => e.qid), ['b']);
      expect(n.single.missCount, 1);
      expect(n.single.overcome, isFalse);
    });

    test('克服: 間違えたあと連続2回正解（1回では克服しない）', () {
      var n = engine.build([r('a', false, 1), r('a', true, 2)]);
      expect(n.single.overcome, isFalse);
      n = engine.build([r('a', false, 1), r('a', true, 2), r('a', true, 3)]);
      expect(n.single.overcome, isTrue);
      expect(n.single.firstMissedAt, DateTime(2026, 10, 1, 9));
    });

    test('途中で間違えると連続は戻り、克服後に間違えたら「これから」に戻る', () {
      var n = engine.build([r('a', false, 1), r('a', true, 2), r('a', false, 3), r('a', true, 4)]);
      expect(n.single.overcome, isFalse);
      expect(n.single.missCount, 2);
      expect(n.single.lastMissedAt, DateTime(2026, 10, 3, 9));
      n = engine.build([
        r('a', false, 1), r('a', true, 2), r('a', true, 3), r('a', false, 4),
      ]);
      expect(n.single.overcome, isFalse);
    });

    test('N の違い: 1 なら1回、3 なら3回', () {
      final recs = [r('a', false, 1), r('a', true, 2), r('a', true, 3)];
      expect(const MistakeNoteEngine(overcomeStreak: 1).build(recs.take(2)).single.overcome, isTrue);
      expect(const MistakeNoteEngine(overcomeStreak: 3).build(recs).single.overcome, isFalse);
      expect(
        const MistakeNoteEngine(overcomeStreak: 3).build([...recs, r('a', true, 4)]).single.overcome,
        isTrue,
      );
    });

    test('入力順に依存しない・決定的・冪等', () {
      final recs = [r('a', false, 1), r('a', true, 2), r('b', false, 3), r('a', true, 4)];
      final x = engine.build(recs);
      expect(engine.build(recs.reversed), x);
      expect(engine.build(recs), x);
      // 同じ履歴をもう一度取り込んでも変わらない
      expect(engine.update(x, recs), x);
      // 履歴が切り捨てられてもノートは残る
      expect(engine.update(x, const []), x);
    });

    test('差分更新: 新しい正解だけ渡しても克服に進む', () {
      final first = engine.build([r('a', false, 1), r('a', true, 2)]);
      final next = engine.update(first, [r('a', true, 3)]);
      expect(next.single.overcome, isTrue);
      expect(engine.newlyOvercome(first, next), ['a']);
      expect(engine.newlyOvercome(next, next), isEmpty);
    });

    test('cause と topicId を反映（原因を選んだ直近の間違い・直近の分野）', () {
      final n = engine.build([
        r('a', false, 1, cause: WrongCause.trap, topic: 't1'),
        r('a', false, 2),
        r('b', false, 2, cause: WrongCause.misread),
      ]);
      final a = n.firstWhere((e) => e.qid == 'a');
      expect(a.lastCause, WrongCause.trap);
      expect(a.topicId, 't1');
      expect(n.firstWhere((e) => e.qid == 'b').lastCause, WrongCause.misread);
      expect(n.firstWhere((e) => e.qid == 'b').topicId, isNull);
    });

    test('並びは直近の間違い順（件数順ではない）', () {
      final n = engine.build([
        r('many', false, 1), r('many', false, 2), r('many', false, 3),
        r('once', false, 5),
        r('mid', false, 4),
      ]);
      expect(n.map((e) => e.qid), ['once', 'mid', 'many']);
    });

    test('JSON 往復と壊れた要素', () {
      final e = engine.build([r('a', false, 1, cause: WrongCause.knowledge, topic: 't')]).single;
      expect(MistakeNoteEntry.fromJson(e.toJson()), e);
      expect(MistakeNoteEntry.fromJson('x'), isNull);
      expect(MistakeNoteEntry.fromJson({'qid': 'a'}), isNull);
      expect(e.toJson().keys, isNot(contains('subjectId')));
    });
  });

  group('MistakeNoteStore', () {
    final entries = engine.build([r('a', false, 1, cause: WrongCause.trap, topic: 't'), r('b', false, 2)]);

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('InMemory の保存と復元', () async {
      final s = InMemoryMistakeNoteStore();
      expect(await s.read(), isEmpty);
      await s.write(entries);
      expect(await s.read(), entries);
    });

    test('SharedPreferences の保存と復元、アプリIDでキーが分かれる', () async {
      final a = SharedPreferencesMistakeNoteStore('app1');
      final b = SharedPreferencesMistakeNoteStore('app2');
      await a.write(entries);
      expect(await a.read(), entries);
      expect(await b.read(), isEmpty);
      final p = await SharedPreferences.getInstance();
      expect(p.getKeys(), {'ukalab_app1_mistake_notes'});
    });

    test('壊れた保存値は空、一部だけ壊れていれば読めた分を復元', () async {
      SharedPreferences.setMockInitialValues({'ukalab_app1_mistake_notes': '{not json'});
      expect(await SharedPreferencesMistakeNoteStore('app1').read(), isEmpty);
      SharedPreferences.setMockInitialValues({'ukalab_app1_mistake_notes': '{"a":1}'});
      expect(await SharedPreferencesMistakeNoteStore('app1').read(), isEmpty);
      final mixed = '[${encodeMistakeNotes(entries).substring(1, encodeMistakeNotes(entries).length - 1)},42,{"qid":1}]';
      expect(decodeMistakeNotes(mixed).length, 2);
    });

    test('保存内容に問題文・個人情報の欄がない', () {
      final raw = encodeMistakeNotes(entries);
      for (final k in ['question', 'name', 'email', 'userId', 'subjectId']) {
        expect(raw.contains('"$k"'), isFalse);
      }
    });

    testWidgets('DataPart: 書き出し・リセット・読み込み・壊れた値', (tester) async {
      late WidgetRef ref;
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(home: Consumer(builder: (c, r, _) {
          ref = r;
          return const SizedBox();
        })),
      ));
      final s = InMemoryMistakeNoteStore();
      await s.write(entries);
      var changed = 0;
      final parts = [mistakeNoteDataPart(s, onChanged: () => changed++)];
      final text = await encodeLearningDataBackupAsync(ref, parts, now: DateTime(2026, 10, 13));
      expect((jsonDecode(text)['parts'] as Map).keys, ['mistakeNotes']);
      await resetLearningData(ref, parts);
      expect(await s.read(), isEmpty);
      await restoreLearningDataBackup(ref, parts, text);
      expect(await s.read(), entries);
      await restoreLearningDataBackup(ref, parts, '{"version":1,"parts":{"mistakeNotes":"broken"}}');
      expect(await s.read(), isEmpty);
      expect(changed, 3);
    });
  });
}
