import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/daily_goal.dart';
import 'package:ukalab_core/reminder.dart';
import 'package:ukalab_core/reminder_notification.dart';

class _FakeNotifier implements ReminderNotifier {
  List<DateTime>? scheduled;
  String? title;
  String? body;
  int cancelled = 0;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(List<DateTime> times, {required String title, required String body}) async {
    scheduled = times;
    this.title = title;
    this.body = body;
  }

  @override
  Future<void> cancelAll() async => cancelled++;
}

void main() {
  group('upcomingReminderTimes', () {
    test('時刻前なら今日から数えて7日分', () {
      final times = upcomingReminderTimes(now: DateTime(2026, 10, 11, 9), hour: 18, achievedToday: false);
      expect(times.length, 7);
      expect(times.first, DateTime(2026, 10, 11, 18));
      expect(times.last, DateTime(2026, 10, 17, 18));
    });

    test('今日の時刻を過ぎていたら明日から', () {
      final times = upcomingReminderTimes(now: DateTime(2026, 10, 11, 19), hour: 18, achievedToday: false);
      expect(times.length, 6);
      expect(times.first, DateTime(2026, 10, 12, 18));
    });

    test('今日の目標を達成済みなら、今日は含めない', () {
      final times = upcomingReminderTimes(now: DateTime(2026, 10, 11, 9), hour: 18, achievedToday: true);
      expect(times.first, DateTime(2026, 10, 12, 18));
      expect(times.length, 6);
    });

    test('月末をまたいでも日付が進む', () {
      final times = upcomingReminderTimes(now: DateTime(2026, 10, 30, 9), hour: 8, achievedToday: false, days: 3);
      expect(times, [DateTime(2026, 10, 30, 8), DateTime(2026, 10, 31, 8), DateTime(2026, 11, 1, 8)]);
    });
  });

  group('goalAchievedToday', () {
    test('日付が今日で、目標に届いていれば達成済み', () {
      final goal = DailyGoal(target: 5, todayCount: 5, todayDate: DateTime(2026, 10, 11));
      expect(goalAchievedToday(goal, DateTime(2026, 10, 11, 20)), isTrue);
    });

    test('昨日の記録は数えない', () {
      final goal = DailyGoal(target: 5, todayCount: 5, todayDate: DateTime(2026, 10, 10));
      expect(goalAchievedToday(goal, DateTime(2026, 10, 11, 20)), isFalse);
    });

    test('目標が未設定、または届いていなければ未達成', () {
      expect(goalAchievedToday(const DailyGoal(), DateTime(2026, 10, 11)), isFalse);
      final goal = DailyGoal(target: 5, todayCount: 2, todayDate: DateTime(2026, 10, 11));
      expect(goalAchievedToday(goal, DateTime(2026, 10, 11)), isFalse);
    });
  });

  group('rescheduleStudyReminders', () {
    final now = DateTime(2026, 10, 11, 9);

    test('目標があり、リマインダーがオンなら予約する', () async {
      final fake = _FakeNotifier();
      await rescheduleStudyReminders(
        notifier: fake,
        settings: const ReminderSettings(),
        goal: const DailyGoal(target: 10),
        now: now,
      );
      expect(fake.scheduled, isNotEmpty);
      expect(fake.body, contains('10問'));
      expect(fake.cancelled, 0);
    });

    test('目標が未設定なら予約を取り消す', () async {
      final fake = _FakeNotifier();
      await rescheduleStudyReminders(
        notifier: fake,
        settings: const ReminderSettings(),
        goal: const DailyGoal(),
        now: now,
      );
      expect(fake.scheduled, isNull);
      expect(fake.cancelled, 1);
    });

    test('学習リマインダーがオフなら予約を取り消す', () async {
      final fake = _FakeNotifier();
      await rescheduleStudyReminders(
        notifier: fake,
        settings: const ReminderSettings(studyReminderEnabled: false),
        goal: const DailyGoal(target: 10),
        now: now,
      );
      expect(fake.cancelled, 1);
    });
  });

  test('既定の通知は何もしない（Web など）', () async {
    const noop = NoopReminderNotifier();
    expect(await noop.requestPermission(), isFalse);
    await noop.schedule([DateTime(2026, 10, 11)], title: 't', body: 'b');
    await noop.cancelAll();
  });
}
