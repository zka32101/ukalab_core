import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

WeeklyRecapDay d(int y, int m, int day, int a, int c, [String? t]) =>
    WeeklyRecapDay(date: DateTime(y, m, day), answered: a, correct: c, topicId: t);

void main() {
  // 2026-10-12 は月曜
  const engine = WeeklyRecapEngine();
  final wed = DateTime(2026, 10, 14, 15, 30);

  test('週境界: 月曜始まりで日曜までを数え、前後の週は入れない', () {
    final r = engine.build([
      d(2026, 10, 11, 9, 9), // 前週の日曜
      d(2026, 10, 12, 5, 4), // 月
      d(2026, 10, 18, 3, 3), // 日
      d(2026, 10, 19, 7, 7), // 次の月曜
    ], weekOf: wed);
    expect(r.weekStart, DateTime(2026, 10, 12));
    expect(r.answered, 8);
    expect(r.correct, 7);
    expect(r.studyDays, 2);
  });

  test('0件の週は isEmpty で、数値はすべて0', () {
    final r = engine.build([d(2026, 10, 5, 4, 2)], weekOf: wed, medalsEarned: 0);
    expect(r.isEmpty, isTrue);
    expect(r.studyDays, 0);
    expect(r.streakDays, 0);
    expect(r.topTopics, isEmpty);
    expect(r.accuracy, 0);
    expect(engine.build(const [], weekOf: wed).isEmpty, isTrue);
  });

  test('連続日数は週内の最長、answered 0 の日は数えない、同日は合算', () {
    final r = engine.build([
      d(2026, 10, 12, 2, 1),
      d(2026, 10, 12, 3, 3, 'a'), // 同日
      d(2026, 10, 13, 1, 1),
      d(2026, 10, 14, 0, 0), // 解いていない
      d(2026, 10, 15, 4, 2),
      d(2026, 10, 16, 4, 2),
      d(2026, 10, 17, 4, 2),
    ], weekOf: wed);
    expect(r.studyDays, 5);
    expect(r.streakDays, 3);
    expect(r.answered, 18);
  });

  test('topTopics は解いた数の多い順・同数は正解数→ID順、topCount で件数制限', () {
    final r = engine.build([
      d(2026, 10, 12, 5, 5, 'b'),
      d(2026, 10, 13, 5, 3, 'a'),
      d(2026, 10, 13, 9, 1, 'c'),
      d(2026, 10, 14, 2, 2, 'z'),
      d(2026, 10, 14, 4, 0), // 分野不明は分野に数えない
    ], weekOf: wed);
    expect([for (final t in r.topTopics) t.topicId], ['c', 'b', 'a']);
    final one = const WeeklyRecapEngine(topCount: 1).build([d(2026, 10, 12, 1, 1, 'q')], weekOf: wed);
    expect(one.topTopics.length, 1);
  });

  test('伸びた分野: 前週より正答率が上がり、両週で最低解答数がある分野だけ', () {
    final r = engine.build([
      d(2026, 10, 5, 4, 1, 'up'),
      d(2026, 10, 12, 4, 3, 'up'),
      d(2026, 10, 5, 4, 3, 'down'),
      d(2026, 10, 12, 4, 1, 'down'),
      d(2026, 10, 12, 4, 4, 'new'), // 前週なし
      d(2026, 10, 5, 2, 0, 'tiny'),
      d(2026, 10, 12, 4, 4, 'tiny'), // 前週のサンプル不足
    ], weekOf: wed);
    expect(r.improvedTopics, ['up']);
  });

  test('週の起点を日曜・水曜にできる', () {
    final days = [d(2026, 10, 11, 3, 3), d(2026, 10, 12, 2, 1)];
    final sun = const WeeklyRecapEngine(weekStartsOn: DateTime.sunday).build(days, weekOf: wed);
    expect(sun.weekStart, DateTime(2026, 10, 11));
    expect(sun.answered, 5);
    expect(sun.streakDays, 2);
    final mon = engine.build(days, weekOf: wed);
    expect(mon.answered, 2);
    final w = const WeeklyRecapEngine(weekStartsOn: DateTime.wednesday)
        .build(days, weekOf: DateTime(2026, 10, 14));
    expect(w.weekStart, DateTime(2026, 10, 14));
    expect(w.isEmpty, isTrue);
    // 月をまたぐ週の起点
    expect(engine.weekStartOf(DateTime(2026, 11, 1)), DateTime(2026, 10, 26));
  });

  test('不正な値は丸める（負数・correct>answered・メダル負数）', () {
    final r = engine.build([d(2026, 10, 12, 3, 9), d(2026, 10, 13, -2, 1)],
        weekOf: wed, medalsEarned: -1);
    expect(r.answered, 3);
    expect(r.correct, 3);
    expect(r.medalsEarned, 0);
  });

  test('ProgressRecord からのアダプタ（問題IDを引き継がない・日付×分野でまとめる）', () {
    ProgressRecord rec(int day, bool ok, String? topic) => ProgressRecord(
        qid: 'q$day$ok', subjectId: 's', correct: ok, at: DateTime(2026, 10, day, 10), topicId: topic);
    final days = weeklyRecapDaysFromRecords([
      rec(12, true, 'a'), rec(12, false, 'a'), rec(12, true, null), rec(13, true, 'a'),
    ]);
    expect(days.length, 3);
    final r = engine.build(days, weekOf: wed);
    expect(r.answered, 4);
    expect(r.correct, 3);
    expect(r.topTopics.single.answered, 3);
  });

  test('同じ入力なら同じ結果', () {
    final input = [d(2026, 10, 12, 5, 4, 'a'), d(2026, 10, 13, 5, 4, 'b')];
    final a = engine.build(input, weekOf: wed);
    final b = engine.build(input, weekOf: wed);
    expect(a.answered, b.answered);
    expect([for (final t in a.topTopics) t.topicId], [for (final t in b.topTopics) t.topicId]);
  });
}
