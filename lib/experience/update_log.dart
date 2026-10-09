import '../src/json_util.dart';

/// 更新ログの種類。
enum UpdateKind {
  /// 法改正による差し替え。
  lawChange,

  /// シラバス・出題範囲の改訂による差し替え。
  syllabusChange,

  /// 誤りの訂正。
  correction,

  /// 問題・解説の追加。
  newContent,
}

/// 更新ログ画面の1件（「法改正で◯問を差し替えた」を見える化する）。
///
/// 差し替えの運用はアプリの外で行い、ここは配信するデータの構造だけを持つ。
class UpdateLogEntry {
  const UpdateLogEntry({
    required this.entryId,
    required this.examId,
    required this.date,
    required this.kind,
    required this.title,
    this.affectedQuestions = 0,
    this.versionRef,
    this.detail,
  });

  final String entryId;
  final String examId;

  /// 更新した日。
  final DateTime date;
  final UpdateKind kind;

  /// 画面に出す見出し（例:「危険物の規制に関する政令の改正に対応」）。
  final String title;

  /// 差し替え・追加・訂正した問題の数。
  final int affectedQuestions;

  /// 根拠の版（lawVersion・シラバス版・教則の版など）。法改正・シラバス改訂では必須。
  final String? versionRef;

  /// 補足の説明（任意）。
  final String? detail;

  factory UpdateLogEntry.fromJson(Map<String, dynamic> j) {
    final entryId = reqString(j, 'entryId', 'updateLog');
    final where = 'updateLog[$entryId]';

    final kindName = reqString(j, 'kind', where);
    final kind = UpdateKind.values.where((k) => k.name == kindName);
    if (kind.isEmpty) {
      fail(where, '"kind" は lawChange / syllabusChange / correction / newContent のいずれか');
    }

    final date = DateTime.tryParse(reqString(j, 'date', where));
    if (date == null) fail(where, '"date" の日付が不正です');

    return UpdateLogEntry(
      entryId: entryId,
      examId: reqString(j, 'examId', where),
      date: date,
      kind: kind.first,
      title: reqString(j, 'title', where),
      affectedQuestions: optInt(j, 'affectedQuestions', where, 0),
      versionRef: optString(j, 'versionRef', where),
      detail: optString(j, 'detail', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'entryId': entryId,
        'examId': examId,
        'date': date.toIso8601String(),
        'kind': kind.name,
        'title': title,
        if (affectedQuestions != 0) 'affectedQuestions': affectedQuestions,
        if (versionRef != null) 'versionRef': versionRef,
        if (detail != null) 'detail': detail,
      };
}

/// 更新ログ画面に出す一覧。新しい順。[now] より後の日付（予定）と、[days] 日より
/// 前の古い更新は含めない。[examId] を渡すとその試験の分だけにする。
List<UpdateLogEntry> recentUpdates(
  List<UpdateLogEntry> entries,
  DateTime now, {
  int days = 90,
  String? examId,
}) {
  final cutoff = now.subtract(Duration(days: days));
  final result = [
    for (final e in entries)
      if (!e.date.isAfter(now) &&
          !e.date.isBefore(cutoff) &&
          (examId == null || e.examId == examId))
        e,
  ]..sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : a.entryId.compareTo(b.entryId);
    });
  return result;
}
