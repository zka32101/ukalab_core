import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/mock_exam_history.dart';
import 'package:ukalab_core/ukalab_core.dart';

MockExamResult _result({int score = 70, int max = 100, bool passed = true}) => MockExamResult(
      total: ScoreLine(score, max),
      bySubject: {'math': const ScoreLine(35, 50), 'word': const ScoreLine(35, 50)},
      passed: passed,
      shortBy: 0,
      subjectShortfalls: const {},
    );

void main() {
  group('MockExamHistoryEntry', () {
    test('fromResult: 総合・科目別の得点率を保持する', () {
      final entry = MockExamHistoryEntry.fromResult(_result(), at: DateTime(2026, 10, 1));
      expect(entry.pct, 70);
      expect(entry.bySubjectPct['math'], 70);
      expect(entry.passed, isTrue);
    });

    test('toJson/fromJson: 往復で値が保たれる', () {
      final entry = MockExamHistoryEntry.fromResult(_result(), at: DateTime(2026, 10, 1));
      final restored = MockExamHistoryEntry.fromJson(entry.toJson());
      expect(restored.score, entry.score);
      expect(restored.max, entry.max);
      expect(restored.passed, entry.passed);
      expect(restored.bySubjectPct, entry.bySubjectPct);
      expect(restored.at, entry.at);
    });
  });

  group('MockExamHistoryService', () {
    test('記録した結果を保存して読み直せる', () async {
      SharedPreferences.setMockInitialValues({});
      final service = MockExamHistoryService(store: MockExamHistoryStore('t'));
      await service.load();
      expect(service.entries, isEmpty);

      await service.record(MockExamHistoryEntry.fromResult(_result(score: 60)));
      await service.record(MockExamHistoryEntry.fromResult(_result(score: 80)));
      expect(service.entries.length, 2);

      final reloaded = MockExamHistoryService(store: MockExamHistoryStore('t'));
      await reloaded.load();
      expect(reloaded.entries.length, 2);
      expect(reloaded.entries.last.score, 80);
    });

    test('上限を超えた古い記録は捨てる', () async {
      SharedPreferences.setMockInitialValues({});
      final store = MockExamHistoryStore('t');
      final service = MockExamHistoryService(store: store);
      await service.load();
      for (var i = 0; i < MockExamHistoryStore.maxEntries + 5; i++) {
        await service.record(MockExamHistoryEntry.fromResult(_result(score: i)));
      }
      expect(service.entries.length, MockExamHistoryStore.maxEntries);
      expect(service.entries.last.score, MockExamHistoryStore.maxEntries + 4);
    });

    test('reset: 履歴を空にする', () async {
      SharedPreferences.setMockInitialValues({});
      final service = MockExamHistoryService(store: MockExamHistoryStore('t'));
      await service.load();
      await service.record(MockExamHistoryEntry.fromResult(_result()));
      await service.reset();
      expect(service.entries, isEmpty);
    });

    test('別のappIdは保存先が独立する', () async {
      SharedPreferences.setMockInitialValues({});
      final a = MockExamHistoryService(store: MockExamHistoryStore('a'));
      await a.load();
      await a.record(MockExamHistoryEntry.fromResult(_result()));

      final b = MockExamHistoryService(store: MockExamHistoryStore('b'));
      await b.load();
      expect(b.entries, isEmpty);
    });
  });
}
