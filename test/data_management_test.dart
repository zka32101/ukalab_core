import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

final _countProvider = StateProvider<int>((ref) => 0);
final _memoProvider = StateProvider<Map<String, String>>((ref) => const {});

List<DataPart> _parts() => [
      DataPart(
        id: 'count',
        export: (ref) => ref.read(_countProvider),
        restore: (ref, json) async => ref.read(_countProvider.notifier).state = json as int,
        reset: (ref) async => ref.read(_countProvider.notifier).state = 0,
      ),
      DataPart(
        id: 'memo',
        export: (ref) => ref.read(_memoProvider),
        restore: (ref, json) async =>
            ref.read(_memoProvider.notifier).state = (json as Map<String, dynamic>).cast<String, String>(),
        reset: (ref) async => ref.read(_memoProvider.notifier).state = const {},
      ),
    ];

Future<WidgetRef> _ref(WidgetTester tester, {List<Override> overrides = const []}) async {
  late WidgetRef captured;
  await tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(
        body: Consumer(builder: (context, ref, _) {
          captured = ref;
          return DataManagementSection(parts: _parts());
        }),
      ),
    ),
  ));
  return captured;
}

void main() {
  testWidgets('書き出して、リセット後に読み込むと元に戻る', (tester) async {
    final ref = await _ref(tester);
    ref.read(_countProvider.notifier).state = 7;
    ref.read(_memoProvider.notifier).state = {'q1': 'メモ'};

    final text = encodeLearningDataBackup(ref, _parts(), now: DateTime(2026, 10, 10));
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    expect(decoded['version'], 1);
    expect((decoded['parts'] as Map).keys, ['count', 'memo']);

    await resetLearningData(ref, _parts());
    expect(ref.read(_countProvider), 0);
    expect(ref.read(_memoProvider), isEmpty);

    await restoreLearningDataBackup(ref, _parts(), text);
    expect(ref.read(_countProvider), 7);
    expect(ref.read(_memoProvider), {'q1': 'メモ'});
  });

  testWidgets('バックアップに無い部品は触らない（古いバックアップを読める）', (tester) async {
    final ref = await _ref(tester);
    ref.read(_memoProvider.notifier).state = {'q1': '残す'};
    await restoreLearningDataBackup(ref, _parts(), '{"version":1,"parts":{"count":3}}');
    expect(ref.read(_countProvider), 3);
    expect(ref.read(_memoProvider), {'q1': '残す'});
  });

  testWidgets('parts を持たない旧形式（項目がトップレベル）も読める', (tester) async {
    final ref = await _ref(tester);
    await restoreLearningDataBackup(ref, _parts(), '{"version":1,"exportedAt":"2026-10-06","count":4}');
    expect(ref.read(_countProvider), 4);
    expect(ref.read(_memoProvider), isEmpty);
  });

  testWidgets('不正な形式・未対応バージョンは FormatException', (tester) async {
    final ref = await _ref(tester);
    for (final bad in ['これはJSONではない', '[1,2]', '{"version":9,"parts":{}}', '{"version":1,"parts":5}']) {
      expect(() => restoreLearningDataBackup(ref, _parts(), bad), throwsFormatException, reason: bad);
    }
  });

  testWidgets('非同期の部品は Async 版で書き出せ、同期版は StateError', (tester) async {
    final ref = await _ref(tester);
    final parts = [
      DataPart(
        id: 'slow',
        export: (ref) async => [1, 2],
        restore: (ref, json) async {},
        reset: (ref) async {},
      ),
    ];
    expect(() => encodeLearningDataBackup(ref, parts), throwsStateError);
    final text = await encodeLearningDataBackupAsync(ref, parts, now: DateTime(2026, 10, 10));
    expect((jsonDecode(text) as Map<String, dynamic>)['parts'], {'slow': [1, 2]});
  });

  testWidgets('リセットは確認ダイアログを経る', (tester) async {
    final ref = await _ref(tester);
    ref.read(_countProvider.notifier).state = 5;
    await tester.tap(find.text('学習記録をリセット'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(ref.read(_countProvider), 5);

    await tester.tap(find.text('学習記録をリセット'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('リセットする'));
    await tester.pumpAndSettle();
    expect(ref.read(_countProvider), 0);
  });
}
