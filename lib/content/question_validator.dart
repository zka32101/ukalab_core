import 'dart:convert';

import '../config/exam_config.dart';
import '../question/question.dart';

/// 問題データの検証結果1件。
class ContentIssue {
  const ContentIssue(this.qid, this.code, this.message);

  /// 対象の qid。行そのものが読めなかった場合は 'line:N'。
  final String qid;

  /// 機械可読な種別（CI の集計・除外用）。
  final String code;
  final String message;

  @override
  String toString() => '[$code] $qid: $message';
}

class ValidationOptions {
  const ValidationOptions({this.minChoices = 2, this.maxChoices = 6});

  final int minChoices;
  final int maxChoices;
}

class ParsedQuestions {
  const ParsedQuestions(this.questions, this.issues);

  final List<Question> questions;

  /// 読み込み（JSON 構文・必須項目）で見つかった問題。
  final List<ContentIssue> issues;
}

/// JSON Lines（1行1問）を読む。読めない行は [ParsedQuestions.issues] に入れて続行する。
ParsedQuestions parseQuestionsJsonl(String text) {
  final questions = <Question>[];
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
      questions.add(Question.fromJson(decoded));
    } on FormatException catch (e) {
      issues.add(ContentIssue('line:${i + 1}', 'parse', e.message));
    }
  }
  return ParsedQuestions(questions, issues);
}

/// 配信前の品質ゲート。出典必須・ID重複・選択肢数・正解の一意性など。
///
/// [exam] を渡すと、examId・subjectId・levelId が試験定義と整合するかも検査する。
List<ContentIssue> validateQuestions(
  List<Question> questions, {
  ExamConfig? exam,
  ValidationOptions options = const ValidationOptions(),
}) {
  final issues = <ContentIssue>[];
  void add(Question q, String code, String message) =>
      issues.add(ContentIssue(q.qid, code, message));

  final seen = <String>{};
  for (final q in questions) {
    if (!seen.add(q.qid)) add(q, 'duplicate-id', 'qid が重複しています');

    if (q.prompt.trim().isEmpty) add(q, 'empty-prompt', '問題文が空です');
    if (q.explanation.trim().isEmpty) add(q, 'empty-explanation', '解説が空です');

    // 出典（区分なしは配信しない。区分は型で必須なので、説明と許諾・版を検査）
    if (q.sourceRef.trim().isEmpty) add(q, 'no-source', '出典の説明がありません');
    if (q.source == QuestionSource.licensed &&
        (q.license == null || q.license!.trim().isEmpty)) {
      add(q, 'no-license', 'licensed の問題には許諾の記録(license)が必要です');
    }
    if (q.source == QuestionSource.statute &&
        (q.lawVersion == null || q.lawVersion!.trim().isEmpty)) {
      add(q, 'no-law-version', 'statute の問題には lawVersion が必要です');
    }

    // 選択肢と正解の一意性
    final n = q.choices.length;
    if (n < options.minChoices || n > options.maxChoices) {
      add(q, 'choice-count',
          '選択肢は${options.minChoices}〜${options.maxChoices}個（現在$n個）');
    }
    final normalized = [for (final c in q.choices) c.trim()];
    if (normalized.any((c) => c.isEmpty)) {
      add(q, 'empty-choice', '空の選択肢があります');
    }
    if (normalized.toSet().length != normalized.length) {
      add(q, 'duplicate-choice', '同じ文面の選択肢があり、正解が一意になりません');
    }
    if (q.answerIndex < 0 || q.answerIndex >= n) {
      add(q, 'answer-range', 'answerIndex(${q.answerIndex}) が選択肢の範囲外です');
    }

    if (q.difficulty < 1 || q.difficulty > 5) {
      add(q, 'difficulty', 'difficulty は1〜5');
    }
    if (q.points <= 0) add(q, 'points', 'points は1以上');
    if (q.contentVer.trim().isEmpty) add(q, 'no-content-ver', 'contentVer がありません');

    if (exam != null) {
      if (q.examId != exam.examId) {
        add(q, 'exam-mismatch', 'examId(${q.examId}) が試験(${exam.examId})と一致しません');
      }
      if (exam.subject(q.subjectId) == null) {
        add(q, 'unknown-subject', '未定義の subjectId: ${q.subjectId}');
      }
      final level = q.levelId;
      if (level != null && exam.level(level) == null) {
        add(q, 'unknown-level', '未定義の levelId: $level');
      }
    }
  }
  return issues;
}
