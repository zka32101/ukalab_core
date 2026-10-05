import '../question/question.dart' show QuestionSource;
import '../src/json_util.dart';

/// 今月のAI動向（画期的な機能10、決定41）の1件。
///
/// 毎週の収集・運営者確認・月次の差分更新という運用はアプリの外で行い、
/// ここは配信するデータの構造だけを持つ。
class AiNewsItem {
  const AiNewsItem({
    required this.newsItemId,
    required this.examId,
    required this.summary,
    required this.sourceUrl,
    required this.sourceDate,
    required this.syllabusTag,
    required this.asOfDate,
    required this.source,
    required this.sourceRef,
    required this.contentVer,
    this.isExamRelevant = false,
    this.relatedQuestionId,
    this.disabled = false,
  });

  final String newsItemId;
  final String examId;

  /// 自分の言葉での1〜2文の要約（記事本文・見出しの転載はしない）。
  final String summary;

  /// 一次情報の出典URL。
  final String sourceUrl;

  /// 出典の発表日。
  final DateTime sourceDate;

  /// シラバスの章タグ（公式の出題内容ページの項目など）。
  final String syllabusTag;

  /// 「試験に出そう」印。
  final bool isExamRelevant;

  /// 「◯年◯月時点」の表示に使う基準日。
  final DateTime asOfDate;

  /// ニュースに紐づく最新動向問題（任意）。
  final String? relatedQuestionId;

  final QuestionSource source;
  final String sourceRef;
  final String contentVer;
  final bool disabled;

  factory AiNewsItem.fromJson(Map<String, dynamic> j) {
    final newsItemId = reqString(j, 'newsItemId', 'aiNewsItem');
    final where = 'aiNewsItem[$newsItemId]';

    final sourceName = reqString(j, 'source', where);
    final source = QuestionSource.values.where((s) => s.name == sourceName);
    if (source.isEmpty) {
      fail(where, '"source" は original / statute / licensed のいずれか');
    }

    final sourceDate = DateTime.tryParse(reqString(j, 'sourceDate', where));
    if (sourceDate == null) fail(where, '"sourceDate" の日付が不正です');

    final asOfDate = DateTime.tryParse(reqString(j, 'asOfDate', where));
    if (asOfDate == null) fail(where, '"asOfDate" の日付が不正です');

    return AiNewsItem(
      newsItemId: newsItemId,
      examId: reqString(j, 'examId', where),
      summary: reqString(j, 'summary', where),
      sourceUrl: reqString(j, 'sourceUrl', where),
      sourceDate: sourceDate,
      syllabusTag: reqString(j, 'syllabusTag', where),
      isExamRelevant: j['isExamRelevant'] == true,
      asOfDate: asOfDate,
      relatedQuestionId: optString(j, 'relatedQuestionId', where),
      source: source.first,
      sourceRef: reqString(j, 'sourceRef', where),
      contentVer: reqString(j, 'contentVer', where),
      disabled: j['disabled'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'newsItemId': newsItemId,
        'examId': examId,
        'summary': summary,
        'sourceUrl': sourceUrl,
        'sourceDate': sourceDate.toIso8601String(),
        'syllabusTag': syllabusTag,
        if (isExamRelevant) 'isExamRelevant': true,
        'asOfDate': asOfDate.toIso8601String(),
        if (relatedQuestionId != null) 'relatedQuestionId': relatedQuestionId,
        'source': source.name,
        'sourceRef': sourceRef,
        'contentVer': contentVer,
        if (disabled) 'disabled': true,
      };
}
