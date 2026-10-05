import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

LedgerAnswer answer() => const LedgerAnswer(
      rows: [
        LedgerRowMeta(rowIndex: 0, date: '4/1', description: '前月繰越'),
        LedgerRowMeta(rowIndex: 1, date: '4/10', description: '売上げ'),
      ],
      givenCells: [
        LedgerCell(
          rowIndex: 0,
          group: LedgerColumnGroup.balance,
          field: LedgerField.quantity,
          value: 10,
        ),
      ],
      blankCells: [
        LedgerCell(
          rowIndex: 1,
          group: LedgerColumnGroup.issue,
          field: LedgerField.quantity,
          value: 5,
        ),
        LedgerCell(
          rowIndex: 1,
          group: LedgerColumnGroup.issue,
          field: LedgerField.amount,
          value: 500,
        ),
      ],
    );

void main() {
  group('judgeLedger', () {
    test('全セル一致なら isCorrect', () {
      final result = judgeLedger(answer(), const [
        LedgerCell(
          rowIndex: 1,
          group: LedgerColumnGroup.issue,
          field: LedgerField.quantity,
          value: 5,
        ),
        LedgerCell(
          rowIndex: 1,
          group: LedgerColumnGroup.issue,
          field: LedgerField.amount,
          value: 500,
        ),
      ]);
      expect(result.isCorrect, isTrue);
      expect(result.correctCount, 2);
      expect(result.totalCount, 2);
    });

    test('値違いは wrongValue', () {
      final result = judgeLedger(answer(), const [
        LedgerCell(
          rowIndex: 1,
          group: LedgerColumnGroup.issue,
          field: LedgerField.quantity,
          value: 999,
        ),
        LedgerCell(
          rowIndex: 1,
          group: LedgerColumnGroup.issue,
          field: LedgerField.amount,
          value: 500,
        ),
      ]);
      expect(result.isCorrect, isFalse);
      expect(
        result.diffs
            .firstWhere((d) => d.expected?.field == LedgerField.quantity)
            .kind,
        LedgerCellDiffKind.wrongValue,
      );
    });

    test('未入力セルは missing', () {
      final result = judgeLedger(answer(), const [
        LedgerCell(
          rowIndex: 1,
          group: LedgerColumnGroup.issue,
          field: LedgerField.quantity,
          value: 5,
        ),
      ]);
      expect(result.isCorrect, isFalse);
      expect(
        result.diffs
            .where((d) => d.kind == LedgerCellDiffKind.missing)
            .map((d) => d.expected?.field),
        contains(LedgerField.amount),
      );
    });

    test('余分な入力セルは extra', () {
      final result = judgeLedger(answer(), const [
        LedgerCell(
          rowIndex: 1,
          group: LedgerColumnGroup.issue,
          field: LedgerField.quantity,
          value: 5,
        ),
        LedgerCell(
          rowIndex: 1,
          group: LedgerColumnGroup.issue,
          field: LedgerField.amount,
          value: 500,
        ),
        LedgerCell(
          rowIndex: 0,
          group: LedgerColumnGroup.balance,
          field: LedgerField.amount,
          value: 1000,
        ),
      ]);
      expect(
        result.diffs.where((d) => d.kind == LedgerCellDiffKind.extra).length,
        1,
      );
      // extra は totalCount（採点対象）に含めない。
      expect(result.totalCount, 2);
    });
  });
}
