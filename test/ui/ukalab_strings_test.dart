import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

Widget _wrap(Widget child, {KitStrings? strings}) => MaterialApp(
  home: Scaffold(
    body: strings == null
        ? child
        : KitStringsScope(strings: strings, child: child),
  ),
);

void main() {
  testWidgets('UkalabShell の下部タブ。labels を渡せば優先', (tester) async {
    final pages = [for (var i = 0; i < 5; i++) Text('p$i')];
    await tester.pumpWidget(MaterialApp(
      home: KitStringsScope(strings: KitStrings.en, child: UkalabShell(pages: pages)),
    ));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: UkalabShell(pages: pages)));
    expect(find.text('ホーム'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(
      home: KitStringsScope(
        strings: KitStrings.en,
        child: UkalabShell(pages: pages, labels: const ['a', 'b', 'c', 'd', 'e']),
      ),
    ));
    expect(find.text('a'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('共有カードの文言・日付が ja/en で切り替わる', (tester) async {
    final data = ShareCardData(
      certLabel: 'Bike License',
      date: DateTime(2026, 10, 9),
      packName: 'p',
      stage: MascotStage.lv1,
    );
    await tester.pumpWidget(_wrap(SizedBox(width: 400, height: 500, child: PassShareCard(data: data))));
    expect(find.text('うかラボ'), findsOneWidget);
    expect(find.text('合格しました！'), findsOneWidget);
    expect(find.text('2026年10月9日'), findsOneWidget);

    await tester.pumpWidget(_wrap(
      SizedBox(width: 400, height: 500, child: PassShareCard(data: data)),
      strings: KitStrings.en,
    ));
    expect(find.text('Qualab'), findsOneWidget);
    expect(find.text('I passed!'), findsOneWidget);
    expect(find.text('Oct 9, 2026'), findsOneWidget);

    // message を渡せば Scope より優先。strings 引数も Scope より優先。
    final custom = ShareCardData(
      certLabel: 'x',
      date: DateTime(2026, 1, 1),
      packName: 'p',
      stage: MascotStage.lv1,
      message: 'Great!',
    );
    await tester.pumpWidget(_wrap(
      SizedBox(width: 400, height: 500, child: PassShareCard(data: custom, strings: KitStrings.en)),
    ));
    expect(find.text('Great!'), findsOneWidget);
    expect(find.text('Jan 1, 2026'), findsOneWidget);
  });

  test('forLocale と全イベントの表示名', () {
    expect(KitStrings.forLocale(const Locale('en', 'US')), same(KitStrings.en));
    expect(KitStrings.forLocale(const Locale('fr')), same(KitStrings.ja));
    for (final t in CoinEventType.values) {
      expect(
        KitStrings.en.coinEventLabels.containsKey(t.name),
        isTrue,
        reason: t.name,
      );
      expect(
        KitStrings.ja.coinEventLabels.containsKey(t.name),
        isTrue,
        reason: t.name,
      );
    }
    expect(coinEventLabel(CoinEventType.streak, KitStrings.en), 'Study streak');
    expect(coinEventLabel(CoinEventType.streak), '連続学習');
  });
}
