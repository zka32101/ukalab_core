import '../progress/progress_record.dart';
import '../progress/weak_topics.dart';
import '../question/question.dart';

/// 弱点集中ドリル（最小版）の出題を組む。
///
/// 弱い論点の上位 [topicLimit] 件から、[size] 問を集める。各論点の中では
/// やさしい問題（difficulty が小さい）から順に取り、論点をまたいで順番に拾う。
/// 最終的な並びは、やさしい問題 → 難しい問題（本番形式）の順。
/// 無効化された問題（disabled）は出さない。
///
/// 細目つきの弱点は細目が同じ問題だけ、章単位の弱点（細目なし）は章が同じ問題から選ぶ。
/// 弱点が無ければ空の一覧を返す。
List<Question> buildWeakDrill(
  List<Question> questions,
  List<ProgressRecord> records, {
  required DateTime now,
  int size = 10,
  int topicLimit = 3,
  WeakScoreConfig config = const WeakScoreConfig(),
}) {
  if (size <= 0 || topicLimit <= 0) return const [];
  final weak = computeWeakTopics(
    records,
    now: now,
    config: config,
    questions: questions,
  ).take(topicLimit).toList();
  if (weak.isEmpty) return const [];

  final pools = <List<Question>>[];
  for (final topic in weak) {
    final pool = [
      for (final q in questions)
        if (!q.disabled &&
            q.topicId == topic.chapterId &&
            (topic.subtopicId == null || q.subtopicId == topic.subtopicId))
          q,
    ]..sort((a, b) {
        final byDifficulty = a.difficulty.compareTo(b.difficulty);
        return byDifficulty != 0 ? byDifficulty : a.qid.compareTo(b.qid);
      });
    pools.add(pool);
  }

  final picked = <Question>[];
  final seen = <String>{};
  final cursors = List<int>.filled(pools.length, 0);
  var progressed = true;
  while (picked.length < size && progressed) {
    progressed = false;
    for (var i = 0; i < pools.length && picked.length < size; i++) {
      while (cursors[i] < pools[i].length) {
        final q = pools[i][cursors[i]++];
        if (seen.add(q.qid)) {
          picked.add(q);
          progressed = true;
          break;
        }
      }
    }
  }

  // やさしい問題 → 本番形式の順（同じ難しさなら拾った順を保つ）。
  final order = {for (var i = 0; i < picked.length; i++) picked[i].qid: i};
  picked.sort((a, b) {
    final byDifficulty = a.difficulty.compareTo(b.difficulty);
    return byDifficulty != 0 ? byDifficulty : order[a.qid]!.compareTo(order[b.qid]!);
  });
  return picked;
}
