/// 間隔反復（Leitner 方式）。問題ID単位で復習時期を管理する。
class SrsItem {
  const SrsItem({required this.qid, required this.box, required this.dueAt});

  final String qid;

  /// 0（間違えた直後）〜[Srs.maxBox]（定着）。
  final int box;
  final DateTime dueAt;

  Map<String, dynamic> toJson() =>
      {'qid': qid, 'box': box, 'dueAt': dueAt.toIso8601String()};

  factory SrsItem.fromJson(Map<String, dynamic> j) => SrsItem(
        qid: j['qid'] as String,
        box: j['box'] as int,
        dueAt: DateTime.parse(j['dueAt'] as String),
      );
}

class Srs {
  Srs._();

  /// 箱ごとの復習間隔。
  static const intervals = <Duration>[
    Duration.zero,
    Duration(days: 1),
    Duration(days: 3),
    Duration(days: 7),
    Duration(days: 14),
    Duration(days: 30),
  ];

  static int get maxBox => intervals.length - 1;

  /// 解答を反映した新しい状態を返す。正解で1つ上の箱へ、不正解は箱0（すぐ再出題）。
  static SrsItem review(
    SrsItem? previous, {
    required String qid,
    required bool correct,
    required DateTime now,
  }) {
    final box = correct ? ((previous?.box ?? 0) + 1).clamp(0, maxBox) : 0;
    return SrsItem(qid: qid, box: box, dueAt: now.add(intervals[box]));
  }

  /// 復習時期が来ている項目。期限の古い順、同じなら定着度の低い順。
  static List<SrsItem> due(
    Iterable<SrsItem> items,
    DateTime now, {
    int? limit,
  }) {
    final due = [
      for (final i in items)
        if (!i.dueAt.isAfter(now)) i,
    ]..sort((a, b) {
        final byDue = a.dueAt.compareTo(b.dueAt);
        return byDue != 0 ? byDue : a.box.compareTo(b.box);
      });
    return limit == null || due.length <= limit ? due : due.sublist(0, limit);
  }
}
