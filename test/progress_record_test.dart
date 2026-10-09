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

  group('ProgressRecord 追加項目（論点・回答時間・原因ラベル）', () {
    test('追加項目も含めて往復できる', () {
      final record = ProgressRecord(
        qid: 'q1',
        subjectId: 's1',
        correct: false,
        at: DateTime(2026, 10, 9, 9, 0),
        topicId: 'ch1',
        subtopicId: 'ch1-a',
        ms: 8400,
        cause: WrongCause.trap,
      );

      expect(record.toJson()['cause'], 'trap');
      expect(ProgressRecord.fromJson(record.toJson()), record);
    });

    test('追加項目の無い旧データも読める（追加項目は null）', () {
      final restored = ProgressRecord.fromJson({
        'qid': 'q1',
        'subjectId': 's1',
        'correct': true,
        'at': DateTime(2026, 10, 6).toIso8601String(),
      });

      expect(restored, isNotNull);
      expect(restored!.topicId, isNull);
      expect(restored.ms, isNull);
      expect(restored.cause, isNull);
    });

    test('追加項目が不正な型・値でも、必須項目は復元する', () {
      final restored = ProgressRecord.fromJson({
        'qid': 'q1',
        'subjectId': 's1',
        'correct': false,
        'at': DateTime(2026, 10, 6).toIso8601String(),
        'topicId': 123,
        'ms': 'fast',
        'cause': 'unknown',
      });

      expect(restored, isNotNull);
      expect(restored!.topicId, isNull);
      expect(restored.ms, isNull);
      expect(restored.cause, isNull);
    });

    test('追加項目が無い記録は toJson にキーを出さない', () {
      final json = ProgressRecord(
        qid: 'q1',
        subjectId: 's1',
        correct: true,
        at: DateTime(2026, 10, 6),
      ).toJson();

      expect(json.keys, unorderedEquals(['qid', 'subjectId', 'correct', 'at']));
    });
  });
}
