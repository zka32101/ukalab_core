import 'progress_record.dart';

/// 間違いノートの1項目（1問分）。「伸びしろ」として扱い、解き直して連続で正解したら [overcome]（克服）。
///
/// 持つのは問題ID・日時・原因コード・分野IDなどの記録だけ（問題文・個人情報は持たない）。
class MistakeNoteEntry {
  const MistakeNoteEntry({
    required this.qid,
    required this.firstMissedAt,
    required this.lastMissedAt,
    required this.missCount,
    required this.overcome,
    this.lastCause,
    this.topicId,
    this.correctStreak = 0,
    required this.lastAnsweredAt,
  });

  final String qid;
  final DateTime firstMissedAt;
  final DateTime lastMissedAt;

  /// 間違えた回数（内部の判定用。ランキング表示には使わない）。
  final int missCount;

  /// 最後の間違いのあと、連続で必要回数以上正解した。
  final bool overcome;

  /// 直近の「原因を選んだ」間違いの原因。無ければ null。
  final WrongCause? lastCause;

  /// 直近に分かった分野ID。
  final String? topicId;

  /// 最後の間違いのあとの連続正解数（差分更新用）。
  final int correctStreak;

  /// この問題の最後の解答の時刻（同じ記録を二重に取り込まないための印）。
  final DateTime lastAnsweredAt;

  Map<String, dynamic> toJson() => {
        'qid': qid,
        'firstMissedAt': firstMissedAt.toIso8601String(),
        'lastMissedAt': lastMissedAt.toIso8601String(),
        'missCount': missCount,
        'overcome': overcome,
        if (lastCause != null) 'cause': lastCause!.name,
        if (topicId != null) 'topicId': topicId,
        'streak': correctStreak,
        'lastAnsweredAt': lastAnsweredAt.toIso8601String(),
      };

