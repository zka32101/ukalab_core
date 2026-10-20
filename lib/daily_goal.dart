// デイリーミッション（今日の目標問題数）と学習カレンダー。
//
// `ui.dart` には含めない（独自の同名クラスを持つアプリとの衝突を避けるため。
// 使うアプリが `package:ukalab_core/daily_goal.dart` を明示的に import する）。
// 保存先は `ukalab_<アプリID>_daily_goal` / `ukalab_<アプリID>_daily_goal_history`。
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 今日の目標問題数と、その達成状況。
class DailyGoal {
  const DailyGoal({
    this.target,
    this.todayCount = 0,
    this.todayDate,
    this.achievedStreak = 0,
    this.lastAchievedDate,
  });

  /// 1日あたりの目標問題数。未設定（オフ）なら null。
  final int? target;

  /// 今日すでに解答した問題数。
  final int todayCount;

  /// [todayCount] の対象日（日付のみ）。
  final DateTime? todayDate;

  /// 目標を達成した日の連続記録。[lastAchievedDate] が今日・昨日でなければ
  /// 途切れているとみなす（表示側は [effectiveAchievedStreak] を使う）。
  final int achievedStreak;

  /// 直近で目標を達成した日（日付のみ）。
  final DateTime? lastAchievedDate;

  bool get achieved => target != null && todayCount >= target!;

  DailyGoal copyWith({
    int? target,
    bool clearTarget = false,
    int? todayCount,
    DateTime? todayDate,
    int? achievedStreak,
    DateTime? lastAchievedDate,
  }) =>
      DailyGoal(
        target: clearTarget ? null : (target ?? this.target),
        todayCount: todayCount ?? this.todayCount,
        todayDate: todayDate ?? this.todayDate,
        achievedStreak: achievedStreak ?? this.achievedStreak,
        lastAchievedDate: lastAchievedDate ?? this.lastAchievedDate,
      );

  Map<String, dynamic> toJson() => {
        'target': target,
        'todayCount': todayCount,
        'todayDate': todayDate?.toIso8601String(),
        'achievedStreak': achievedStreak,
        'lastAchievedDate': lastAchievedDate?.toIso8601String(),
      };

  static DailyGoal fromJson(Map<String, dynamic> json) => DailyGoal(
        target: json['target'] as int?,
        todayCount: json['todayCount'] as int? ?? 0,
        todayDate: json['todayDate'] == null ? null : DateTime.parse(json['todayDate'] as String),
        achievedStreak: json['achievedStreak'] as int? ?? 0,
        lastAchievedDate: json['lastAchievedDate'] == null
            ? null
            : DateTime.parse(json['lastAchievedDate'] as String),
      );
}

/// 目標達成日の連続記録を更新する。[lastAchievedDate] が昨日なら+1、今日なら
/// そのまま（同日内の再達成）、それ以外（空白があった・初回）なら1にする。
int nextAchievedStreak({
  required int previousStreak,
  required DateTime? lastAchievedDate,
  required DateTime today,
}) {
  if (lastAchievedDate == null) return 1;
  final gap = today.difference(lastAchievedDate).inDays;
  if (gap == 0) return previousStreak;
  if (gap == 1) return previousStreak + 1;
  return 1;
}

/// 表示用の実効連続達成日数。最後に目標を達成した日が今日・昨日でなければ
/// 途切れているとみなし0を返す（次に達成するまで `achievedStreak` の値は
/// 古いまま保持されるため、表示側でこの関数を使って判定する）。
int effectiveAchievedStreak(DailyGoal goal, DateTime now) {
  final last = goal.lastAchievedDate;
  if (last == null) return 0;
  final today = DateTime(now.year, now.month, now.day);
  final gap = today.difference(last).inDays;
  return gap <= 1 ? goal.achievedStreak : 0;
}

/// ある日のデイリーミッションの達成状況のスナップショット。
class DailyGoalHistoryEntry {
  const DailyGoalHistoryEntry({required this.date, required this.count, required this.achieved});

  /// 日付のみ（時刻は0:00）。
  final DateTime date;

  /// その日に解答した問題数。
  final int count;

