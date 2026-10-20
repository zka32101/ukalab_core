import 'dart:math';

import 'answer_check.dart';
import 'journal_judge.dart';
import 'ledger_judge.dart';
import 'worksheet_judge.dart';
import '../question/question.dart';

enum PracticeMode { practice, mock, weak }

/// 解答ログ1件。[choiceIndex] は type が choice の問題、[journalLines] は
/// type が journal の問題、[worksheetCells] は type が worksheet の問題、
/// [ledgerCells] は type が ledger の問題、[boolAnswer] は trueFalse、[clozeAnswers] は cloze
/// （空欄番号 → 入力）、[textAnswer] は reverseLookup の問題のときにそれぞれ入る（他は null）。
/// [selfReported] は、自由入力の不正解を本人が「合っていた」と申告して正解に直した記録。
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
    this.ledgerCells,
    this.boolAnswer,
    this.clozeAnswers,
    this.textAnswer,
    this.selfReported = false,
  });

  final String qid;
  final int? choiceIndex;
  final List<JournalLine>? journalLines;
  final List<WorksheetCell>? worksheetCells;
  final List<LedgerCell>? ledgerCells;
  final bool? boolAnswer;
  final Map<int, String>? clozeAnswers;
  final String? textAnswer;
  final bool selfReported;
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
  /// [excludeQids]（習得済みで出さない問題など）は、優先指定も含めて出題から除く。
  PracticeSession({
    required Iterable<Question> pool,
    required this.size,
    this.mode = PracticeMode.practice,
    int seed = 0,
    List<String> priorityQids = const [],
    Set<String> excludeQids = const {},
  }) : questions = _pick(pool, size, seed, priorityQids, excludeQids);

  final int size;
  final PracticeMode mode;
  final List<Question> questions;
  final List<AnswerRecord> _records = [];

  static List<Question> _pick(
    Iterable<Question> pool,
    int size,
    int seed,
    List<String> priorityQids,
    Set<String> excludeQids,
  ) {
    final active = {
      for (final q in pool)
        if (!q.disabled && !excludeQids.contains(q.qid)) q.qid: q,
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

  /// 補助簿（type: ledger）の現在の問題に答える。[cells] はユーザーが入力したセル
  /// （[LedgerAnswer.blankCells] に対応する分のみでよい）。正誤判定は [judgeLedger]
  /// の完全一致（[LedgerJudgeResult.isCorrect]）で行う。
  /// 終了後、または type が ledger 以外の問題に呼ぶと [StateError]。
  AnswerRecord answerLedger(List<LedgerCell> cells, {int ms = 0, DateTime? at}) {
    final q = _currentOrThrow();
    if (q.type != QuestionType.ledger) {
      throw StateError(
        'type が ledger の問題にのみ answerLedger() が使えます（qid: ${q.qid}, type: ${q.type.name}）',
      );
    }
    final result = judgeLedger(q.ledgerAnswer!, cells);
    final record = AnswerRecord(
      qid: q.qid,
      ledgerCells: cells,
      correct: result.isCorrect,
      ms: ms,
      at: at ?? DateTime.now(),
      mode: mode,
    );
    _records.add(record);
    return record;
  }

  /// ○×（type: trueFalse）の現在の問題に答える。type が trueFalse 以外、または終了後は [StateError]。
  AnswerRecord answerTrueFalse(bool value, {int ms = 0, DateTime? at}) {
    final q = _currentOrThrow();
    _requireType(q, QuestionType.trueFalse, 'answerTrueFalse');
    return _add(
      AnswerRecord(
        qid: q.qid,
        boolAnswer: value,
        correct: judgeTrueFalse(q, value),
        ms: ms,
        at: at ?? DateTime.now(),
        mode: mode,
      ),
    );
  }

  /// 空欄補充（type: cloze）の現在の問題に答える。[inputs] は空欄番号 → 入力
  /// （選択式の空欄は選んだ選択肢の文字列）。全空欄が正解のときだけ正解（部分点なし）。
  /// type が cloze 以外、または終了後は [StateError]。
  AnswerRecord answerCloze(
    Map<int, String> inputs, {
    int ms = 0,
    DateTime? at,
  }) {
    final q = _currentOrThrow();
    _requireType(q, QuestionType.cloze, 'answerCloze');
    return _add(
      AnswerRecord(
        qid: q.qid,
        clozeAnswers: Map.unmodifiable(inputs),
        correct: judgeCloze(q, inputs).isCorrect,
        ms: ms,
        at: at ?? DateTime.now(),
        mode: mode,
      ),
    );
  }

  /// 説明から用語（type: reverseLookup）の現在の問題に答える。[input] は入力、または
  /// 選んだ選択肢の文字列。type が reverseLookup 以外、または終了後は [StateError]。
  AnswerRecord answerReverseLookup(String input, {int ms = 0, DateTime? at}) {
    final q = _currentOrThrow();
    _requireType(q, QuestionType.reverseLookup, 'answerReverseLookup');
    return _add(
      AnswerRecord(
        qid: q.qid,
        textAnswer: input,
        correct: judgeReverseLookup(q, input),
        ms: ms,
        at: at ?? DateTime.now(),
        mode: mode,
      ),
    );
  }

  /// 直近の記録を、本人の申告で正解に直す（自由入力の打ち間違い救済。
  /// cloze / reverseLookup のみ）。すでに正解なら何もしない。記録が無い、
  /// または直近の問題が自由入力の対象でなければ [StateError]。
  AnswerRecord markLastSelfReportedCorrect() {
    if (_records.isEmpty) throw StateError('まだ解答がありません');
    final last = _records.last;
    final q = questions[_records.length - 1];
    if (q.type != QuestionType.cloze && q.type != QuestionType.reverseLookup) {
      throw StateError(
        '自己申告は cloze / reverseLookup のみ（qid: ${q.qid}, type: ${q.type.name}）',
      );
    }
    if (last.correct) return last;
    final fixed = AnswerRecord(
      qid: last.qid,
      correct: true,
      ms: last.ms,
      at: last.at,
      mode: last.mode,
      clozeAnswers: last.clozeAnswers,
      textAnswer: last.textAnswer,
      selfReported: true,
    );
    _records[_records.length - 1] = fixed;
    return fixed;
  }

  AnswerRecord _add(AnswerRecord r) {
    _records.add(r);
    return r;
  }

  void _requireType(Question q, QuestionType t, String method) {
    if (q.type != t) {
      throw StateError(
        'type が ${t.name} の問題にのみ $method() が使えます（qid: ${q.qid}, type: ${q.type.name}）',
      );
    }
  }

  Question _currentOrThrow() {
    final q = current;
    if (q == null) throw StateError('セッションは終了しています');
    return q;
  }
}
