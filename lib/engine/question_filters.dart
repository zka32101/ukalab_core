import '../question/question.dart';

/// [onlyBookmarked] が true なら、[bookmarkedQids] に含まれる問題だけに絞り込む。
/// false なら [pool] をそのまま返す。
List<Question> filterByBookmark(
  List<Question> pool,
  Set<String> bookmarkedQids, {
  required bool onlyBookmarked,
}) =>
    onlyBookmarked ? [for (final q in pool) if (bookmarkedQids.contains(q.qid)) q] : pool;

/// [keyword] が問題文・解説・選択肢のいずれかに含まれる問題を返す
/// （大文字小文字は区別しない）。空のキーワードでは何も返さない。
List<Question> searchQuestions(List<Question> pool, String keyword) {
  final kw = keyword.trim().toLowerCase();
  if (kw.isEmpty) return [];
  return [
    for (final q in pool)
      if (q.prompt.toLowerCase().contains(kw) ||
          q.explanation.toLowerCase().contains(kw) ||
          q.choices.any((c) => c.toLowerCase().contains(kw)))
        q,
  ];
}

/// メモが書かれている問題（[memos] に qid があるもの）のうち、[keyword] が
/// 問題文またはメモ本文に含まれるものを返す。空のキーワードならメモがある
/// 全問題を返す。
List<Question> filterMemoedQuestions(
  List<Question> pool,
  Map<String, String> memos,
  String keyword,
) {
  final memoed = [for (final q in pool) if (memos.containsKey(q.qid)) q];
  final kw = keyword.trim();
  if (kw.isEmpty) return memoed;
  return [
    for (final q in memoed)
      if (q.prompt.contains(kw) || (memos[q.qid] ?? '').contains(kw)) q,
  ];
}

/// 指定した qid 集合の中で使われているタグを、名前順ですべて返す
/// （ブックマーク一覧のタグ絞り込みチップ用）。
List<String> allBookmarkTags(Map<String, Set<String>> tags, Iterable<String> qids) {
  final qidSet = qids.toSet();
  final names = <String>{};
  for (final e in tags.entries) {
    if (qidSet.contains(e.key)) names.addAll(e.value);
  }
  final sorted = names.toList()..sort();
  return sorted;
}
