import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/achievements.dart';

const _list = [
  Achievement(id: 'a', title: 'Aバッジ', description: 'Aの説明', icon: Icons.star, unlocked: true, category: 'x'),
  Achievement(id: 'b', title: 'Bバッジ', description: 'Bの説明', icon: Icons.star, unlocked: false, category: 'y'),
];

void main() {
  test('新しく解除されたIDだけを返し、保存して読み直せる。アプリIDごとに別', () async {
    SharedPreferences.setMockInitialValues({});
    final o = await achievementUnlockOverrides('t1');
    final c = ProviderContainer(overrides: o);
    addTearDown(c.dispose);
    final n = c.read(achievementUnlockProvider.notifier);
    expect(n.checkNewlyUnlocked({'a'}, DateTime(2026, 10, 11)), ['a']);
    expect(n.checkNewlyUnlocked({'a'}, DateTime(2026, 10, 12)), isEmpty);
    await Future<void>.delayed(Duration.zero);

    final again = await achievementUnlockOverrides('t1');
    final c2 = ProviderContainer(overrides: again);
    addTearDown(c2.dispose);
    expect(c2.read(achievementUnlockProvider).keys, ['a']);

    final other = ProviderContainer(overrides: await achievementUnlockOverrides('t2'));
    addTearDown(other.dispose);
    expect(other.read(achievementUnlockProvider), isEmpty);

    await c.read(achievementUnlockProvider.notifier).reset();
    expect(c.read(achievementUnlockProvider), isEmpty);
  });

  testWidgets('一覧は達成数とカテゴリ絞り込みを出す', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final o = (await tester.runAsync(() => achievementUnlockOverrides('t3')))!;
    await tester.pumpWidget(ProviderScope(
      overrides: [...o, achievementsProvider.overrideWithValue(_list)],
      child: const MaterialApp(home: AchievementsView(categoryLabels: {'x': 'X組', 'y': 'Y組'})),
    ));
    expect(find.text('1 / 2 個達成'), findsOneWidget);
    expect(find.text('Bバッジ'), findsOneWidget);
    await tester.tap(find.text('X組'));
    await tester.pump();
    expect(find.text('Bバッジ'), findsNothing);
    expect(find.text('Aバッジ'), findsOneWidget);
  });
}