  /// その日に目標を達成したか。
  final bool achieved;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'count': count,
        'achieved': achieved,
      };

  static DailyGoalHistoryEntry fromJson(Map<String, dynamic> json) => DailyGoalHistoryEntry(
        date: DateTime.parse(json['date'] as String),
        count: json['count'] as int,
        achieved: json['achieved'] as bool,
      );
}

/// 直近[days]日分の学習記録を、古い日から新しい日の順で返す（カレンダー表示用）。
/// [history] に記録が無い日（保存件数の上限を超えて切り捨てられた日・未学習の日）
/// は null になる。
List<DailyGoalHistoryEntry?> streakCalendarDays(
  List<DailyGoalHistoryEntry> history,
  DateTime now, {
  int days = 28,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final byDate = {for (final e in history) e.date: e};
  return [
    for (var i = days - 1; i >= 0; i--) byDate[today.subtract(Duration(days: i))],
  ];
}

/// [monthAnchor] と同じ年月の、1日から月末までの学習記録を日付順に返す
/// （学習カレンダーの月表示用）。記録が無い日は null になる。
List<DailyGoalHistoryEntry?> monthCalendarDays(
  List<DailyGoalHistoryEntry> history,
  DateTime monthAnchor,
) {
  final byDate = {for (final e in history) e.date: e};
  final firstDay = DateTime(monthAnchor.year, monthAnchor.month, 1);
  final daysInMonth = DateTime(monthAnchor.year, monthAnchor.month + 1, 0).day;
  return [
    for (var d = 0; d < daysInMonth; d++) byDate[firstDay.add(Duration(days: d))],
  ];
}

/// [monthAnchor] から [offsetMonths] ヵ月分ずらした月の1日を返す
/// （前月・翌月への移動に使う）。
DateTime addMonths(DateTime monthAnchor, int offsetMonths) =>
    DateTime(monthAnchor.year, monthAnchor.month + offsetMonths, 1);

/// 学習カレンダーのヒートマップ表示で使う、その日の解答数に応じた濃さ
/// （0.0〜1.0）。[maxCount]（表示中の月で最も解答数が多かった日の件数）に
/// 対する比率で求める。[count] が0以下、又は [maxCount] が0以下なら0
/// （記録なし・解答数0の日は塗らない）。0より大きい場合は、薄すぎて
/// 見えなくならないよう最低でも0.25の濃さを保証する。
double heatmapOpacity(int count, int maxCount) {
  if (count <= 0 || maxCount <= 0) return 0;
  final ratio = count / maxCount;
  return ratio < 0.25 ? 0.25 : ratio;
}

/// [days] のうち最大の解答数（`DailyGoalHistoryEntry.count`）。記録が無い
/// 日は無視する。記録が1件も無ければ0。
int maxCountIn(List<DailyGoalHistoryEntry?> days) {
  var max = 0;
  for (final d in days) {
    if (d != null && d.count > max) max = d.count;
  }
  return max;
}

// ---------------------------------------------------------------------------
// 保存・サービス・プロバイダー（アプリID別）
// ---------------------------------------------------------------------------

/// デイリーミッションの端末内保存。キーは `ukalab_<アプリID>_daily_goal`。
class DailyGoalStore {
  DailyGoalStore(this.appId);

  final String appId;

  String get _key => 'ukalab_${appId}_daily_goal';

  Future<DailyGoal> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const DailyGoal();
    try {
      return DailyGoal.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const DailyGoal();
    }
  }

  Future<void> write(DailyGoal goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(goal.toJson()));
  }
}

/// デイリーミッションの読み込み・更新。`main()` で `load()` してから
/// [dailyGoalServiceProvider] に渡す。
class DailyGoalService {
  DailyGoalService({required DailyGoalStore store, DateTime Function()? clock})
      : _store = store,
        _clock = clock ?? DateTime.now;

  final DailyGoalStore _store;
  final DateTime Function() _clock;
  DailyGoal _goal = const DailyGoal();

  DailyGoal get goal => _goal;

  Future<void> load() async {
    _goal = _resetIfNewDay(await _store.read());
  }

  DailyGoal _resetIfNewDay(DailyGoal goal) {
    final today = _today();
    if (goal.todayDate == today) return goal;
    return goal.copyWith(todayCount: 0, todayDate: today);
  }

  DateTime _today() {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }

