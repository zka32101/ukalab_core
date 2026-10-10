import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

const debit = JournalSide.debit;
const credit = JournalSide.credit;

JournalLine l(JournalSide side, String account, int amount) =>
    JournalLine(side: side, account: account, amount: amount);

void main() {
  group('judgeJournal', () {
    test('単純仕訳の完全正解', () {
      final correct = JournalAnswer(lines: [l(debit, 'cash', 1000), l(credit, 'sales', 1000)]);
      final result = judgeJournal(correct, [l(debit, 'cash', 1000), l(credit, 'sales', 1000)]);
      expect(result.isCorrect, isTrue);
      expect(result.balanced, isTrue);
      expect(result.diffs.map((d) => d.kind), everyElement(JournalLineDiffKind.correct));
    });

    test('行の順序は結果に影響しない', () {
      final correct = JournalAnswer(lines: [l(debit, 'cash', 1000), l(credit, 'sales', 1000)]);
      final result = judgeJournal(correct, [l(credit, 'sales', 1000), l(debit, 'cash', 1000)]);
      expect(result.isCorrect, isTrue);
    });

    test('貸借が逆', () {
      final correct = JournalAnswer(lines: [l(debit, 'cash', 1000), l(credit, 'sales', 1000)]);
      final result = judgeJournal(correct, [l(credit, 'cash', 1000), l(debit, 'sales', 1000)]);
      expect(result.isCorrect, isFalse);
      expect(
        result.diffs.map((d) => d.kind),
        everyElement(JournalLineDiffKind.sideSwapped),
      );
      expect(result.balanced, isTrue); // 貸借が逆でも合計は一致する
    });

    test('科目の混同（前払/未払 等）', () {
      final correct = JournalAnswer(lines: [l(debit, 'prepaid_expense', 500), l(credit, 'cash', 500)]);
      final result = judgeJournal(correct, [l(debit, 'unpaid_expense', 500), l(credit, 'cash', 500)]);
      expect(result.isCorrect, isFalse);
      final wrong = result.diffs.firstWhere((d) => d.kind == JournalLineDiffKind.wrongAccount);
      expect(wrong.expected!.account, 'prepaid_expense');
      expect(wrong.actual!.account, 'unpaid_expense');
    });

    test('金額の誤り', () {
      final correct = JournalAnswer(lines: [l(debit, 'cash', 1000), l(credit, 'sales', 1000)]);
      final result = judgeJournal(correct, [l(debit, 'cash', 999), l(credit, 'sales', 1000)]);
      expect(result.isCorrect, isFalse);
      expect(result.balanced, isFalse); // 999 != 1000
      final wrong = result.diffs.firstWhere((d) => d.kind == JournalLineDiffKind.wrongAmount);
      expect(wrong.expected!.amount, 1000);
      expect(wrong.actual!.amount, 999);
    });

    test('複合仕訳で行が不足', () {
      final correct = JournalAnswer(lines: [
        l(debit, 'cash', 700),
        l(debit, 'allowance_for_doubtful', 300),
        l(credit, 'accounts_receivable', 1000),
      ]);
      final result = judgeJournal(correct, [l(debit, 'cash', 700), l(credit, 'accounts_receivable', 1000)]);
      expect(result.isCorrect, isFalse);
      expect(
        result.diffs.where((d) => d.kind == JournalLineDiffKind.missing).map((d) => d.expected!.account),
        ['allowance_for_doubtful'],
      );
    });

    test('余分な行', () {
      final correct = JournalAnswer(lines: [l(debit, 'cash', 1000), l(credit, 'sales', 1000)]);
      final result = judgeJournal(correct, [
        l(debit, 'cash', 1000),
        l(credit, 'sales', 1000),
        l(debit, 'cash', 1),
      ]);
      expect(result.isCorrect, isFalse);
      expect(result.diffs.where((d) => d.kind == JournalLineDiffKind.extra), hasLength(1));
    });
  });
}
