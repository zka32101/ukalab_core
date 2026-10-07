import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

void main() {
  group('ProgressRecord', () {
    test('toJson/fromJsonで往復できる', () {
      final record = ProgressRecord(
        qid: 'q1',
        subjectId: 's1',
        correct: true,
        at: DateTime(2026, 10, 6, 12, 30),
      );

      final restored = ProgressRecord.fromJson(record.toJson());

      expect(restored, record);
    });

    test('必須フィールドが欠けているJSONはnullを返す', () {
      expect(ProgressRecord.fromJson({'qid': 'q1'}), isNull);
      expect(ProgressRecord.fromJson('not a map'), isNull);
      expect(ProgressRecord.fromJson(null), isNull);
    });
  });

  group('InMemoryProgressStore', () {
    test('追加した記録を読み出せる', () async {
      final store = InMemoryProgressStore();
      final record = ProgressRecord(
        qid: 'q1',
        subjectId: 's1',
        correct: false,
        at: DateTime(2026, 10, 6),
      );

      await store.addRecord(record);

      expect(await store.loadRecords(), [record]);
    });

    test('clearRecordsで全件消える', () async {
      final store = InMemoryProgressStore();
      await store.addRecord(
        ProgressRecord(qid: 'q1', subjectId: 's1', correct: true, at: DateTime(2026, 10, 6)),
      );

      await store.clearRecords();

      expect(await store.loadRecords(), isEmpty);
    });
  });
}
