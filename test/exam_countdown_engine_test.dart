import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

const _banJa = [
  'サボ', 'さぼ', '遅れ', '遅い', 'ダメ', 'だめ', '駄目', 'ないと', 'なければ', 'べき', '怠',
  '失敗', '焦', '急が', '急い', '間に合わ', '足りな', 'わずか', '危', '残念', '少な', '減',
  'しかない', '最後', '以下',
];
const _banEn = [
  'lazy', 'behind', 'slack', 'skipp', 'must', 'have to', 'should', 'fail', 'hurry', 'rush',
  'running out', 'too late', 'disappoint', 'only ', 'worry', 'deadline', 'fewer', 'less ',
  'drop', 'decline', 'missed', 'last chance', 'little time', 'hardly',
];

void main() {
  const engine = ExamCountdownEngine();
  final today = DateTime(2026, 10, 13);
  DateTime inDays(int n) => DateTime(2026, 10, 13 + n);

  group('phase の境界', () {
    final cases = <int, ExamCountdownPhase>{
      101: ExamCountdownPhase.farAway,
      100: ExamCountdownPhase.approaching,
      31: ExamCountdownPhase.approaching,
      30: ExamCountdownPhase.close,
      8: ExamCountdownPhase.close,
      7: ExamCountdownPhase.finalDays,
      1: ExamCountdownPhase.finalDays,
      0: ExamCountdownPhase.today,
      -1: ExamCountdownPhase.done,
    };
    cases.forEach((days, phase) {
      test('$days 日 -> $phase', () {
        final c = engine.compute(inDays(days), today: today);
        expect(c.daysLeft, days);
        expect(c.phase, phase);
      });
    });
  });

  test('未設定は none・daysLeft null', () {
    final c = engine.compute(null, today: today);
    expect(c.phase, ExamCountdownPhase.none);
    expect(c.daysLeft, isNull);
    expect(c.showsCount, isFalse);
  });

  test('showsCount は farAway〜finalDays のみ', () {
    expect(engine.compute(inDays(5), today: today).showsCount, isTrue);
    expect(engine.compute(inDays(0), today: today).showsCount, isFalse);
    expect(engine.compute(inDays(-3), today: today).showsCount, isFalse);
  });

  test('基準日の注入: 同じ試験日でも基準日で結果が変わる', () {
    final exam = DateTime(2026, 12, 1);
    expect(engine.compute(exam, today: DateTime(2026, 11, 30)).daysLeft, 1);
    expect(engine.compute(exam, today: DateTime(2026, 12, 1)).phase, ExamCountdownPhase.today);
    expect(engine.compute(exam, today: DateTime(2026, 12, 2)).phase, ExamCountdownPhase.done);
  });

  test('時刻は無視し暦日差で数える（23:59 と 00:00 でも 1 日）', () {
    final exam = DateTime(2026, 10, 14, 9, 30);
    expect(engine.compute(exam, today: DateTime(2026, 10, 13, 23, 59, 59)).daysLeft, 1);
    expect(engine.compute(exam, today: DateTime(2026, 10, 13, 0, 0, 1)).daysLeft, 1);
    expect(engine.compute(exam, today: DateTime(2026, 10, 14, 23, 59)).daysLeft, 0);
  });

  group('夏時間(DST)・月またぎ・年またぎ', () {
    // 暦日差は年月日だけで数えるため、実行環境のタイムゾーンに依らず結果が同じ。
    // 夏時間を持つ環境では `TZ=America/New_York flutter test` でも同じ結果になる。
    test('米国の春(2026-03-08, 23時間日)を跨いでも暦日差どおり', () {
      expect(engine.compute(DateTime(2026, 3, 9), today: DateTime(2026, 3, 7)).daysLeft, 2);
      expect(engine.compute(DateTime(2026, 3, 9), today: DateTime(2026, 3, 8, 23, 30)).daysLeft, 1);
      expect(engine.compute(DateTime(2026, 3, 8, 0, 30), today: DateTime(2026, 3, 7, 23, 30)).daysLeft, 1);
    });
    test('米国の秋(2026-11-01, 25時間日)を跨いでも暦日差どおり', () {
      expect(engine.compute(DateTime(2026, 11, 2), today: DateTime(2026, 10, 31)).daysLeft, 2);
      expect(engine.compute(DateTime(2026, 11, 2), today: DateTime(2026, 11, 1, 0, 10)).daysLeft, 1);
    });
    test('欧州の春(2026-03-29)・秋(2026-10-25)を跨いでも暦日差どおり', () {
      expect(engine.compute(DateTime(2026, 3, 30), today: DateTime(2026, 3, 28)).daysLeft, 2);
      expect(engine.compute(DateTime(2026, 10, 26), today: DateTime(2026, 10, 24)).daysLeft, 2);
    });
    test('100日 / 年またぎ', () {
      expect(engine.compute(DateTime(2026, 3, 20), today: DateTime(2025, 12, 10)).daysLeft, 100);
      expect(engine.compute(DateTime(2027, 1, 2), today: DateTime(2026, 12, 31)).daysLeft, 2);
    });
  });

  group('ExamCountdownStrings', () {
    test('ja の全文言に禁止語を含まない', () {
      for (final t in ExamCountdownStrings.ja.allTexts) {
        for (final w in _banJa) {
          expect(t.contains(w), isFalse, reason: '"$t" contains "$w"');
        }
      }
    });
    test('en の全文言に禁止語を含まない', () {
      for (final t in ExamCountdownStrings.en.allTexts) {
        for (final w in _banEn) {
          expect(t.toLowerCase().contains(w), isFalse, reason: '"$t" contains "$w"');
        }
      }
    });
    test('禁止語検査が実際に検出する', () {
      final bad = ExamCountdownStrings.ja.copyWith(paceFinal: '急がないとダメ');
      expect(bad.allTexts.any((t) => _banJa.any(t.contains)), isTrue);
    });
    test('終了後・未設定に今日できることは出さず、final 期も落ち着いた調子', () {
      final s = ExamCountdownStrings.ja;
      expect(s.todaySuggestion(ExamCountdownPhase.done), isNull);
      expect(s.todaySuggestion(ExamCountdownPhase.none), isNull);
      expect(s.pace(ExamCountdownPhase.finalDays), contains('いつもどおり'));
      expect(s.chip(engine.compute(inDays(-2), today: today)), 'おつかれさまでした');
      expect(s.chip(engine.compute(inDays(-2), today: today)).contains(RegExp(r'\d')), isFalse);
    });
    test('forLanguageCode は en 以外 ja', () {
      expect(ExamCountdownStrings.forLanguageCode('en'), same(ExamCountdownStrings.en));
      expect(ExamCountdownStrings.forLanguageCode('ko'), same(ExamCountdownStrings.ja));
    });
  });
}
