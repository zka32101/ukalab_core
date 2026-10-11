import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/daily_goal.dart';
import 'package:ukalab_core/reminder.dart';

void main() {
  group('shouldShowStudyReminder', () {
    const goal = DailyGoal(target: 10, todayCount: 3);
    test('目標が未達成で、指定時刻以降なら出す', () {
      expect(shouldShowStudyReminder(goal: goal, now: DateTime(2026, 10, 10, 18)), isTrue);
      expect(shouldShowStudyReminder(goal: goal, now: DateTime(2026, 10, 10, 17, 59)), isFalse);
      expect(shouldShowStudyReminder(goal: goal, now: DateTime(2026, 10, 10, 9), reminderHour: 8), isTrue);
    });
    test('目標がオフ、または達成済みなら出さない', () {
      expect(shouldShowStudyReminder(goal: const DailyGoal(), now: DateTime(2026, 10, 10, 20)), isFalse);
      expect(
        shouldShowStudyReminder(goal: const DailyGoal(target: 10, todayCount: 10), now: DateTime(2026, 10, 10, 20)),
        isFalse,
      );
    });
  });

  test('設定は保存して読み直せ、アプリIDごとに別', () async {
    SharedPreferences.setMockInitialValues({});
    final service = ReminderSettingsService(store: ReminderSettingsStore('a'));
    await service.update((s) => s.copyWith(studyReminderHour: 21, mockReminderEnabled: false));
    final reloaded = ReminderSettingsService(store: ReminderSettingsStore('a'));
    await reloaded.load();
    expect(reloaded.settings.studyReminderHour, 21);
    expect(reloaded.settings.mockReminderEnabled, isFalse);
    final other = ReminderSettingsService(store: ReminderSettingsStore('b'));
    await other.load();
    expect(other.settings.studyReminderHour, 18);
  });

  Future<List<Override>> overrides(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final list = (await tester.runAsync(() async => [
          ...await dailyGoalOverrides('t'),
          ...await reminderOverrides('t'),
        ]))!;
    return list;
  }

  testWidgets('目標を決めて夜に未達成なら学習リマインダーが出て、オフにすると消える', (tester) async {
    final o = await overrides(tester);
    await tester.pumpWidget(ProviderScope(
      overrides: o,
      child: MaterialApp(
        home: Scaffold(
          body: ListView(children: [
            const DailyGoalSetting(),
            StudyReminderCard(now: DateTime(2026, 10, 10, 20)),
            const ReminderSettingsSection(),
          ]),
        ),
      ),
    ));
    expect(find.textContaining('目標（'), findsNothing); // 目標オフ

    await tester.tap(find.text('10問/日'));
    await tester.pumpAndSettle();
    expect(find.textContaining('今日はまだ目標（10問）に届いていません'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('今日はまだ目標（10問）に届いていません'), findsNothing);
  });
}
