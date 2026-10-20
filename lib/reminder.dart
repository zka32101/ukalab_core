// アプリ内リマインダー（学習）の設定と表示。
//
// アプリを開いたときにホームへ出すカードと、その設定。
// OS の通知（端末のローカル通知）は `reminder_notification.dart` が受け持つ。
//
// `ui.dart` には含めない（独自の同名クラスを持つアプリとの衝突を避けるため。
// 使うアプリが `package:ukalab_core/reminder.dart` を明示的に import する）。
// 保存先は `ukalab_<アプリID>_reminder_settings`。
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'daily_goal.dart';
import 'reminder_notification.dart';

/// アプリ内リマインダーを個別に表示するかどうかの設定。
class ReminderSettings {
  const ReminderSettings({
    this.studyReminderEnabled = true,
    this.mockReminderEnabled = true,
    this.studyReminderHour = 18,
  });

  /// デイリーミッション未達成時の学習リマインダー（ホーム）を表示するか。
  final bool studyReminderEnabled;

  /// 模擬試験の受験間隔リマインダー（ホーム）を表示するか。表示の判定は各アプリが持つ。
  final bool mockReminderEnabled;

  /// 学習リマインダーを表示し始める時刻（0〜23時）。既定は18時。
  final int studyReminderHour;

  ReminderSettings copyWith({bool? studyReminderEnabled, bool? mockReminderEnabled, int? studyReminderHour}) =>
      ReminderSettings(
        studyReminderEnabled: studyReminderEnabled ?? this.studyReminderEnabled,
        mockReminderEnabled: mockReminderEnabled ?? this.mockReminderEnabled,
        studyReminderHour: studyReminderHour ?? this.studyReminderHour,
      );

  Map<String, dynamic> toJson() => {
        'studyReminderEnabled': studyReminderEnabled,
        'mockReminderEnabled': mockReminderEnabled,
        'studyReminderHour': studyReminderHour,
      };

  static ReminderSettings fromJson(Map<String, dynamic> json) => ReminderSettings(
        studyReminderEnabled: json['studyReminderEnabled'] as bool? ?? true,
        mockReminderEnabled: json['mockReminderEnabled'] as bool? ?? true,
        studyReminderHour: json['studyReminderHour'] as int? ?? 18,
      );
}

/// デイリーミッションの目標がある夜（[reminderHour] 時以降、既定18時）に、
/// まだ達成していなければ学習リマインダーを表示する時刻かどうか。
bool shouldShowStudyReminder({required DailyGoal goal, required DateTime now, int reminderHour = 18}) =>
    goal.target != null && !goal.achieved && now.hour >= reminderHour;

/// リマインダー設定の端末内保存。キーは `ukalab_<アプリID>_reminder_settings`。
class ReminderSettingsStore {
  ReminderSettingsStore(this.appId);

  final String appId;

  String get _key => 'ukalab_${appId}_reminder_settings';

  Future<ReminderSettings> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const ReminderSettings();
    try {
      return ReminderSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const ReminderSettings();
    }
  }

  Future<void> write(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}

/// リマインダー設定の読み込み・更新。`main()` で `load()` してから
/// [reminderSettingsServiceProvider] に渡す。
class ReminderSettingsService {
  ReminderSettingsService({required ReminderSettingsStore store}) : _store = store;

  final ReminderSettingsStore _store;
  ReminderSettings _settings = const ReminderSettings();

  ReminderSettings get settings => _settings;

  Future<void> load() async {
    _settings = await _store.read();
  }

  Future<ReminderSettings> update(ReminderSettings Function(ReminderSettings) change) async {
    _settings = change(_settings);
    await _store.write(_settings);
    return _settings;
  }
}

final reminderSettingsServiceProvider = Provider<ReminderSettingsService>(
  (ref) => throw UnimplementedError('reminderSettingsServiceProvider を override してください'),
);

class ReminderSettingsNotifier extends Notifier<ReminderSettings> {
  ReminderSettingsService get _s => ref.read(reminderSettingsServiceProvider);

