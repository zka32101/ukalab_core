import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/exam_date.dart';

void main() {
  test('受験日を保存して再読み込みでき、nullで解除できる', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer(overrides: [
      examDateStoreProvider.overrideWithValue(ExamDateStore('t')),
    ]);
    addTearDown(c.dispose);
    expect(c.read(examDateProvider), isNull);

    await c.read(examDateProvider.notifier).setDate(DateTime(2027, 3, 14, 9, 30));
    expect(c.read(examDateProvider), DateTime(2027, 3, 14));

    final c2 = ProviderContainer(overrides: [
      examDateStoreProvider.overrideWithValue(ExamDateStore('t')),
    ]);
    addTearDown(c2.dispose);
    await c2.read(examDateProvider.notifier).load();
    expect(c2.read(examDateProvider), DateTime(2027, 3, 14));

    await c2.read(examDateProvider.notifier).setDate(null);
    expect(c2.read(examDateProvider), isNull);
    expect(await ExamDateStore('t').read(), isNull);
  });

  test('アプリIDが違えば保存先も別', () async {
    SharedPreferences.setMockInitialValues({});
    await ExamDateStore('a').write(DateTime(2027, 1, 1));
    expect(await ExamDateStore('b').read(), isNull);
  });
}
