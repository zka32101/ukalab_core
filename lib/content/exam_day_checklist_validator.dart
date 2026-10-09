import 'dart:convert';

import '../config/exam_config.dart';
import '../experience/exam_day_checklist.dart';
import 'question_validator.dart' show ContentIssue;

class ParsedChecklistItems {
  const ParsedChecklistItems(this.items, this.issues);

  final List<ChecklistItem> items;

  /// 読み込み（JSON 構文・必須項目）で見つかった問題。
  final List<ContentIssue> issues;
}

/// JSON Lines（1行1項目）を読む。読めない行は [ParsedChecklistItems.issues] に入れて続行する。
ParsedChecklistItems parseChecklistItemsJsonl(String text) {
  final items = <ChecklistItem>[];
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
      items.add(ChecklistItem.fromJson(decoded));
    } on FormatException catch (e) {
      issues.add(ContentIssue('line:${i + 1}', 'parse', e.message));
    }
  }
  return ParsedChecklistItems(items, issues);
}

/// 配信前の品質ゲート。ID重複・空のラベルを検査する。[exam] を渡すと examId が
/// 試験定義と一致するかも検査する。公式で未確認の項目はエラーにしない
/// （画面で「公式で要確認」と出す。[unconfirmedItems] で数える）。
List<ContentIssue> validateChecklistItems(
  List<ChecklistItem> items, {
  ExamConfig? exam,
}) {
  final issues = <ContentIssue>[];
  void add(ChecklistItem i, String code, String message) =>
      issues.add(ContentIssue(i.itemId, code, message));

  final seen = <String>{};
  for (final item in items) {
    if (!seen.add(item.itemId)) add(item, 'duplicate-id', 'itemId が重複しています');
    if (item.label.trim().isEmpty) add(item, 'empty-label', '項目名(label)が空です');
    if (exam != null && item.examId != exam.examId) {
      add(item, 'exam-mismatch', 'examId(${item.examId}) が試験(${exam.examId})と一致しません');
    }
  }
  return issues;
}
