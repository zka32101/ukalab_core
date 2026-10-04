import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

WorksheetAnswer answer() => const WorksheetAnswer(
      givenCells: [
        WorksheetCell(
          account: 'cash',
          column: WorksheetColumn.trialBalanceDebit,
          amount: 100000,
        ),
      ],
      blankCells: [
        WorksheetCell(
          account: 'depreciation_expense',
          column: WorksheetColumn.incomeStatementDebit,
          amount: 5000,
        ),
        WorksheetCell(
          account: 'accumulated_depreciation',
          column: WorksheetColumn.balanceSheetCredit,
          amount: 5000,
        ),
      ],
    );

void main() {
  group('judgeWorksheet', () {
    test('全セル一致なら isCorrect', () {
      final result = judgeWorksheet(answer(), const [
        WorksheetCell(
          account: 'depreciation_expense',
          column: WorksheetColumn.incomeStatementDebit,
          amount: 5000,
        ),
        WorksheetCell(
          account: 'accumulated_depreciation',
          column: WorksheetColumn.balanceSheetCredit,
          amount: 5000,
        ),
      ]);
      expect(result.isCorrect, isTrue);
      expect(result.correctCount, 2);
      expect(result.totalCount, 2);
    });

    test('金額違いは wrongAmount', () {
      final result = judgeWorksheet(answer(), const [
        WorksheetCell(
          account: 'depreciation_expense',
          column: WorksheetColumn.incomeStatementDebit,
          amount: 9999,
        ),
        WorksheetCell(
          account: 'accumulated_depreciation',
          column: WorksheetColumn.balanceSheetCredit,
          amount: 5000,
        ),
      ]);
      expect(result.isCorrect, isFalse);
      expect(
        result.diffs.firstWhere((d) => d.expected?.account == 'depreciation_expense').kind,
        WorksheetCellDiffKind.wrongAmount,
      );
    });

    test('未入力セルは missing', () {
      final result = judgeWorksheet(answer(), const [
        WorksheetCell(
          account: 'depreciation_expense',
          column: WorksheetColumn.incomeStatementDebit,
          amount: 5000,
        ),
      ]);
      expect(result.isCorrect, isFalse);
      expect(
        result.diffs
            .where((d) => d.kind == WorksheetCellDiffKind.missing)
            .map((d) => d.expected?.account),
        contains('accumulated_depreciation'),
      );
    });

    test('余分な入力セルは extra', () {
      final result = judgeWorksheet(answer(), const [
        WorksheetCell(
          account: 'depreciation_expense',
          column: WorksheetColumn.incomeStatementDebit,
          amount: 5000,
        ),
        WorksheetCell(
          account: 'accumulated_depreciation',
          column: WorksheetColumn.balanceSheetCredit,
          amount: 5000,
        ),
        WorksheetCell(
          account: 'cash',
          column: WorksheetColumn.balanceSheetDebit,
          amount: 1000,
        ),
      ]);
      expect(
        result.diffs.where((d) => d.kind == WorksheetCellDiffKind.extra).length,
        1,
      );
      // extra は totalCount（採点対象）に含めない。
      expect(result.totalCount, 2);
    });
  });
}
