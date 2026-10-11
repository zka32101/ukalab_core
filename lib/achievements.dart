/// 実績バッジの共通部品。バッジの定義と達成条件はアプリ側で作り、
/// このライブラリは「一覧画面」「解除日時の保存」「解除通知」を受け持つ。
///
/// 使い方:
/// 1. `achievementsProvider` をアプリ側で override し、達成状況付きの一覧を返す
/// 2. main で `await achievementUnlockOverrides(appId)` を ProviderScope に渡す
/// 3. アプリのルートで `watchAchievementUnlocks(ref, scaffoldMessengerKey)` を呼ぶ
/// 4. 一覧は `AchievementsView` を push する
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'daily_goal.dart';
import 'ui/data_management/data_management.dart';

/// 実績バッジ1件（達成条件の判定はアプリ側で済ませる）。
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
    this.category,
    this.progressText,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;

  /// 一覧のタブ分けに使う区分。`AchievementsView.categoryLabels` のキーと対応させる。
  final String? category;

  /// 未解除のバッジをタップしたときに見せる進捗の説明。
  final String? progressText;
}

/// 達成状況付きの実績一覧。アプリ側で `overrideWith` する。
final achievementsProvider = Provider<List<Achievement>>(
  (ref) => throw UnimplementedError('achievementsProvider を override してください'),
);

/// 解除日時（ID→日時）の端末内保存。キーは `ukalab_<アプリID>_notified_achievement_ids`。
class AchievementUnlockStore {
  AchievementUnlockStore(this.appId);

  final String appId;

  String get _key => 'ukalab_${appId}_notified_achievement_ids';

  Future<Map<String, DateTime>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {for (final e in map.entries) e.key: DateTime.parse(e.value as String)};
    } catch (_) {
      return {};
    }
  }

  Future<void> write(Map<String, DateTime> unlockedAt) async {
    final prefs = await SharedPreferences.getInstance();
    final json = {for (final e in unlockedAt.entries) e.key: e.value.toIso8601String()};
    await prefs.setString(_key, jsonEncode(json));
  }
}

class AchievementUnlockService {
  AchievementUnlockService({required AchievementUnlockStore store}) : _store = store;

  final AchievementUnlockStore _store;
  Map<String, DateTime> _unlockedAt = const {};

  Map<String, DateTime> get unlockedAt => _unlockedAt;

  Future<void> load() async {
    _unlockedAt = await _store.read();
  }

  Future<void> markNotified(Set<String> ids, DateTime now) async {
    _unlockedAt = {..._unlockedAt, for (final id in ids) id: now};
    await _store.write(_unlockedAt);
  }

  /// バックアップの読み込み時に呼ぶ。[unlockedAt] で置き換える。
  Future<void> replace(Map<String, DateTime> unlockedAt) async {
    _unlockedAt = unlockedAt;
    await _store.write(_unlockedAt);
  }

  Future<void> reset() => replace(const {});
}

final achievementUnlockServiceProvider = Provider<AchievementUnlockService>(
  (ref) => throw UnimplementedError('achievementUnlockServiceProvider を override してください'),
);

class AchievementUnlockNotifier extends Notifier<Map<String, DateTime>> {
  AchievementUnlockService get _s => ref.read(achievementUnlockServiceProvider);

  @override
  Map<String, DateTime> build() => _s.unlockedAt;

  /// [unlockedIds] のうち、まだ記録していないIDを返し、[now] を解除日時として記録する。
  List<String> checkNewlyUnlocked(Set<String> unlockedIds, DateTime now) {
    final newly = [for (final id in unlockedIds) if (!state.containsKey(id)) id];
    if (newly.isEmpty) return const [];
    state = {...state, for (final id in newly) id: now};
    _s.markNotified(newly.toSet(), now);
    return newly;
  }

  Future<void> restore(Map<String, DateTime> unlockedAt) async {
    await _s.replace(unlockedAt);
    state = unlockedAt;
  }

  Future<void> reset() async {
    await _s.reset();
    state = const {};
  }
}

