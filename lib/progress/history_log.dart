import 'dart:convert';

import '../question/question.dart';
import 'history_export.dart';
import 'progress_record.dart';

/// 解答履歴の保存件数の上限。古いものから捨てる（端末内の保存サイズを抑える）。
const historyMaxRecords = 2000;

/// [record] を末尾に足し、[max] 件を超えた分は古いものから捨てる。元のリストは変えない。
List<ProgressRecord> appendHistory(
  List<ProgressRecord> records,
  ProgressRecord record, {
  int max = historyMaxRecords,
}) {
  final next = [...records, record];
  return next.length > max ? next.sublist(next.length - max) : next;
}

/// 問題 [q] への解答から履歴1件を作る。[at] を省くと現在時刻。
ProgressRecord historyRecordFor(
  Question q, {
  required bool correct,
  int? ms,
  DateTime? at,
}) =>
    ProgressRecord(
      qid: q.qid,
      subjectId: q.subjectId,
      correct: correct,
      at: at ?? DateTime.now(),
      topicId: q.topicId,
      subtopicId: q.subtopicId,
      ms: ms,
    );

/// 履歴を保存用の JSON 文字列にする。
String encodeHistory(List<ProgressRecord> records) =>
    jsonEncode([for (final r in records) r.toJson()]);

/// 保存された JSON 文字列から履歴を復元する。null・壊れたデータ・不正な要素は無視する。
List<ProgressRecord> decodeHistory(String? raw) {
  if (raw == null) return const [];
  try {
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map(ProgressRecord.fromJson).whereType<ProgressRecord>().toList();
  } catch (_) {
    return const [];
  }
}

/// 履歴CSV（日付ごと＋分野ごと）。個人情報は含まない。
String historyCsv(List<ProgressRecord> records, List<Question> questions) {
  final daily = dailySummaryCsv(summarizeByDay(records));
  final topics = topicAccuracyCsv(summarizeByTopic(records, questions: questions));
  return '$daily\n$topics';
}
