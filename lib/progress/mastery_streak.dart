import '../engine/practice_session.dart';
import '../question/question.dart';

/// 「同じ問題を連続で正解したら以後出題しない」の状態（qid 単位・純 Dart）。
///
/// - 連続数は同じ問題への連続した解答の正解数（日をまたいでもよい）。不正解で 0 に戻る。
/// - [threshold] 回連続で正解すると除外済みになる。除外中に不正解なら自動で解除される。
/// - 解答履歴（件数上限あり）とは別に、qid ごとの連続数と除外集合だけを持つ。
/// - 値オブジェクト（不変）。更新は新しいインスタンスを返す。
class MasteryStreak {
  const MasteryStreak({this.streaks = const {}, this.excluded = const {}});

  /// 除外になる連続正解数。
  static const int threshold = 2;

  static const MasteryStreak empty = MasteryStreak();

  /// qid → 現在の連続正解数（1 以上のものだけ）。
  final Map<String, int> streaks;

  /// 除外済みの qid。
  final Set<String> excluded;

  int streakOf(String qid) => streaks[qid] ?? 0;
  bool isExcluded(String qid) => excluded.contains(qid);
  int get excludedCount => excluded.length;

  /// この解答モードが連続数に影響するか。通常出題とペース走（[PracticeMode.practice]）のみ。
  /// 模擬試験・復習（weak）は影響しない。
  static bool appliesTo(PracticeMode mode) => mode == PracticeMode.practice;

  /// 1 回の解答を反映した新しい状態を返す。
  /// 正解は連続数 +1（[threshold] で除外）、不正解は 0 に戻して除外を解除する。
  MasteryStreak record(String qid, bool correct) {
    final nextStreaks = Map<String, int>.of(streaks);
    final nextExcluded = Set<String>.of(excluded);
    if (correct) {
      final n = streakOf(qid) + 1;
      nextStreaks[qid] = n;
      if (n >= threshold) nextExcluded.add(qid);
    } else {
      nextStreaks.remove(qid);
      nextExcluded.remove(qid);
    }
    return MasteryStreak(streaks: nextStreaks, excluded: nextExcluded);
  }

  /// [AnswerRecord] を反映する。[appliesTo] でないモード（模擬試験・復習）は何もしない。
  MasteryStreak recordAnswer(AnswerRecord r) =>
      appliesTo(r.mode) ? record(r.qid, r.correct) : this;

  /// 除外だけを全件戻す（連続数は 0 に戻す）。
  MasteryStreak restoreAll() => empty;

  Map<String, dynamic> toJson() => {
        'streaks': streaks,
        'excluded': (excluded.toList()..sort()),
      };

  /// null・壊れた値・不正な要素は無視する（壊れていれば空）。
  static MasteryStreak fromJson(Object? json) {
    if (json is! Map) return empty;
    final s = <String, int>{};
    final rawStreaks = json['streaks'];
    if (rawStreaks is Map) {
      rawStreaks.forEach((k, v) {
        if (k is String && v is int && v > 0) s[k] = v;
      });
    }
    final e = <String>{};
    final rawExcluded = json['excluded'];
    if (rawExcluded is List) {
      for (final v in rawExcluded) {
        if (v is String) e.add(v);
      }
    }
    return MasteryStreak(streaks: s, excluded: e);
  }
}

/// [pool] から除外済み qid の問題を除く。順序は保つ。
Iterable<Question> withoutExcluded(Iterable<Question> pool, Set<String> excluded) =>
    excluded.isEmpty ? pool : pool.where((q) => !excluded.contains(q.qid));

/// 出題できる問題（無効でないもの）がすべて除外済みか。
/// true のとき、アプリは「すべて習得済み。設定で戻せます」の案内を出す。
/// 出題できる問題がもともと 0 件のときは false（習得済みではない）。
bool isAllMastered(Iterable<Question> pool, Set<String> excluded) {
  var any = false;
  for (final q in pool) {
    if (q.disabled) continue;
    any = true;
    if (!excluded.contains(q.qid)) return false;
  }
  return any;
}
