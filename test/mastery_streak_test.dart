import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

Question q(String id, {bool disabled = false}) => Question(
      qid: id,
      examId: 'sample',
      subjectId: 'math',
      topicId: 't',
      prompt: 'p',
      choices: const ['a', 'b', 'c'],
      answerIndex: 1,
      explanation: 'e',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
      disabled: disabled,
    );

AnswerRecord rec(String id, bool ok, PracticeMode mode) =>
    AnswerRecord(qid: id, correct: ok, ms: 0, at: DateTime(2026, 10, 1), mode: mode);

void main() {
  group('MasteryStreak', () {
    test('正解で+1、2回で除外、不正解で0に戻り自動解除', () {
      var m = MasteryStreak.empty.record('a', true);
      expect(m.streakOf('a'), 1);
      expect(m.isExcluded('a'), isFalse);
      m = m.record('a', true);
      expect(m.isExcluded('a'), isTrue);
      expect(m.excludedCount, 1);
      m = m.record('a', false);
      expect(m.streakOf('a'), 0);
      expect(m.isExcluded('a'), isFalse);
      m = m.record('a', true).record('a', false).record('a', true);
      expect(m.isExcluded('a'), isFalse);
    });

    test('模擬試験・復習は影響しない（練習のみ）', () {
      var m = MasteryStreak.empty.recordAnswer(rec('a', true, PracticeMode.practice));
      m = m.recordAnswer(rec('a', true, PracticeMode.mock));
      m = m.recordAnswer(rec('a', true, PracticeMode.weak));
      expect(m.streakOf('a'), 1);
      expect(m.isExcluded('a'), isFalse);
      m = m.recordAnswer(rec('a', false, PracticeMode.mock));
      expect(m.streakOf('a'), 1);
    });

    test('JSON往復と壊れた値', () {
      final m = MasteryStreak.empty.record('a', true).record('b', true).record('b', true);
      final back = MasteryStreak.fromJson(jsonDecode(jsonEncode(m.toJson())));
      expect(back.streakOf('a'), 1);
      expect(back.excluded, {'b'});
      expect(MasteryStreak.fromJson('x').excludedCount, 0);
      expect(decodeMasteryStreak('{{').excludedCount, 0);
      expect(decodeMasteryStreak(null).excludedCount, 0);
    });

    test('全件戻すと連続数も除外も空', () {
      final m = MasteryStreak.empty.record('a', true).record('a', true).restoreAll();
      expect(m.excludedCount, 0);
      expect(m.streakOf('a'), 0);
    });
  });

  group('出題プール', () {
    final pool = [for (var i = 0; i < 10; i++) q('q$i')];

    test('除外qidは出題されない（新形式問題も qid 単位）', () {
      final s = PracticeSession(pool: pool, size: 10, seed: 1, excludeQids: {'q1', 'q2'});
      expect(s.questions.map((e) => e.qid), isNot(contains('q1')));
      expect(s.questions.length, 8);
      final f = withoutExcluded(pool, {'q3'});
      expect(f.map((e) => e.qid), isNot(contains('q3')));
    });

    test('優先指定された除外qidも出ない', () {
      final s = PracticeSession(pool: pool, size: 3, priorityQids: ['q1'], excludeQids: {'q1'});
      expect(s.questions.map((e) => e.qid), isNot(contains('q1')));
    });

    test('除外を渡さなければ従来どおり、同じseedで決定的', () {
      final a = PracticeSession(pool: pool, size: 10, seed: 7).questions.map((e) => e.qid).toList();
      final b = PracticeSession(pool: pool, size: 10, seed: 7).questions.map((e) => e.qid).toList();
      expect(a, b);
      final c = PracticeSession(pool: pool, size: 10, seed: 7, excludeQids: {'q0'})
          .questions
          .map((e) => e.qid)
          .toList();
      final d = PracticeSession(pool: pool, size: 10, seed: 7, excludeQids: {'q0'})
          .questions
          .map((e) => e.qid)
          .toList();
      expect(c, d);
    });

    test('全件除外でも落ちず、判定関数が true', () {
      final all = {for (final p in pool) p.qid};
      expect(PracticeSession(pool: pool, size: 5, excludeQids: all).questions, isEmpty);
      expect(isAllMastered(pool, all), isTrue);
      expect(isAllMastered(pool, {'q0'}), isFalse);
      expect(isAllMastered(const [], {}), isFalse);
      expect(isAllMastered([q('x', disabled: true), q('y')], {'y'}), isTrue);
    });
  });

  group('ストア', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('履歴が2000件を超えても専用ストアに保持される', () async {
      final store = SharedPreferencesMasteryStore('app');
      var m = MasteryStreak.empty;
      for (var i = 0; i < 2500; i++) {
        m = m.record('q$i', true).record('q$i', true);
      }
      await store.write(m);
      final back = await SharedPreferencesMasteryStore('app').read();
      expect(back.excludedCount, 2500);
      final p = await SharedPreferences.getInstance();
      expect(p.getString('ukalab_app_streak_v1'), isNotNull);
    });

    test('ON/OFFは既定OFFで保存される', () async {
      final store = SharedPreferencesMasteryStore('app');
      expect(await store.readEnabled(), isFalse);
      await store.writeEnabled(true);
      expect(await store.readEnabled(), isTrue);
    });
  });

  group('バックアップ・リセット・設定UI', () {
    testWidgets('書き出し→リセット→復元。ON/OFFはリセットされない', (tester) async {
      final store = InMemoryMasteryStore();
      await store.writeEnabled(true);
      await store.write(MasteryStreak.empty.record('a', true).record('a', true));
      final parts = [masteryStreakDataPart(store)];
      late WidgetRef ref;
      await tester.pumpWidget(ProviderScope(
        child: Consumer(builder: (c, r, _) {
          ref = r;
          return const SizedBox();
        }),
      ));
      final text = await encodeLearningDataBackupAsync(ref, parts);
      await resetLearningData(ref, parts);
      expect((await store.read()).excludedCount, 0);
      expect(await store.readEnabled(), isTrue);
      await restoreLearningDataBackup(ref, parts, text);
      expect((await store.read()).isExcluded('a'), isTrue);
    });

    testWidgets('設定: 件数表示・切替・全件戻す', (tester) async {
      final store = InMemoryMasteryStore();
      await store.write(MasteryStreak.empty.record('a', true).record('a', true));
      bool? lastEnabled;
      MasteryStreak? lastStreak;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MasterySettingsTile(
            store: store,
            onChanged: (e, s) {
              lastEnabled = e;
              lastStreak = s;
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('除外中の問題: 1問'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(lastEnabled, isTrue);
      expect(await store.readEnabled(), isTrue);
      await tester.tap(find.text('除外した問題を戻す（全件）'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('戻す'));
      await tester.pumpAndSettle();
      expect(lastStreak?.excludedCount, 0);
      expect((await store.read()).excludedCount, 0);
      expect(find.text('除外中の問題: 0問'), findsOneWidget);
    });
  });
}
