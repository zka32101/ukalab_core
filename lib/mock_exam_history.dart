// 模擬試験結果の履歴（プレミアム機能: 成長グラフでの比較）。
//
// `ui.dart` には含めない（アプリ側の独自実装との衝突を避けるため。
// 使うアプリが `package:ukalab_core/mock_exam_history.dart` を明示的に import する）。
// 保存先は `ukalab_<アプリID>_mock_exam_history`。
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engine/mock_exam.dart';

/// 模擬試験1回分の結果のスナップショット（履歴保存用）。
class MockExamHistoryEntry {
  const MockExamHistoryEntry({
    required this.at,
    required this.score,
    required this.max,
    required this.passed,
    required this.bySubjectPct,
  });

  final DateTime at;
  final int score;
  final int max;
  final bool passed;

  /// 科目ID → 得点率（%）。
  final Map<String, double> bySubjectPct;

  double get pct => max == 0 ? 0 : score * 100 / max;

  factory MockExamHistoryEntry.fromResult(MockExamResult result, {DateTime? at}) =>
      MockExamHistoryEntry(
        at: at ?? DateTime.now(),
        score: result.total.score,
        max: result.total.max,
        passed: result.passed,
        bySubjectPct: {
          for (final e in result.bySubject.entries) e.key: e.value.pct,
        },
      );

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'score': score,
        'max': max,
        'passed': passed,
        'bySubjectPct': bySubjectPct,
      };

  static MockExamHistoryEntry fromJson(Map<String, dynamic> json) => MockExamHistoryEntry(
        at: DateTime.parse(json['at'] as String),
        score: json['score'] as int,
        max: json['max'] as int,
        passed: json['passed'] as bool,
        bySubjectPct: (json['bySubjectPct'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
      );
}

// ---------------------------------------------------------------------------
// 保存・サービス・プロバイダー（アプリID別）
// ---------------------------------------------------------------------------

/// 模擬試験結果の履歴の端末内保存。キーは `ukalab_<アプリID>_mock_exam_history`。
class MockExamHistoryStore {
  MockExamHistoryStore(this.appId);

  final String appId;

  /// 保持する件数の上限（古いものから捨てる）。
  static const maxEntries = 50;

  String get _key => 'ukalab_${appId}_mock_exam_history';

  Future<List<MockExamHistoryEntry>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final j in list) MockExamHistoryEntry.fromJson(j as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> write(List<MockExamHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final e in entries) e.toJson()]));
  }
}

/// 模擬試験結果の履歴の読み込み・記録。`main()` で `load()` してから
/// [mockExamHistoryServiceProvider] に渡す。
class MockExamHistoryService {
  MockExamHistoryService({required MockExamHistoryStore store}) : _store = store;

  final MockExamHistoryStore _store;
  List<MockExamHistoryEntry> _entries = [];

  List<MockExamHistoryEntry> get entries => _entries;

  Future<void> load() async {
    _entries = await _store.read();
  }

  Future<List<MockExamHistoryEntry>> record(MockExamHistoryEntry entry) async {
    final next = [..._entries, entry];
    _entries = next.length > MockExamHistoryStore.maxEntries
        ? next.sublist(next.length - MockExamHistoryStore.maxEntries)
        : next;
    await _store.write(_entries);
    return _entries;
  }

  Future<List<MockExamHistoryEntry>> reset() async {
    _entries = [];
    await _store.write(_entries);
    return _entries;
  }
}

final mockExamHistoryServiceProvider = Provider<MockExamHistoryService>(
  (ref) => throw UnimplementedError('mockExamHistoryServiceProvider を override してください'),
);

class MockExamHistoryNotifier extends Notifier<List<MockExamHistoryEntry>> {
  MockExamHistoryService get _s => ref.read(mockExamHistoryServiceProvider);

  @override
  List<MockExamHistoryEntry> build() => _s.entries;

  Future<void> record(MockExamResult result) async {
    state = await _s.record(MockExamHistoryEntry.fromResult(result));
  }

  Future<void> reset() async {
    state = await _s.reset();
  }
}

final mockExamHistoryProvider =
    NotifierProvider<MockExamHistoryNotifier, List<MockExamHistoryEntry>>(
  MockExamHistoryNotifier.new,
);

/// [main] で呼ぶ。サービスを [appId] 別の保存先で読み込み、ProviderScope に渡す override を返す。
Future<List<Override>> mockExamHistoryOverrides(String appId) async {
  final service = MockExamHistoryService(store: MockExamHistoryStore(appId));
  await service.load();
  return [mockExamHistoryServiceProvider.overrideWithValue(service)];
}

