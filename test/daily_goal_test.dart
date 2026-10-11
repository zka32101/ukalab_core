import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/daily_goal.dart';

void main() {
  group('ロジック', () {
    test('nextAchievedStreak: 初回は1、昨日なら+1、同日はそのまま、空白があれば1', () {
      final today = DateTime(2026, 10, 10);
      expect(nextAchievedStreak(previousStreak: 0, lastAchievedDate: null, today: today), 1);
      expect(nextAchievedStreak(previousStreak: 3, lastAchievedDate: DateTime(2026, 10, 9), today: today), 4);
      expect(nextAchievedStreak(previousStreak: 3, lastAchievedDate: today, today: today), 3);
      expect(nextAchievedStreak(previousStreak: 3, lastAchievedDate: DateTime(2026, 10, 7), today: today), 1);
    });

    test('effectiveAchievedStreak: 最後の達成が一昨日以前なら0', () {
      final now = DateTime(2026, 10, 10, 12);
      const base = DailyGoal(achievedStreak: 5);
      expect(effectiveAchievedStreak(base.copyWith(lastAchievedDate: DateTime(2026, 10, 9)), now), 5);
      expect(effectiveAchievedStreak(base.copyWith(lastAchievedDate: DateTime(2026, 10, 8)), now), 0);
    });

    test('heatmapOpacity: 0なら塗らず、最低0.25を保証する', () {
      expect(heatmapOpacity(0, 10), 0);
      expect(heatmapOpacity(1, 100), 0.25);
      expect(heatmapOpacity(10, 10), 1);
    });
  });

  group('サービス', () {
    test('目標を達成した瞬間に連続達成が1になり、保存して読み直せる', () async {
      SharedPreferences.setMockInitialValues({});
      var now = DateTime(2026, 10, 10, 9);
      final service = DailyGoalService(store: DailyGoalStore('t'), clock: () => now);
      await service.load();
      await service.setTarget(2);
      await service.recordAnswer();
      expect(service.goal.achieved, isFalse);
      await service.recordAnswer();
      expect(service.goal.achieved, isTrue);
      expect(service.goal.achievedStreak, 1);

      final reloaded = DailyGoalService(store: DailyGoalStore('t'), clock: () => now);
      await reloaded.load();
      expect(reloaded.goal.todayCount, 2);
      expect(reloaded.goal.target, 2);

      // 翌日は今日の回数が0に戻り、連続達成は保持される。
      now = DateTime(2026, 10, 11, 9);
      final nextDay = DailyGoalService(store: DailyGoalStore('t'), clock: () => now);
      await nextDay.load();
      expect(nextDay.goal.todayCount, 0);
      expect(nextDay.goal.achievedStreak, 1);
    });

    test('アプリIDが違えば保存先も別', () async {
      SharedPreferences.setMockInitialValues({});
      await DailyGoalStore('a').write(const DailyGoal(target: 10));
      expect((await DailyGoalStore('b').read()).target, isNull);
    });

    test('履歴は1日1件で、上限を超えたら古いものから捨てる', () async {
      SharedPreferences.setMockInitialValues({});
      final service = DailyGoalHistoryService(store: DailyGoalHistoryStore('t'));
      await service.load();
      for (var i = 0; i < DailyGoalHistoryStore.maxEntries + 5; i++) {
        await service.recordSnapshot(date: DateTime(2026, 9, 1).add(Duration(days: i)), count: 1, achieved: false);
      }
      expect(service.history.length, DailyGoalHistoryStore.maxEntries);
      await service.recordSnapshot(date: service.history.last.date, count: 9, achieved: true);
      expect(service.history.last.count, 9);
      expect(service.history.length, DailyGoalHistoryStore.maxEntries);
    });
  });

  group('カレンダー', () {
    test('monthCalendarDays: 月の日数ぶん返し、記録の無い日は null', () {
      final history = [DailyGoalHistoryEntry(date: DateTime(2026, 10, 3), count: 5, achieved: true)];
      final days = monthCalendarDays(history, DateTime(2026, 10, 1));
      expect(days.length, 31);
      expect(days[2]!.count, 5);
      expect(days[0], isNull);
      expect(maxCountIn(days), 5);
    });
  });

  testWidgets('目標チップを選ぶと、ミッションカードに進み具合が出る', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final overrides = (await tester.runAsync(() => dailyGoalOverrides('t')))!;
    await tester.pumpWidget(ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        home: Scaffold(
          body: Column(children: [DailyGoalSetting(), DailyMissionCard()]),
        ),
      ),
    ));
    expect(find.text('デイリーミッション'), findsOneWidget); // 設定の見出し（目標がオフの間はカードは出ない）
    await tester.tap(find.text('20問/日'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 20問'), findsOneWidget);
  });
}