final achievementUnlockProvider =
    NotifierProvider<AchievementUnlockNotifier, Map<String, DateTime>>(AchievementUnlockNotifier.new);

/// main で呼ぶ。解除日時を [appId] 別の保存先で読み込み、ProviderScope に渡す override を返す。
Future<List<Override>> achievementUnlockOverrides(String appId) async {
  final service = AchievementUnlockService(store: AchievementUnlockStore(appId));
  await service.load();
  return [achievementUnlockServiceProvider.overrideWithValue(service)];
}

/// アプリのルート（`build`）で呼ぶ。新しく解除された実績を検知して、
/// どの画面にいても [messengerKey] のスナックバーで知らせる。
void watchAchievementUnlocks(WidgetRef ref, GlobalKey<ScaffoldMessengerState> messengerKey) {
  ref.listen<List<Achievement>>(achievementsProvider, (previous, next) {
    final unlockedIds = {for (final a in next) if (a.unlocked) a.id};
    final newly = ref.read(achievementUnlockProvider.notifier).checkNewlyUnlocked(unlockedIds, DateTime.now());
    if (newly.isEmpty) return;
    for (final a in next) {
      if (!newly.contains(a.id)) continue;
      messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(a.icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('実績解除: ${a.title}')),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  });
}

String _formatDate(DateTime at) =>
    '${at.year}/${at.month.toString().padLeft(2, '0')}/${at.day.toString().padLeft(2, '0')}';

/// 実績の一覧。[categoryLabels] を渡すとカテゴリ別タブ（先頭に「すべて」）で切り替えられる。
/// [shareCardBuilder] を渡すと、解除済みのバッジの詳細に「達成カードを見る」が出る。
class AchievementsView extends ConsumerStatefulWidget {
  const AchievementsView({super.key, this.categoryLabels = const {}, this.shareCardBuilder});

  final Map<String, String> categoryLabels;
  final Widget Function(Achievement achievement, DateTime date)? shareCardBuilder;

  @override
  ConsumerState<AchievementsView> createState() => _AchievementsViewState();
}

class _AchievementsViewState extends ConsumerState<AchievementsView> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final achievements = ref.watch(achievementsProvider);
    final unlockedAt = ref.watch(achievementUnlockProvider);
    final unlockedCount = achievements.where((a) => a.unlocked).length;
    final filtered =
        _selected == null ? achievements : [for (final a in achievements) if (a.category == _selected) a];
    return Scaffold(
      appBar: AppBar(title: const Text('実績')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('$unlockedCount / ${achievements.length} 個達成', style: Theme.of(context).textTheme.titleSmall),
          if (widget.categoryLabels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  label: const Text('すべて'),
                  selected: _selected == null,
                  onSelected: (_) => setState(() => _selected = null),
                ),
                for (final e in widget.categoryLabels.entries)
                  ChoiceChip(
                    label: Text(e.value),
                    selected: _selected == e.key,
                    onSelected: (_) => setState(() => _selected = e.key),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          for (final a in filtered)
            _AchievementTile(
              achievement: a,
              unlockedAt: unlockedAt[a.id],
              shareCardBuilder: widget.shareCardBuilder,
            ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, this.unlockedAt, this.shareCardBuilder});

  final Achievement achievement;
  final DateTime? unlockedAt;
  final Widget Function(Achievement achievement, DateTime date)? shareCardBuilder;

  void _showDetail(BuildContext context) {
    final a = achievement;
    final at = unlockedAt;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(a.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.description),
            if (a.progressText != null) ...[
              const SizedBox(height: 12),
              Text(a.progressText!, style: Theme.of(context).textTheme.bodySmall),
            ] else if (a.unlocked) ...[
              const SizedBox(height: 12),
              Text(
                at == null ? '達成済みです。' : '達成済みです（${_formatDate(at)}）。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          if (a.unlocked && shareCardBuilder != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showShareCard(context);
              },
              child: const Text('達成カードを見る'),
            ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('閉じる')),
        ],
      ),
    );
  }

  void _showShareCard(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              shareCardBuilder!(achievement, DateTime.now()),
              const SizedBox(height: 12),
              Text(
                'スクリーンショットで共有できます。カードに名前などの個人情報は入りません。',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('閉じる')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = achievement.unlocked;
    final color = unlocked ? theme.colorScheme.primary : theme.disabledColor;
    final at = unlockedAt;
    return Card(
      child: ListTile(
        onTap: () => _showDetail(context),
        leading: Icon(achievement.icon, color: color),
        title: Text(
          achievement.title,
          style: theme.textTheme.titleSmall?.copyWith(color: unlocked ? null : theme.disabledColor),
        ),
        subtitle: Text(
          unlocked && at != null
              ? '${achievement.description}（${_formatDate(at)}達成）'
              : achievement.description,
          style: theme.textTheme.bodySmall?.copyWith(color: unlocked ? null : theme.disabledColor),
        ),
        trailing: unlocked
            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
            : const Icon(Icons.lock_outline),
      ),
    );
  }
}

