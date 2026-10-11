// 学習リマインダーの OS 通知（端末のローカル通知）の共通部分。
//
// 「いつ通知するか」の判断と、予約のつなぎ込みだけを持つ。端末の通知機能そのもの
// （権限の確認・予約・取り消し）は [ReminderNotifier] として差し込む。差し込まない
// アプリ（Web など）は何もしない [NoopReminderNotifier] のままで、アプリ内カードだけが出る。
//
// 使い方:
// 1. 端末側の [ReminderNotifier] を作り、`reminderNotifierProvider` を override する
// 2. `MaterialApp` の `builder` で `ReminderNotificationWatcher` に包む
//
// `ui.dart` には含めない（`package:ukalab_core/reminder_notification.dart` を明示的に import する）。
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'daily_goal.dart';
import 'reminder.dart';

/// 端末の通知機能への差し込み口。
abstract class ReminderNotifier {
  /// 通知の許可を求める。許可されている（または今回許可された）なら true。
  /// 端末が通知に対応しない場合は false。
  Future<bool> requestPermission();

  /// [times] の各時刻に通知を出すよう予約する。これまでの予約はすべて置き換える。
  Future<void> schedule(List<DateTime> times, {required String title, required String body});

  /// 予約をすべて取り消す。
  Future<void> cancelAll();
}

/// 何もしない実装（Web など、端末の通知を使わないアプリの既定）。
class NoopReminderNotifier implements ReminderNotifier {
  const NoopReminderNotifier();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule(List<DateTime> times, {required String title, required String body}) async {}

  @override
  Future<void> cancelAll() async {}
}

final reminderNotifierProvider = Provider<ReminderNotifier>((ref) => const NoopReminderNotifier());

/// 予約する日数の既定。アプリを開くたびに予約し直すので、1週間先までで足りる。
const reminderScheduleDays = 7;

/// 通知する時刻の一覧（古い順）。毎日 [hour] 時を [days] 日先まで。
///
/// - すでに [hour] 時を過ぎた今日は含めない
/// - 今日の目標を達成済み（[achievedToday]）なら、今日は含めない
List<DateTime> upcomingReminderTimes({
  required DateTime now,
  required int hour,
  required bool achievedToday,
  int days = reminderScheduleDays,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final times = <DateTime>[];
  for (var i = 0; i < days; i++) {
    final at = DateTime(today.year, today.month, today.day + i, hour);
    if (!at.isAfter(now)) continue;
    if (i == 0 && achievedToday) continue;
    times.add(at);
  }
  return times;
}

/// 今日の目標を達成済みか。日付が今日のものだけを数える（日付をまたいだ古い記録は無視する）。
bool goalAchievedToday(DailyGoal goal, DateTime now) {
  final date = goal.todayDate;
  if (date == null || !goal.achieved) return false;
  return date.year == now.year && date.month == now.month && date.day == now.day;
}

/// 設定と目標の状況に合わせて、通知の予約を作り直す。
///
/// 目標が未設定（オフ）、または学習リマインダーがオフなら、予約をすべて取り消す。
Future<void> rescheduleStudyReminders({
  required ReminderNotifier notifier,
  required ReminderSettings settings,
  required DailyGoal goal,
  required DateTime now,
}) async {
  final target = goal.target;
  if (!settings.studyReminderEnabled || target == null) {
    await notifier.cancelAll();
    return;
  }
  final times = upcomingReminderTimes(
    now: now,
    hour: settings.studyReminderHour,
    achievedToday: goalAchievedToday(goal, now),
  );
  await notifier.schedule(
    times,
    title: '今日の学習はまだですか？',
    body: '今日の目標（$target問）に向けて、少しだけ進めましょう',
  );
}

/// アプリのルートを包むウィジェット。起動時に一度、そのあとは設定や今日の目標が変わるたびに、
/// 通知の予約を作り直す。`MaterialApp` の `builder` で `child` を包むのが簡単。
///
/// ```dart
/// MaterialApp(builder: (context, child) => ReminderNotificationWatcher(child: child ?? const SizedBox()))
/// ```
class ReminderNotificationWatcher extends ConsumerStatefulWidget {
  const ReminderNotificationWatcher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ReminderNotificationWatcher> createState() => _ReminderNotificationWatcherState();
}

class _ReminderNotificationWatcherState extends ConsumerState<ReminderNotificationWatcher> {
  void _sync() {
    rescheduleStudyReminders(
      notifier: ref.read(reminderNotifierProvider),
      settings: ref.read(reminderSettingsProvider),
      goal: ref.read(dailyGoalProvider),
      now: DateTime.now(),
    );
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(reminderSettingsProvider, (_, __) => _sync());
    ref.listenManual(dailyGoalProvider, (_, __) => _sync());
    ref.listenManual(reminderNotifierProvider, (_, __) => _sync());
    _sync();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
