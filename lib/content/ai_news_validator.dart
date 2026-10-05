import 'dart:convert';

import '../config/exam_config.dart';
import '../experience/ai_news.dart';
import 'question_validator.dart' show ContentIssue;

class ParsedAiNewsItems {
  const ParsedAiNewsItems(this.items, this.issues);

  final List<AiNewsItem> items;

  /// 読み込み（JSON 構文・必須項目）で見つかった問題。
  final List<ContentIssue> issues;
}

/// JSON Lines（1行1件）を読む。読めない行は [ParsedAiNewsItems.issues] に
/// 入れて続行する。
ParsedAiNewsItems parseAiNewsItemsJsonl(String text) {
  final items = <AiNewsItem>[];
  final issues = <ContentIssue>[];
  final lines = const LineSplitter().convert(text);
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('//')) continue;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('1行は JSON オブジェクトが必要です');
      }
      items.add(AiNewsItem.fromJson(decoded));
    } on FormatException catch (e) {
      issues.add(ContentIssue('line:${i + 1}', 'parse', e.message));
    }
  }
  return ParsedAiNewsItems(items, issues);
}

/// 配信前の品質ゲート。要約・出典URL・章タグが空でないか、未確認情報を
/// うっかり含めていないかなどを検査する。
///
/// [exam] を渡すと、examId・relatedQuestionId が試験定義・問題データと
/// 整合するかも検査する。
List<ContentIssue> validateAiNewsItems(
  List<AiNewsItem> items, {
  ExamConfig? exam,
  List<String>? questionIds,
}) {
  final issues = <ContentIssue>[];
  void add(AiNewsItem n, String code, String message) =>
      issues.add(ContentIssue(n.newsItemId, code, message));

  final seenIds = <String>{};
  for (final n in items) {
    if (!seenIds.add(n.newsItemId)) {
      add(n, 'duplicate-id', 'newsItemId が重複しています');
    }

    if (n.summary.trim().isEmpty) add(n, 'empty-summary', '要約(summary)が空です');
    if (n.sourceUrl.trim().isEmpty) add(n, 'empty-source-url', '出典URL(sourceUrl)が空です');
    if (n.syllabusTag.trim().isEmpty) add(n, 'empty-syllabus-tag', '章タグ(syllabusTag)が空です');
    if (n.sourceRef.trim().isEmpty) add(n, 'no-source', '出典の説明がありません');
    if (n.contentVer.trim().isEmpty) add(n, 'no-content-ver', 'contentVer がありません');

    if (n.asOfDate.isBefore(n.sourceDate)) {
      add(n, 'as-of-before-source', '"◯年◯月時点"(asOfDate)が出典日(sourceDate)より前です');
    }

    if (exam != null && n.examId != exam.examId) {
      add(n, 'exam-mismatch', 'examId(${n.examId}) が試験(${exam.examId})と一致しません');
    }
    final relatedQuestionId = n.relatedQuestionId;
    if (questionIds != null &&
        relatedQuestionId != null &&
        !questionIds.contains(relatedQuestionId)) {
      add(n, 'unknown-related-question', '未定義の関連問題qid: $relatedQuestionId');
    }
  }
  return issues;
}