/// 学習日の連続日数。履歴（直近30日まで）で、今日（まだ学習していなければ昨日）から
/// 数えて、1問以上解いた日が途切れず続いている日数。
int studyStreakFromHistory(List<DailyGoalHistoryEntry> history, DateTime now) {
  final days = {for (final e in history) if (e.count > 0) e.date};
  var day = DateTime(now.year, now.month, now.day);
  if (!days.contains(day)) day = day.subtract(const Duration(days: 1));
  var streak = 0;
  while (days.contains(day)) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

const _studyStreakMilestones = [3, 7, 14, 30];
const _achievedStreakMilestones = [3, 7, 14, 30, 60, 100];

/// デイリーミッションの記録だけから作れる共通の実績。
/// 「学習継続」（連続学習日数は履歴の範囲＝直近30日まで）と「目標達成の連続」。
List<Achievement> dailyGoalAchievements({
  required DailyGoal goal,
  required List<DailyGoalHistoryEntry> history,
  required DateTime now,
}) {
  final studyStreak = studyStreakFromHistory(history, now);
  final achievedStreak = effectiveAchievedStreak(goal, now);
  return [
    for (final d in _studyStreakMilestones)
      Achievement(
        id: 'streak_$d',
        title: '$d日連続学習',
        description: '$d日間、毎日学習を続けた',
        icon: Icons.local_fire_department_outlined,
        unlocked: studyStreak >= d,
        category: 'streak',
        progressText: studyStreak >= d ? null : '現在の連続学習日数: $studyStreak日 / $d日',
      ),
    for (final d in _achievedStreakMilestones)
      Achievement(
        id: 'achieved_streak_$d',
        title: '目標達成$d日連続',
        description: 'デイリーミッションの目標を$d日連続で達成した',
        icon: Icons.flag_outlined,
        unlocked: achievedStreak >= d,
        category: 'streak',
        progressText: achievedStreak >= d ? null : '現在の連続達成日数: $achievedStreak日 / $d日',
      ),
  ];
}

/// [achievementsProvider] の差し込み先に使える、デイリーミッション由来の実績の override。
/// [achievementUnlockOverrides] と同じ ProviderScope に渡す。
final dailyGoalAchievementsOverride = achievementsProvider.overrideWith((ref) {
  return dailyGoalAchievements(
    goal: ref.watch(dailyGoalProvider),
    history: ref.watch(dailyGoalHistoryProvider),
    now: DateTime.now(),
  );
});

/// 解除日時をバックアップ・リセットの対象にする部品（`DataManagementSection` の parts に足す）。
final achievementUnlockDataPart = DataPart(
  id: 'achievementUnlock',
  export: (ref) => {
    for (final e in ref.read(achievementUnlockProvider).entries) e.key: e.value.toIso8601String(),
  },
  restore: (ref, json) => ref.read(achievementUnlockProvider.notifier).restore({
    for (final e in (json as Map<String, dynamic>).entries) e.key: DateTime.parse(e.value as String),
  }),
  reset: (ref) => ref.read(achievementUnlockProvider.notifier).reset(),
);

/// 共通の実績の一覧で使うカテゴリ表示名。
const dailyGoalAchievementCategoryLabels = {'streak': '学習継続'};