  @override
  ReminderSettings build() => _s.settings;

  Future<void> setStudyReminderEnabled(bool enabled) async {
    state = await _s.update((s) => s.copyWith(studyReminderEnabled: enabled));
  }

  Future<void> setMockReminderEnabled(bool enabled) async {
    state = await _s.update((s) => s.copyWith(mockReminderEnabled: enabled));
  }

  Future<void> setStudyReminderHour(int hour) async {
    state = await _s.update((s) => s.copyWith(studyReminderHour: hour));
  }

  /// バックアップの読み込み時に呼ぶ。[settings] で上書きする。
  Future<void> restore(ReminderSettings settings) async {
    state = await _s.update((_) => settings);
  }

  /// 既定の設定に戻す。
  Future<void> reset() async {
    state = await _s.update((_) => const ReminderSettings());
  }
}

final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsNotifier, ReminderSettings>(ReminderSettingsNotifier.new);

/// [main] で呼ぶ。リマインダー設定を [appId] 別の保存先で読み込み、ProviderScope に渡す override を返す。
Future<List<Override>> reminderOverrides(String appId) async {
  final service = ReminderSettingsService(store: ReminderSettingsStore(appId));
  await service.load();
  return [reminderSettingsServiceProvider.overrideWithValue(service)];
}

/// ホームに置く学習リマインダー。設定がオンで、今日の目標が未達成の夜だけ出る
/// （[now] はテスト用の時刻注入）。出ないときは何も描かない。
class StudyReminderCard extends ConsumerWidget {
  const StudyReminderCard({super.key, this.now});

  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(reminderSettingsProvider);
    final goal = ref.watch(dailyGoalProvider);
    final show = settings.studyReminderEnabled &&
        shouldShowStudyReminder(goal: goal, now: now ?? DateTime.now(), reminderHour: settings.studyReminderHour);
    if (!show) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.nightlight_outlined, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '今日はまだ目標（${goal.target}問）に届いていません。解くタブから続けましょう',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 設定画面の「リマインダー」。学習リマインダーのオン／オフと時刻。
/// 模試リマインダーの切り替えは、表示の判定を持つアプリだけ [showMockReminder] で出す。
class ReminderSettingsSection extends ConsumerWidget {
  const ReminderSettingsSection({super.key, this.showMockReminder = false, this.mockReminderSubtitle});

  final bool showMockReminder;
  final String? mockReminderSubtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(reminderSettingsProvider);
    final notifier = ref.read(reminderSettingsProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('リマインダー', style: theme.textTheme.titleSmall),
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 4),
          child: Text('ホームに表示するアプリ内リマインダーを個別にオフにできます。', style: TextStyle(fontSize: 12, height: 1.6)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('学習リマインダー'),
          subtitle: Text('${settings.studyReminderHour}時以降に今日の目標が未達成なら知らせます'),
          value: settings.studyReminderEnabled,
          onChanged: (enabled) async {
            await notifier.setStudyReminderEnabled(enabled);
            if (!enabled) return;
            // オンにしたとき、端末の通知の許可を求める（対応しない端末では何もしない）。
            final granted = await ref.read(reminderNotifierProvider).requestPermission();
            if (!granted || !context.mounted) return;
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(content: Text('通知を許可しました。設定した時刻にお知らせします')),
            );
          },
        ),
        if (settings.studyReminderEnabled)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('学習リマインダーの時刻'),
            trailing: DropdownButton<int>(
              value: settings.studyReminderHour,
              items: [for (var h = 0; h < 24; h++) DropdownMenuItem(value: h, child: Text('$h時'))],
              onChanged: (h) {
                if (h != null) notifier.setStudyReminderHour(h);
              },
            ),
          ),
        if (showMockReminder)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('模試リマインダー'),
            subtitle: Text(mockReminderSubtitle ?? '前回の模擬試験から7日以上経ったら知らせます'),
            value: settings.mockReminderEnabled,
            onChanged: notifier.setMockReminderEnabled,
          ),
      ],
    );
  }
}
