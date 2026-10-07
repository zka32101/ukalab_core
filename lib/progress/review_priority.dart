import 'progress_record.dart';

/// 間隔反復の優先qidを計算する。各qidの最新の解答記録（`at` が最大のもの）が
/// 不正解だった問題を「復習が必要」とみなし、不正解のまま最も長く放置されている
/// （`at` が古い）ものから順に並べる。直近で正解し直した問題は対象から外れる。
///
/// [PracticeSession.new] の `priorityQids` にそのまま渡す想定。
///
/// より本格的な間隔反復（Leitner方式の箱・復習間隔）が必要な場合は [Srs] を使う。
/// こちらは [SrsItem] という専用の永続化状態を必要としないぶんシンプルで、
/// [ProgressRecord] の蓄積だけから毎回計算し直せる（新しい永続化の仕組みを
/// 増やしたくない場合や、まず単純な「間違えたものを優先」で十分な場合向け）。
List<String> reviewPriorityQids(List<ProgressRecord> records) {
  final latestByQid = <String, ProgressRecord>{};
  for (final r in records) {
    final existing = latestByQid[r.qid];
    if (existing == null || r.at.isAfter(existing.at)) {
      latestByQid[r.qid] = r;
    }
  }
  final due = latestByQid.values.where((r) => !r.correct).toList()
    ..sort((a, b) => a.at.compareTo(b.at));
  return [for (final r in due) r.qid];
}