  /// 目標問題数を設定する。null で目標をオフにする。
  Future<DailyGoal> setTarget(int? target) async {
    _goal = _resetIfNewDay(_goal).copyWith(target: target, clearTarget: target == null);
    await _store.write(_goal);
    return _goal;
  }

  /// 1問答えたときに呼ぶ。今日初めて目標を達成した瞬間に、連続達成日数を更新する。
  Future<DailyGoal> recordAnswer() async {
    final reset = _resetIfNewDay(_goal);
    final updated = reset.copyWith(todayCount: reset.todayCount + 1);
    final today = _today();
    final justAchieved = updated.achieved && updated.lastAchievedDate != today;
    _goal = justAchieved
        ? updated.copyWith(
            achievedStreak: nextAchievedStreak(
              previousStreak: updated.achievedStreak,
              lastAchievedDate: updated.lastAchievedDate,
              today: today,
            ),
            lastAchievedDate: today,
          )
        : updated;
    await _store.write(_goal);
    return _goal;
  }

  /// 目標設定を含め初期状態に戻す。
  Future<DailyGoal> reset() async {
    _goal = const DailyGoal();
    await _store.write(_goal);
    return _goal;
  }

  /// バックアップの読み込み時に呼ぶ。[goal] で上書きする。
  Future<DailyGoal> restore(DailyGoal goal) async {
    _goal = goal;
    await _store.write(_goal);
    return _goal;
  }
}

final dailyGoalServiceProvider = Provider<DailyGoalService>(
  (ref) => throw UnimplementedError('dailyGoalServiceProvider を override してください'),
);

class DailyGoalNotifier extends Notifier<DailyGoal> {
  DailyGoalService get _s => ref.read(dailyGoalServiceProvider);

  @override
  DailyGoal build() => _s.goal;

  Future<void> setTarget(int? target) async {
    state = await _s.setTarget(target);
  }

  Future<void> recordAnswer() async {
    state = await _s.recordAnswer();
  }

  Future<void> reset() async {
    state = await _s.reset();
  }

  Future<void> restore(DailyGoal goal) async {
    state = await _s.restore(goal);
  }
}

final dailyGoalProvider = NotifierProvider<DailyGoalNotifier, DailyGoal>(DailyGoalNotifier.new);

/// デイリーミッションの達成履歴の端末内保存。キーは `ukalab_<アプリID>_daily_goal_history`。
class DailyGoalHistoryStore {
  DailyGoalHistoryStore(this.appId);

  final String appId;

  /// 保持する日数の上限（古いものから捨てる）。
  static const maxEntries = 30;

  String get _key => 'ukalab_${appId}_daily_goal_history';

  Future<List<DailyGoalHistoryEntry>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return [for (final j in list) DailyGoalHistoryEntry.fromJson(j as Map<String, dynamic>)];
    } catch (_) {
      return [];
    }
  }

  Future<void> write(List<DailyGoalHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final e in entries) e.toJson()]));
  }
}

/// 達成履歴の読み込み・記録。`main()` で `load()` してから
/// [dailyGoalHistoryServiceProvider] に渡す。
class DailyGoalHistoryService {
  DailyGoalHistoryService({required DailyGoalHistoryStore store}) : _store = store;

  final DailyGoalHistoryStore _store;
  List<DailyGoalHistoryEntry> _history = [];

  /// 古い順。
  List<DailyGoalHistoryEntry> get history => _history;

  Future<void> load() async {
    _history = await _store.read();
  }

  /// 解答した直後、今日の最新の解答数・達成状況を渡して呼ぶ。今日のスナップショットを置き換える。
  Future<List<DailyGoalHistoryEntry>> recordSnapshot({
    required DateTime date,
    required int count,
    required bool achieved,
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    final withoutToday = [for (final e in _history) if (e.date != day) e];
    _history = [...withoutToday, DailyGoalHistoryEntry(date: day, count: count, achieved: achieved)]
      ..sort((a, b) => a.date.compareTo(b.date));
    if (_history.length > DailyGoalHistoryStore.maxEntries) {
      _history = _history.sublist(_history.length - DailyGoalHistoryStore.maxEntries);
    }
    await _store.write(_history);
    return _history;
  }

  Future<List<DailyGoalHistoryEntry>> reset() async {
    _history = [];
    await _store.write(_history);
    return _history;
  }

  Future<List<DailyGoalHistoryEntry>> restore(List<DailyGoalHistoryEntry> history) async {
    _history = history;
    await _store.write(_history);
    return _history;
  }
}

final dailyGoalHistoryServiceProvider = Provider<DailyGoalHistoryService>(
  (ref) => throw UnimplementedError('dailyGoalHistoryServiceProvider を override してください'),
);

class DailyGoalHistoryNotifier extends Notifier<List<DailyGoalHistoryEntry>> {
  DailyGoalHistoryService get _s => ref.read(dailyGoalHistoryServiceProvider);

