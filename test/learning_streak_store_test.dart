import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ukalab_core/learning.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('初回に記録すると連続日数は1になる', () async {
    final now = DateTime(2026, 10, 6);
    await recordStudyToday(now: now);
    expect(await loadCurrentStreak(now: now), 1);
  });

  test('前日に続けて記録すると連続日数が+1される', () async {
    final day1 = DateTime(2026, 10, 5);
    final day2 = DateTime(2026, 10, 6);
    await recordStudyToday(now: day1);
    await recordStudyToday(now: day2);
    expect(await loadCurrentStreak(now: day2), 2);
  });

  test('同じ日に複数回記録しても連続日数は加算されない', () async {
    final day = DateTime(2026, 10, 6);
    await recordStudyToday(now: day);
    await recordStudyToday(now: day);
    await recordStudyToday(now: day);
    expect(await loadCurrentStreak(now: day), 1);
  });

  test('2日以上空くと連続日数は1から数え直される', () async {
    final day1 = DateTime(2026, 10, 1);
    final day2 = DateTime(2026, 10, 2);
    final dayAfterGap = DateTime(2026, 10, 10);
    await recordStudyToday(now: day1);
    await recordStudyToday(now: day2);
    await recordStudyToday(now: dayAfterGap);
    expect(await loadCurrentStreak(now: dayAfterGap), 1);
  });

  test('2日以上空いて記録がないまま表示すると連続日数は0になる', () async {
    final day = DateTime(2026, 10, 1);
    final muchLater = DateTime(2026, 10, 10);
    await recordStudyToday(now: day);
    expect(await loadCurrentStreak(now: muchLater), 0);
  });

  test('一度も記録していない場合は0になる', () async {
    expect(await loadCurrentStreak(now: DateTime(2026, 10, 6)), 0);
  });
}
