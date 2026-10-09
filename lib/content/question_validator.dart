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

    switch (q.type) {
      case QuestionType.choice:
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
      case QuestionType.journal:
        // 仕訳: 借方合計＝貸方合計を機械検証（企画設計書3-2「正解は仕訳エンジンで再計算」）
        final answer = q.journalAnswer;
        if (answer == null || answer.lines.isEmpty) {
          add(q, 'journal-empty', '仕訳の行がありません');
        } else {
          if (answer.lines.any((l) => l.amount <= 0)) {
            add(q, 'journal-amount', '仕訳の金額は1以上である必要があります');
          }
          if (answer.lines.any((l) => l.account.trim().isEmpty)) {
            add(q, 'journal-account', '仕訳の勘定科目が空です');
          }
          if (answer.debitTotal != answer.creditTotal) {
            add(q, 'journal-unbalanced',
                '借方合計(${answer.debitTotal})と貸方合計(${answer.creditTotal})が一致しません');
          }
        }
      case QuestionType.worksheet:
        // 表埋め（精算表・財務諸表など）: セルの金額・科目・重複を検証
        final answer = q.worksheetAnswer;
        if (answer == null || answer.blankCells.isEmpty) {
          add(q, 'worksheet-empty', '表埋め問題の blankCells がありません');
        } else {
          final allCells = [...answer.givenCells, ...answer.blankCells];
          if (allCells.any((c) => c.amount <= 0)) {
            add(q, 'worksheet-amount', '表埋め問題の金額は1以上である必要があります');
          }
          if (allCells.any((c) => c.account.trim().isEmpty)) {
            add(q, 'worksheet-account', '表埋め問題の勘定科目が空です');
          }
          final positions = [for (final c in allCells) (c.account, c.column)];
          if (positions.toSet().length != positions.length) {
            add(q, 'worksheet-duplicate-cell',
                '同じ勘定科目・列の組み合わせのセルが重複しています（givenCellsとblankCellsの重複を含む）');
          }
        }
      case QuestionType.ledger:
        // 補助簿（商品有高帳・現金出納帳など）: セルの値・行参照・重複を検証
        final answer = q.ledgerAnswer;
        if (answer == null || answer.blankCells.isEmpty) {
          add(q, 'ledger-empty', '補助簿問題の blankCells がありません');
        } else {
          final allCells = [...answer.givenCells, ...answer.blankCells];
          if (allCells.any((c) => c.value <= 0)) {
            add(q, 'ledger-value', '補助簿問題の値は1以上である必要があります');
          }
          final rowIndices = answer.rows.map((r) => r.rowIndex).toSet();
          if (allCells.any((c) => !rowIndices.contains(c.rowIndex))) {
            add(q, 'ledger-unknown-row', '補助簿問題のセルが rows に無い rowIndex を参照しています');
          }
          final positions = [for (final c in allCells) (c.rowIndex, c.group, c.field)];
          if (positions.toSet().length != positions.length) {
            add(q, 'ledger-duplicate-cell',
                '同じ行・列グループ・項目の組み合わせのセルが重複しています（givenCellsとblankCellsの重複を含む）');
          }
        }
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

/// 比較対象（[Question.compareWith]）の存在チェック。[termIds] は用語データの
/// [Term.termId] の一覧。存在しないID・同じIDの重複・空のIDを検出する。
List<ContentIssue> validateCompareTargets(
  List<Question> questions,
  Iterable<String> termIds,
) {
  final known = termIds.toSet();
  final issues = <ContentIssue>[];
  for (final q in questions) {
    final seen = <String>{};
    for (final id in q.compareWith) {
      if (id.trim().isEmpty) {
        issues.add(ContentIssue(q.qid, 'compare-empty', '比較対象のIDが空です'));
      } else if (!seen.add(id)) {
        issues.add(ContentIssue(q.qid, 'compare-duplicate', '比較対象 "$id" が重複しています'));
      } else if (!known.contains(id)) {
        issues.add(ContentIssue(q.qid, 'compare-unknown', '比較対象 "$id" が用語データにありません'));
      }
    }
  }
  return issues;
}
