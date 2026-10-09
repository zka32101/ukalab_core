import '../src/json_util.dart';

/// チェック項目の分類。
enum ChecklistCategory {
  /// 持ち物。
  belongings,

  /// 会場までの移動・時間。
  travel,

  /// 受験票・本人確認。
  admission,

  /// 通信・部屋など、受験環境。
  environment,
}

/// 受験の形式。
enum ExamVenueKind {
  /// 自宅などで受けるオンライン受験。
  online,

  /// 会場で受ける。
  venue,
}

/// 試験当日チェックリストの1項目。
///
/// 項目の中身（持ち物・条件）は各公式の案内で確認が必要なので、公式で確認できていない
/// 項目は [officialConfirmed] を false にし、画面で「公式で要確認」と表示する。
class ChecklistItem {
  const ChecklistItem({
    required this.itemId,
    required this.examId,
    required this.category,
    required this.label,
    this.venue,
    this.officialConfirmed = false,
    this.note,
  });

  final String itemId;
  final String examId;
  final ChecklistCategory category;
  final String label;

  /// 対象の受験形式。null なら、どの形式でも出す。
  final ExamVenueKind? venue;

  /// 公式の案内で確認済みか。
  final bool officialConfirmed;
  final String? note;

  factory ChecklistItem.fromJson(Map<String, dynamic> j) {
    final itemId = reqString(j, 'itemId', 'checklistItem');
    final where = 'checklistItem[$itemId]';

    final categoryName = reqString(j, 'category', where);
    final category = ChecklistCategory.values.where((c) => c.name == categoryName);
    if (category.isEmpty) {
      fail(where, '"category" は belongings / travel / admission / environment のいずれか');
    }

    ExamVenueKind? venue;
    final venueName = optString(j, 'venue', where);
    if (venueName != null) {
      final match = ExamVenueKind.values.where((v) => v.name == venueName);
      if (match.isEmpty) fail(where, '"venue" は online / venue のいずれか');
      venue = match.first;
    }

    return ChecklistItem(
      itemId: itemId,
      examId: reqString(j, 'examId', where),
      category: category.first,
      label: reqString(j, 'label', where),
      venue: venue,
      officialConfirmed: j['officialConfirmed'] == true,
      note: optString(j, 'note', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'examId': examId,
        'category': category.name,
        'label': label,
        if (venue != null) 'venue': venue!.name,
        if (officialConfirmed) 'officialConfirmed': true,
        if (note != null) 'note': note,
      };
}

/// [examId] の当日チェックリスト。[venue] を渡すと、その受験形式の項目と
/// 形式を問わない項目だけにする。分類の定義順 → 登録順に並べる。
List<ChecklistItem> checklistFor(
  String examId,
  List<ChecklistItem> items, {
  ExamVenueKind? venue,
}) {
  final picked = [
    for (final item in items)
      if (item.examId == examId && (venue == null || item.venue == null || item.venue == venue))
        item,
  ];
  final order = {for (var i = 0; i < picked.length; i++) picked[i].itemId: i};
  picked.sort((a, b) {
    final byCategory = a.category.index.compareTo(b.category.index);
    return byCategory != 0 ? byCategory : order[a.itemId]!.compareTo(order[b.itemId]!);
  });
  return picked;
}

/// 公式の案内で確認できていない項目（画面で「公式で要確認」と出す）。
List<ChecklistItem> unconfirmedItems(List<ChecklistItem> items) =>
    [for (final item in items) if (!item.officialConfirmed) item];

/// チェックの状態（不変）。端末内に保存するのはアプリ側で、ここは操作だけを持つ。
class ChecklistProgress {
  const ChecklistProgress([this.checkedIds = const {}]);

  final Set<String> checkedIds;

  bool isChecked(String itemId) => checkedIds.contains(itemId);

  /// チェックを付ける／外す。
  ChecklistProgress toggle(String itemId) {
    final next = {...checkedIds};
    if (!next.remove(itemId)) next.add(itemId);
    return ChecklistProgress(Set.unmodifiable(next));
  }

  /// [items] のうちチェック済みの数。
  int doneCount(List<ChecklistItem> items) =>
      items.where((i) => checkedIds.contains(i.itemId)).length;

  /// [items] がすべてチェック済みか。項目が無いときは false。
  bool isComplete(List<ChecklistItem> items) =>
      items.isNotEmpty && doneCount(items) == items.length;
}
