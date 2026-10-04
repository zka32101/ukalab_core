import 'dart:math';

import 'journal_judge.dart';
import 'worksheet_judge.dart';
import '../question/question.dart';

enum PracticeMode { practice, mock, weak }

/// 解答ログ1件。[choiceIndex] は type が choice の問題、[journalLines] は
/// type が journal の問題、[worksheetCells] は type が worksheet の問題の
/// ときにそれぞれ入る（他は null）。
class AnswerRecord {
  const AnswerRecord({
    required this.qid,
    required this.correct,
    required this.ms,
    required this.at,
    required this.mode,
    this.choiceIndex,
    this.journalLines,
    this.worksheetCells,
  });

  final String qid;
  final int? choiceIndex;
  final List<JournalLine>? journalLines;
  final List<WorksheetCell>? worksheetCells;
  final bool correct;
  final int ms;
  final DateTime at;
  final PracticeMode mode;
}

/// 演習1回分。出題順の決定と解答の記録だけを担う（画面・保存は持たない）。
class PracticeSession {
  /// [pool] から [size] 問を選ぶ。無効（disabled）の問題は除く。
  /// [priorityQids]（間隔反復の期限切れなど）は先頭に、与えた順で並べる。
  /// 残りは [seed] で再現可能にシャッフルする。
  PracticeSession({
    required Iterable<Question> pool,
    required this.size,
    this.mode = PracticeMode.practice,
    int seed = 0,
    List<String> priorityQids = const [],
  }) : questions = _pick(pool, size, seed, priorityQids);

  final int size;
  final PracticeMode mode;
  final List<Question> questions;
  final List<AnswerRecord> _records = [];

  static List<Question> _pick(
    Iterable<Question> pool,
    int size,
    int seed,
    List<String> priorityQids,
  ) {
    final active = {
      for (final q in pool)
        if (!q.disabled) q.qid: q,
    };
    final first = [
      for (final id in priorityQids) ?active.remove(id),
    ];
    final rest = active.values.toList()..shuffle(Random(seed));
    return [...first, ...rest].take(size).toList();
  }

  List<AnswerRecord> get records => List.unmodifiable(_records);
  int get index => _records.length;
  bool get finished => index >= questions.length;
  Question? get current => finished ? null : questions[index];
  int get correctCount => _records.where((r) => r.correct).length;

  /// 選択式（type: choice）の現在の問題に答える。終了後に呼ぶと [StateError]。
  /// type が choice 以外の問題に呼ぶと [StateError]。
  AnswerRecord answer(int choiceIndex, {int ms = 0, DateTime? at}) {
    final q = _currentOrThrow();
    if (q.type != QuestionType.choice) {
      throw StateError(
        'type が choice の問題にのみ answer() が使えます（qid: ${q.qid}, type: ${q.type.name}）',
      );
    }
    final record = AnswerRecord(
      qid: q.qid,
      choiceIndex: choiceIndex,
      correct: choiceIndex == q.answerIndex,
      ms: ms,
      at: at ?? DateTime.now(),
      mode: mode,
    );
    _records.add(record);
    return record;
  }

  /// 仕訳（type: journal）の現在の問題に答える。[lines] はユーザーが入力した仕訳。
  /// 正誤判定は [judgeJournal] の完全一致（[JournalJudgeResult.isCorrect]）で行う。
  /// 終了後、または type が journal 以外の問題に呼ぶと [StateError]。
  AnswerRecord answerJournal(List<JournalLine> lines, {int ms = 0, DateTime? at}) {
    final q = _currentOrThrow();
    if (q.type != QuestionType.journal) {
      throw StateError(
        'type が journal の問題にのみ answerJournal() が使えます（qid: ${q.qid}, type: ${q.type.name}）',
      );
    }
    final result = judgeJournal(q.journalAnswer!, lines);
    final record = AnswerRecord(
      qid: q.qid,
      journalLines: lines,
      correct: result.isCorrect,
      ms: ms,
      at: at ?? DateTime.now(),
      mode: mode,
    );
    _records.add(record);
    return record;
  }

  /// 表埋め（type: worksheet）の現在の問題に答える。[cells] はユーザーが入力したセル
  /// （[WorksheetAnswer.blankCells] に対応する分のみでよい）。正誤判定は [judgeWorksheet]
  /// の完全一致（[WorksheetJudgeResult.isCorrect]）で行う。
  /// 終了後、または type が worksheet 以外の問題に呼ぶと [StateError]。
  AnswerRecord answerWorksheet(List<WorksheetCell> cells, {int ms = 0, DateTime? at}) {
    final q = _currentOrThrow();
    if (q.type != QuestionType.worksheet) {
      throw StateError(
        'type が worksheet の問題にのみ answerWorksheet() が使えます（qid: ${q.qid}, type: ${q.type.name}）',
      );
    }
    final result = judgeWorksheet(q.worksheetAnswer!, cells);
    final record = AnswerRecord(
      qid: q.qid,
      worksheetCells: cells,
      correct: result.isCorrect,
      ms: ms,
      at: at ?? DateTime.now(),
      mode: mode,
    );
    _records.add(record);
    return record;
  }

  Question _currentOrThrow() {
    final q = current;
    if (q == null) throw StateError('セッションは終了しています');
    return q;
  }
}
