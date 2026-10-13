import 'mistake_note_engine.dart';

/// 「今日の復習」の1問分の状態。持つのは問題ID・段・次回の日付などの記録だけ（問題文・個人情報は持たない）。
class ReviewItem {
  const ReviewItem({
    required this.qid,
    required this.stage,
    required this.dueAt,
    required this.lastReviewedAt,
    this.graduated = false,
    this.topicId,
  });

  final String qid;

  /// 0 から（[ReviewSchedulerEngine.intervals] の添字）。段が高いほど間隔が長い。
  final int stage;

  /// 次に見返す日（暦日の 0 時）。[graduated] なら使わない。
  final DateTime dueAt;

  /// 最後に間違えた日、または最後に復習した時刻。
  final DateTime lastReviewedAt;

  /// 最後の段まで正解して、復習の対象から卒業した。
  final bool graduated;

  final String? topicId;

  ReviewItem copyWith({
    int? stage,
    DateTime? dueAt,
    DateTime? lastReviewedAt,
    bool? graduated,
    String? topicId,
  }) =>
      ReviewItem(
        qid: qid,
        stage: stage ?? this.stage,
        dueAt: dueAt ?? this.dueAt,
        lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
        graduated: graduated ?? this.graduated,
        topicId: topicId ?? this.topicId,
      );

  Map<String, dynamic> toJson() => {
        'qid': qid,
        'stage': stage,
        'dueAt': dueAt.toIso8601String(),
        'lastReviewedAt': lastReviewedAt.toIso8601String(),
        if (graduated) 'graduated': true,
        if (topicId != null) 'topicId': topicId,
      };

  /// 壊れた・不正な入力は null（読めた分だけ復元する）。
  static ReviewItem? fromJson(Object? json) {
    if (json is! Map) return null;
    final qid = json['qid'];
    final stage = json['stage'];
    final due = DateTime.tryParse('${json['dueAt']}');
    final last = DateTime.tryParse('${json['lastReviewedAt']}');
    if (qid is! String || qid.isEmpty || stage is! int || stage < 0) return null;
    if (due == null || last == null) return null;
    final topic = json['topicId'];
    return ReviewItem(
      qid: qid,
      stage: stage,
      dueAt: due,
      lastReviewedAt: last,
      graduated: json['graduated'] == true,
      topicId: topic is String ? topic : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReviewItem &&
      other.qid == qid &&
      other.stage == stage &&
      other.dueAt == dueAt &&
      other.lastReviewedAt == lastReviewedAt &&
      other.graduated == graduated &&
      other.topicId == topicId;

  @override
  int get hashCode => Object.hash(qid, stage, dueAt, lastReviewedAt, graduated, topicId);

  @override
  String toString() => 'ReviewItem($qid, stage: $stage, due: $dueAt)';
}

/// 間違いノートの問題を、忘れる頃に「今日の復習」として返す純 Dart のロジック（簡易ボックス方式）。
///
/// - 間隔は [intervals]（既定 1/3/7/14/30 日）。段 s の問題は、最後に見てから `intervals[s]` 日後に出る。
/// - 正解で次の段へ。最後の段で正解したら卒業（もう出さない）。
/// - 不正解で1段戻る（段 0 のままなら段 0）。次は戻った段の間隔のあとに出る。
/// - 日付は暦日（時刻・夏時間で 1 日ずれない）。期限を過ぎても罰や重みづけはなく、ただ「出せる」状態のまま。
///
/// `Srs`（箱0=すぐ再出題の Leitner 方式。全問題の履歴向け）とは別物で、こちらは間違いノートの
/// 「これから」の問題だけを対象にする。同じ `ProgressRecord` から両方を更新してもよい。
class ReviewSchedulerEngine {
  const ReviewSchedulerEngine({
    this.intervals = const [1, 3, 7, 14, 30],
  });

  /// 段ごとの間隔（日）。1 件以上が必要（const 式の中で長さを検査できないため、ここでは検査しない）。
  final List<int> intervals;

  int get lastStage => intervals.length - 1;

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  DateTime _dueFrom(DateTime from, int stage) {
    final d = _day(from);
    return DateTime(d.year, d.month, d.day + intervals[stage]);
  }

  /// 間違いノート [notes] を取り込む。新しく載った問題は段 0（間違えた翌日）から。
  /// 克服した・ノートから消えた問題は外す。卒業後に再び間違えた（または、復習より後に間違えた）問題は段 0 からやり直す。
  /// 同じ入力なら同じ結果（冪等）。
  List<ReviewItem> sync(Iterable<ReviewItem> existing, Iterable<MistakeNoteEntry> notes) {
    final have = {for (final i in existing) i.qid: i};
    final out = <ReviewItem>[];
    for (final n in notes) {
      if (n.overcome) continue;
      final cur = have[n.qid];
      if (cur == null || n.lastMissedAt.isAfter(cur.lastReviewedAt)) {
        out.add(ReviewItem(
          qid: n.qid,
          stage: 0,
          dueAt: _dueFrom(n.lastMissedAt, 0),
          lastReviewedAt: n.lastMissedAt,
          topicId: n.topicId,
        ));
      } else {
        out.add(cur);
      }
    }
    out.sort((a, b) => a.qid.compareTo(b.qid));
    return out;
  }

  /// 復習の結果を反映した新しい項目を返す。
  ReviewItem review(ReviewItem item, {required bool correct, required DateTime now}) {
    if (correct) {
      final next = item.stage + 1;
      if (next > lastStage) {
        return item.copyWith(stage: lastStage, lastReviewedAt: now, graduated: true);
      }
      return item.copyWith(stage: next, dueAt: _dueFrom(now, next), lastReviewedAt: now);
    }
    final back = item.stage > 0 ? (item.stage - 1).clamp(0, lastStage) : 0;
    return item.copyWith(
      stage: back,
      dueAt: _dueFrom(now, back),
      lastReviewedAt: now,
      graduated: false,
    );
  }

  /// [qid] の結果を [items] に反映する。対象外の qid は変えない。
  List<ReviewItem> applyResult(
    Iterable<ReviewItem> items,
    String qid, {
    required bool correct,
    required DateTime now,
  }) =>
      [for (final i in items) i.qid == qid ? review(i, correct: correct, now: now) : i];

  bool isDue(ReviewItem i, DateTime now) => !i.graduated && !i.dueAt.isAfter(now);

  /// 今日の期限分の件数（全部）。
  int dueCount(Iterable<ReviewItem> items, DateTime now) =>
      items.where((i) => isDue(i, now)).length;

  /// 今日の期限分を最大 [max] 問。期限の古い順、同じなら段の低い順、さらに qid 順（決定的）。
  List<ReviewItem> due(Iterable<ReviewItem> items, DateTime now, {int max = 5}) {
    final list = [
      for (final i in items)
        if (isDue(i, now)) i,
    ]..sort((a, b) {
        final c = a.dueAt.compareTo(b.dueAt);
        if (c != 0) return c;
        final s = a.stage.compareTo(b.stage);
        return s != 0 ? s : a.qid.compareTo(b.qid);
      });
    final n = max < 0 ? 0 : max;
    return list.length <= n ? list : list.sublist(0, n);
  }
}