  /// 壊れた・不正な入力は null（読めた分だけ復元する）。
  static MistakeNoteEntry? fromJson(Object? json) {
    if (json is! Map) return null;
    final qid = json['qid'];
    final first = DateTime.tryParse('${json['firstMissedAt']}');
    final last = DateTime.tryParse('${json['lastMissedAt']}');
    final miss = json['missCount'];
    final overcome = json['overcome'];
    if (qid is! String || qid.isEmpty || first == null || last == null) return null;
    if (miss is! int || miss < 1 || overcome is! bool) return null;
    final answered = DateTime.tryParse('${json['lastAnsweredAt']}') ?? last;
    final streak = json['streak'];
    final topic = json['topicId'];
    WrongCause? cause;
    for (final c in WrongCause.values) {
      if (c.name == json['cause']) cause = c;
    }
    return MistakeNoteEntry(
      qid: qid,
      firstMissedAt: first,
      lastMissedAt: last,
      missCount: miss,
      overcome: overcome,
      lastCause: cause,
      topicId: topic is String ? topic : null,
      correctStreak: streak is int && streak >= 0 ? streak : 0,
      lastAnsweredAt: answered,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MistakeNoteEntry &&
      other.qid == qid &&
      other.firstMissedAt == firstMissedAt &&
      other.lastMissedAt == lastMissedAt &&
      other.missCount == missCount &&
      other.overcome == overcome &&
      other.lastCause == lastCause &&
      other.topicId == topicId &&
      other.correctStreak == correctStreak &&
      other.lastAnsweredAt == lastAnsweredAt;

  @override
  int get hashCode => Object.hash(qid, firstMissedAt, lastMissedAt, missCount, overcome,
      lastCause, topicId, correctStreak, lastAnsweredAt);

  @override
  String toString() => 'MistakeNoteEntry($qid, overcome: $overcome)';
}

/// 解答記録から間違いノートを作る純 Dart のロジック。同じ入力なら同じ結果（決定的・冪等）。
///
/// 克服の定義は「間違えたあとに連続 [overcomeStreak] 回（既定 2）正解」。
/// 克服したあとにまた間違えたら、その問題は「これから」に戻る（記録は続きから）。
/// 暫定の判断なので、アプリ側で [overcomeStreak] を変えられる。
class MistakeNoteEngine {
  const MistakeNoteEngine({this.overcomeStreak = 2}) : assert(overcomeStreak >= 1);

  final int overcomeStreak;

  /// [records] から項目を作る。直近の間違い順（同時刻は qid 順）。
  List<MistakeNoteEntry> build(Iterable<ProgressRecord> records) => update(const [], records);

  /// 既存の [existing] に [records] を取り込む。各問題の最後の解答より後の記録だけを反映するので、
  /// 同じ履歴を何度渡しても結果は変わらない（履歴が古い分から切り捨てられても、ノートは残る）。
  List<MistakeNoteEntry> update(
    Iterable<MistakeNoteEntry> existing,
    Iterable<ProgressRecord> records,
  ) {
    final base = {for (final e in existing) e.qid: e};
    final state = <String, _Acc>{
      for (final e in base.values) e.qid: _Acc.from(e),
    };
    // 時刻順（同時刻は入力順）。Dart の sort は安定でないため添字で順序を固定する。
    final indexed = records.toList().asMap().entries.toList()
      ..sort((a, b) {
        final c = a.value.at.compareTo(b.value.at);
        return c != 0 ? c : a.key.compareTo(b.key);
      });
    for (final ie in indexed) {
      final r = ie.value;
      final seen = base[r.qid]?.lastAnsweredAt;
      if (seen != null && !r.at.isAfter(seen)) continue;
      final acc = state[r.qid];
      if (r.correct) {
        if (acc == null) continue; // 間違えていない問題はノートに載せない
        acc.streak += 1;
        acc.lastAnswered = r.at;
        if (acc.streak >= overcomeStreak) acc.overcome = true;
      } else {
        final a = state.putIfAbsent(r.qid, () => _Acc.fresh(r));
        a.missCount += 1;
        a.lastMissed = r.at;
        a.streak = 0;
        a.overcome = false;
        a.lastAnswered = r.at;
        if (r.cause != null) a.cause = r.cause;
        if (r.topicId != null) a.topicId = r.topicId;
      }
    }
    final out = [for (final a in state.values) a.toEntry()]
      ..sort((a, b) {
        final c = b.lastMissedAt.compareTo(a.lastMissedAt);
        return c != 0 ? c : a.qid.compareTo(b.qid);
      });
    return out;
  }

  /// [before] では克服していなかったが [after] で克服済みになった問題ID（お祝い用）。
  List<String> newlyOvercome(
    Iterable<MistakeNoteEntry> before,
    Iterable<MistakeNoteEntry> after,
  ) {
    final was = {for (final e in before) e.qid: e.overcome};
    return [
      for (final e in after)
        if (e.overcome && was[e.qid] != true) e.qid,
    ];
  }
}

class _Acc {
  _Acc.fresh(ProgressRecord r)
      : qid = r.qid,
        firstMissed = r.at,
        lastMissed = r.at,
        missCount = 0,
        overcome = false,
        cause = null,
        topicId = null,
        streak = 0,
        lastAnswered = r.at;

  _Acc.from(MistakeNoteEntry e)
      : qid = e.qid,
        firstMissed = e.firstMissedAt,
        lastMissed = e.lastMissedAt,
        missCount = e.missCount,
        overcome = e.overcome,
        cause = e.lastCause,
        topicId = e.topicId,
        streak = e.correctStreak,
        lastAnswered = e.lastAnsweredAt;

  final String qid;
  DateTime firstMissed;
  DateTime lastMissed;
  int missCount;
  bool overcome;
  WrongCause? cause;
  String? topicId;
  int streak;
  DateTime lastAnswered;

  MistakeNoteEntry toEntry() => MistakeNoteEntry(
        qid: qid,
        firstMissedAt: firstMissed,
        lastMissedAt: lastMissed,
        missCount: missCount,
        overcome: overcome,
        lastCause: cause,
        topicId: topicId,
        correctStreak: streak,
        lastAnsweredAt: lastAnswered,
      );
}
