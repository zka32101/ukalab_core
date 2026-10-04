import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

Question choiceQ(String qid, {int answerIndex = 1, bool disabled = false}) =>
    Question(
      qid: qid,
      examId: 'sample',
      subjectId: 'math',
      topicId: 't',
      prompt: 'p',
      choices: const ['a', 'b', 'c'],
      answerIndex: answerIndex,
      explanation: 'e',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
      disabled: disabled,
    );

Question journalQ(String qid) => Question(
      qid: qid,
      examId: 'boki3',
      subjectId: 'q1_shiwake',
      topicId: 't',
      type: QuestionType.journal,
      prompt: '仕訳せよ',
      journalAnswer: const JournalAnswer(lines: [
        JournalLine(side: JournalSide.debit, account: 'cash', amount: 1000),
        JournalLine(side: JournalSide.credit, account: 'sales', amount: 1000),
      ]),
      explanation: 'e',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
    );

Question worksheetQ(String qid) => Question(
      qid: qid,
      examId: 'boki3',
      subjectId: 'q3_kessan',
      topicId: 't',
      type: QuestionType.worksheet,
      prompt: '精算表を完成させよ',
      worksheetAnswer: const WorksheetAnswer(blankCells: [
        WorksheetCell(
          account: 'depreciation_expense',
          column: WorksheetColumn.incomeStatementDebit,
          amount: 5000,
        ),
      ]),
      explanation: 'e',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
    );

void main() {
  group('PracticeSession.answer（choice）', () {
    test('正解・不正解を記録する', () {
      final session = PracticeSession(pool: [choiceQ('a')], size: 1);
      final record = session.answer(1);
      expect(record.correct, isTrue);
      expect(record.choiceIndex, 1);
      expect(record.journalLines, isNull);
      expect(session.finished, isTrue);
    });

    test('type が journal の問題には使えない', () {
      final session = PracticeSession(pool: [journalQ('j')], size: 1);
      expect(() => session.answer(0), throwsStateError);
    });
  });

  group('PracticeSession.answerJournal', () {
    test('完全一致なら正解になる', () {
      final session = PracticeSession(pool: [journalQ('j')], size: 1);
      final record = session.answerJournal(const [
        JournalLine(side: JournalSide.debit, account: 'cash', amount: 1000),
        JournalLine(side: JournalSide.credit, account: 'sales', amount: 1000),
      ]);
      expect(record.correct, isTrue);
      expect(record.journalLines, hasLength(2));
      expect(record.choiceIndex, isNull);
      expect(session.correctCount, 1);
    });

    test('科目違いなど不一致なら不正解になる', () {
      final session = PracticeSession(pool: [journalQ('j')], size: 1);
      final record = session.answerJournal(const [
        JournalLine(side: JournalSide.debit, account: 'cash', amount: 1000),
        JournalLine(side: JournalSide.credit, account: 'purchases', amount: 1000),
      ]);
      expect(record.correct, isFalse);
    });

    test('type が choice の問題には使えない', () {
      final session = PracticeSession(pool: [choiceQ('a')], size: 1);
      expect(() => session.answerJournal(const []), throwsStateError);
    });

    test('セッション終了後は StateError', () {
      final session = PracticeSession(pool: [journalQ('j')], size: 1);
      session.answerJournal(const [
        JournalLine(side: JournalSide.debit, account: 'cash', amount: 1000),
        JournalLine(side: JournalSide.credit, account: 'sales', amount: 1000),
      ]);
      expect(() => session.answerJournal(const []), throwsStateError);
    });
  });

  group('PracticeSession.answerWorksheet', () {
    test('全セル一致なら正解になる', () {
      final session = PracticeSession(pool: [worksheetQ('w')], size: 1);
      final record = session.answerWorksheet(const [
        WorksheetCell(
          account: 'depreciation_expense',
          column: WorksheetColumn.incomeStatementDebit,
          amount: 5000,
        ),
      ]);
      expect(record.correct, isTrue);
      expect(record.worksheetCells, hasLength(1));
      expect(record.choiceIndex, isNull);
      expect(record.journalLines, isNull);
    });

    test('金額違いなら不正解になる', () {
      final session = PracticeSession(pool: [worksheetQ('w')], size: 1);
      final record = session.answerWorksheet(const [
        WorksheetCell(
          account: 'depreciation_expense',
          column: WorksheetColumn.incomeStatementDebit,
          amount: 1,
        ),
      ]);
      expect(record.correct, isFalse);
    });

    test('type が journal の問題には使えない', () {
      final session = PracticeSession(pool: [journalQ('j')], size: 1);
      expect(() => session.answerWorksheet(const []), throwsStateError);
    });
  });
}
