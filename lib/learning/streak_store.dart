import 'package:shared_preferences/shared_preferences.dart';

const _streakDaysKey = 'app_common_kit_streak_days';
const _lastStudyDateKey = 'app_common_kit_last_study_date';

/// 演習・模擬試験などを1件記録した際に呼び出し、連続学習日数（ストリーク）を
/// 更新する。表示は [StreakBadge]（`ui_kit/streak_badge.dart`）と組み合わせる。
///
/// 当日すでに記録済みなら何もしない。前日に記録があれば+1、それ以外（2日以上
/// 空いた・初回）なら1から数え直す。`now` はテスト用（省略時は現在時刻）。
Future<void> recordStudyToday({DateTime? now}) async {
  final today = _dateKey(now ?? DateTime.now());
  final prefs = await SharedPreferences.getInstance();
  final lastDate = prefs.getString(_lastStudyDateKey);
  if (lastDate == today) return;

  final currentStreak = prefs.getInt(_streakDaysKey) ?? 0;
  final newStreak = lastDate == _dateKey((now ?? DateTime.now()).subtract(const Duration(days: 1)))
      ? currentStreak + 1
      : 1;
  await prefs.setString(_lastStudyDateKey, today);
  await prefs.setInt(_streakDaysKey, newStreak);
}

/// 現在の連続学習日数を返す。最後に学習したのが今日でも前日でもない場合
/// （2日以上空いて途切れている場合）は0を返す。
Future<int> loadCurrentStreak({DateTime? now}) async {
  final prefs = await SharedPreferences.getInstance();
  final lastDate = prefs.getString(_lastStudyDateKey);
  if (lastDate == null) return 0;

  final reference = now ?? DateTime.now();
  final isRecent = lastDate == _dateKey(reference) || lastDate == _dateKey(reference.subtract(const Duration(days: 1)));
  if (!isRecent) return 0;
  return prefs.getInt(_streakDaysKey) ?? 0;
}

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
