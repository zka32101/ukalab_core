import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

void main() {
  final now = DateTime(2026, 10, 24, 15, 30);

  test('当日は 1 日として数える', () {
    expect(dailyGoal(examDate: DateTime(2026, 10, 24), unmasteredCount: 100, now: now), 130);
  });

  test('前日（残り 1 日）', () {
    expect(dailyGoal(examDate: DateTime(2026, 10, 25), unmasteredCount: 100, now: now), 130);
  });

  test('過去は null', () {
    expect(dailyGoal(examDate: DateTime(2026, 10, 23), unmasteredCount: 100, now: now), isNull);
  });

  test('時刻付きでも暦日で数える', () {
    final late = DateTime(2026, 10, 24, 23, 59);
    expect(dailyGoal(examDate: DateTime(2026, 10, 27, 0, 1), unmasteredCount: 30, now: late),
        (30 * 1.3 / 3).ceil());
    // 試験日の朝 9:00 の試験・現在 23:59 でも当日扱い
    expect(dailyGoal(examDate: DateTime(2026, 10, 24, 9), unmasteredCount: 10, now: late), 13);
  });

  test('未習得 0 は 0（過去でなければ）', () {
    expect(dailyGoal(examDate: DateTime(2026, 11, 1), unmasteredCount: 0, now: now), 0);
    expect(dailyGoal(examDate: DateTime(2026, 10, 24), unmasteredCount: 0, now: now), 0);
  });

  test('端数は切り上げ', () {
    // 10 * 1.3 / 4 = 3.25 -> 4
    expect(dailyGoal(examDate: DateTime(2026, 10, 28), unmasteredCount: 10, now: now), 4);
    // 1 問・30 日 -> 0.043 -> 1
    expect(dailyGoal(examDate: DateTime(2026, 11, 23), unmasteredCount: 1, now: now), 1);
  });

  test('bufferFactor を変えられる', () {
    expect(
        dailyGoal(examDate: DateTime(2026, 10, 28), unmasteredCount: 8, now: now, bufferFactor: 1.0),
        2);
  });
}