  @override
  List<DailyGoalHistoryEntry> build() => _s.history;

  Future<void> recordSnapshot({required DateTime date, required int count, required bool achieved}) async {
    state = await _s.recordSnapshot(date: date, count: count, achieved: achieved);
  }

  Future<void> reset() async {
    state = await _s.reset();
  }

  Future<void> restore(List<DailyGoalHistoryEntry> history) async {
    state = await _s.restore(history);
  }
}

final dailyGoalHistoryProvider =
    NotifierProvider<DailyGoalHistoryNotifier, List<DailyGoalHistoryEntry>>(DailyGoalHistoryNotifier.new);

/// 1問答えたときに呼ぶ。目標の進み具合と、今日の履歴スナップショットを一度に更新する。
Future<void> recordDailyAnswer(WidgetRef ref) async {
  await ref.read(dailyGoalProvider.notifier).recordAnswer();
  final goal = ref.read(dailyGoalProvider);
  await ref.read(dailyGoalHistoryProvider.notifier).recordSnapshot(
        date: goal.todayDate ?? DateTime.now(),
        count: goal.todayCount,
        achieved: goal.achieved,
      );
}

/// [main] で呼ぶ。2つのサービスを [appId] 別の保存先で読み込み、ProviderScope に渡す override を返す。
Future<List<Override>> dailyGoalOverrides(String appId) async {
  final goal = DailyGoalService(store: DailyGoalStore(appId));
  final history = DailyGoalHistoryService(store: DailyGoalHistoryStore(appId));
  await goal.load();
  await history.load();
  return [
    dailyGoalServiceProvider.overrideWithValue(goal),
    dailyGoalHistoryServiceProvider.overrideWithValue(history),
  ];
}

// ---------------------------------------------------------------------------
// 画面の部品
// ---------------------------------------------------------------------------

/// 「今日のデイリーミッション」の進み具合カード。目標がオフのときは何も出さない。
class DailyMissionCard extends ConsumerWidget {
  const DailyMissionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(dailyGoalProvider);
    final target = goal.target;
    if (target == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final streak = effectiveAchievedStreak(goal, DateTime.now());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              goal.achieved ? Icons.celebration_outlined : Icons.flag_outlined,
              color: goal.achieved ? theme.colorScheme.primary : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.achieved ? '今日の目標を達成しました！' : '今日のデイリーミッション', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: (goal.todayCount / target).clamp(0, 1).toDouble(), minHeight: 8),
                  ),
                  const SizedBox(height: 4),
                  Text('${goal.todayCount} / $target問', style: theme.textTheme.bodySmall),
                  if (streak > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department_outlined, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          '$streak日連続達成',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 設定画面の「デイリーミッション」（目標問題数の選択）。
class DailyGoalSetting extends ConsumerWidget {
  const DailyGoalSetting({super.key, this.choices = const [10, 20, 30]});

  /// 選べる1日あたりの問題数。
  final List<int> choices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final target = ref.watch(dailyGoalProvider).target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('デイリーミッション', style: theme.textTheme.titleSmall),
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 12),
          child: Text('1日の目標問題数を決めて、解くタブで達成状況を確認できます。', style: TextStyle(fontSize: 12, height: 1.6)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ChoiceChip(
              label: const Text('オフ'),
              selected: target == null,
              onSelected: (_) => ref.read(dailyGoalProvider.notifier).setTarget(null),
            ),
            for (final n in choices)
              ChoiceChip(
                label: Text('$n問/日'),
                selected: target == n,
                onSelected: (_) => ref.read(dailyGoalProvider.notifier).setTarget(n),
              ),
          ],
        ),
      ],
    );
  }
}
