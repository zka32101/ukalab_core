import 'dart:convert';

import '../config/exam_config.dart';
import '../question/question.dart';
import '../term/term.dart';
import 'question_validator.dart' show ContentIssue;

class ParsedTerms {
  const ParsedTerms(this.terms, this.issues);

  final List<Term> terms;

  /// 読み込み（JSON 構文・必須項目）で見つかった問題。
  final List<ContentIssue> issues;
}

/// JSON Lines（1行1用語）を読む。読めない行は [ParsedTerms.issues] に入れて続行する。
ParsedTerms parseTermsJsonl(String text) {
  final terms = <Term>[];
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
      terms.add(Term.fromJson(decoded));
    } on FormatException catch (e) {
      issues.add(ContentIssue('line:${i + 1}', 'parse', e.message));
    }
  }
  return ParsedTerms(terms, issues);
}

/// 配信前の品質ゲート（決定50）。①〜③が空でないか、関連用語のリンク切れ、
/// 同義語（表記）の重複、出典の有無などを検査する。
///
/// [exam] を渡すと、examId・subjectId が試験定義と整合するかも検査する。
/// [questions] を渡すと、relatedQuestionIds の参照先が実在するかも検査する。
List<ContentIssue> validateTerms(
  List<Term> terms, {
  ExamConfig? exam,
  List<Question>? questions,
}) {
  final issues = <ContentIssue>[];
  void add(Term t, String code, String message) =>
      issues.add(ContentIssue(t.termId, code, message));

  final termIds = terms.map((t) => t.termId).toSet();
  final questionIds = questions?.map((q) => q.qid).toSet();

  final seenIds = <String>{};
  final seenTerms = <String, String>{}; // term表記(正規化) → 最初に見た termId
  for (final t in terms) {
    if (!seenIds.add(t.termId)) add(t, 'duplicate-id', 'termId が重複しています');

    final normalizedTerm = t.term.trim();
    if (normalizedTerm.isEmpty) {
      add(t, 'empty-term', '見出し語(term)が空です');
    } else {
      final firstId = seenTerms.putIfAbsent(normalizedTerm, () => t.termId);
      if (firstId != t.termId) {
        add(t, 'duplicate-term',
            '見出し語「$normalizedTerm」が $firstId と重複しています（同義語は関連用語で結ぶ）');
      }
    }

    if (t.headline.trim().isEmpty) {
      add(t, 'empty-headline', 'ひとことで言うと（headline）が空です');
    }
    if (t.definition.trim().isEmpty) {
      add(t, 'empty-definition', '正確な意味（definition）が空です');
    }

    if (t.sourceRef.trim().isEmpty) add(t, 'no-source', '出典の説明がありません');
    if (t.source == QuestionSource.licensed &&
        (t.license == null || t.license!.trim().isEmpty)) {
      add(t, 'no-license', 'licensed の用語には許諾の記録(license)が必要です');
    }
    if (t.source == QuestionSource.statute &&
        (t.lawVersion == null || t.lawVersion!.trim().isEmpty)) {
      add(t, 'no-law-version', 'statute の用語には lawVersion が必要です');
    }
    if (t.contentVer.trim().isEmpty) add(t, 'no-content-ver', 'contentVer がありません');

    for (final relatedId in t.relatedTermIds) {
      if (relatedId == t.termId) {
        add(t, 'self-related-term', '関連用語に自分自身(${t.termId})を指定しています');
      } else if (!termIds.contains(relatedId)) {
        add(t, 'unknown-related-term', '未定義の関連用語termId: $relatedId');
      }
    }
    if (questionIds != null) {
      for (final relatedId in t.relatedQuestionIds) {
        if (!questionIds.contains(relatedId)) {
          add(t, 'unknown-related-question', '未定義の関連問題qid: $relatedId');
        }
      }
    }

    if (exam != null) {
      if (t.examId != exam.examId) {
        add(t, 'exam-mismatch', 'examId(${t.examId}) が試験(${exam.examId})と一致しません');
      }
      final subjectId = t.subjectId;
      if (subjectId != null && exam.subject(subjectId) == null) {
        add(t, 'unknown-subject', '未定義の subjectId: $subjectId');
      }
    }
  }
  return issues;
}
