import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/achievements.dart';
import 'package:ukalab_core/daily_goal.dart';

const _list = [
  Achievement(id: 'a', title: 'Aバッジ', description: 'Aの説明', icon: Icons.star, unlocked: true, category: 'x'),
  Achievement(id: 'b', title: 'Bバッジ', description: 'Bの説明', icon: Icons.star, unlocked: false, category: 'y'),
];

void main() {
  test('新しく解除されたIDだけを返し、保存して読み直せる。アプリIDごとに別', () async {
    SharedPreferences.setMockInitialValues({});
    final o = await achievementUnlockOverrides('t1');
    final c = ProviderContainer(overrides: o);
    addTearDown(c.dispose);
    final n = c.read(achievementUnlockProvider.notifier);
    expect(n.checkNewlyUnlocked({'a'}, DateTime(2026, 10, 11)), ['a']);
    expect(n.checkNewlyUnlocked({'a'}, DateTime(2026, 10, 12)), isEmpty);
    await Future<void>.delayed(Duration.zero);

    final again = await achievementUnlockOverrides('t1');
    final c2 = ProviderContainer(overrides: again);
    addTearDown(c2.dispose);
    expect(c2.read(achievementUnlockProvider).keys, ['a']);

    final other = ProviderContainer(overrides: await achievementUnlockOverrides('t2'));
    addTearDown(other.dispose);
    expect(other.read(achievementUnlockProvider), isEmpty);

    await c.read(achievementUnlockProvider.notifier).reset();
    expect(c.read(achievementUnlockProvider), isEmpty);
  });

  testWidgets('一覧は達成数とカテゴリ絞り込みを出す', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final o = (await tester.runAsync(() => achievementUnlockOverrides('t3')))!;
    await tester.pumpWidget(ProviderScope(
      overrides: [...o, achievementsProvider.overrideWithValue(_list)],
      child: const MaterialApp(home: AchievementsView(categoryLabels: {'x': 'X組', 'y': 'Y組'})),
    ));
    expect(find.text('1 / 2 個達成'), findsOneWidget);
    expect(find.text('Bバッジ'), findsOneWidget);
    await tester.tap(find.text('X組'));
    await tester.pump();
    expect(find.text('Bバッジ'), findsNothing);
    expect(find.text('Aバッジ'), findsOneWidget);
  });

  group('dailyGoalAchievements', () {
    final now = DateTime(2026, 10, 11, 9);
    DailyGoalHistoryEntry day(int d, {int count = 5}) =>
        DailyGoalHistoryEntry(date: DateTime(2026, 10, d), count: count, achieved: count >= 5);

    test('今日まで・昨日までの連続学習日数を数える', () {
      expect(studyStreakFromHistory([day(9), day(10), day(11)], now), 3);
      expect(studyStreakFromHistory([day(8), day(9), day(10)], now), 3);
      expect(studyStreakFromHistory([day(7), day(10)], now), 1);
      expect(studyStreakFromHistory([day(9, count: 0), day(10, count: 0)], now), 0);
      expect(studyStreakFromHistory([], now), 0);
    });

    test('連続日数とマイルストーンで解除される', () {
      final list = dailyGoalAchievements(
        goal: DailyGoal(target: 5, achievedStreak: 4, lastAchievedDate: DateTime(2026, 10, 10)),
        history: [day(9), day(10), day(11)],
        now: now,
      );
      bool unlocked(String id) => list.firstWhere((a) => a.id == id).unlocked;
      expect(unlocked('streak_3'), isTrue);
      expect(unlocked('streak_7'), isFalse);
      expect(unlocked('achieved_streak_3'), isTrue);
      expect(unlocked('achieved_streak_7'), isFalse);
    });
  });
}
