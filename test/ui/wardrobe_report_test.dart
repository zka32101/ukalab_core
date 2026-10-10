import 'package:app_common_kit/app_common_kit.dart';
import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container() {
  final coin = CoinService(
    store: InMemoryCoinStore(),
    shop: OutfitCatalog.shopItems([UkalabCert.bikeLicense]),
  );
  final c = ProviderContainer(overrides: [
    coinServiceProvider.overrideWithValue(coin),
    outfitServiceProvider.overrideWithValue(OutfitService(store: InMemoryOutfitStore())),
  ]);
  addTearDown(c.dispose);
  return c;
}

Future<void> _earn(ProviderContainer c, int passes) async {
  for (var i = 0; i < passes; i++) {
    await c.read(coinProvider.notifier).grant(CoinEvent.mockPass('exam$i'));
  }
}

void _bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('資格の追加', () {
    test('漢字検定が入っている（資格17種・衣装68着）', () {
      expect(UkalabCert.fromId('kanji_kentei'), UkalabCert.kanjiKentei);
      expect(OutfitCatalog.forCert(UkalabCert.kanjiKentei), hasLength(4));
      expect(OutfitCatalog.all, hasLength(68));
    });
  });

  group('ReadinessRule（準備完了の暫定判定）', () {
    const high = MasteryInput(coverage: 0.95, accuracy: 0.9);
    const low = MasteryInput(coverage: 0.3, accuracy: 0.6);
    test('習得度が高く、模擬試験で合格点を超えたら準備完了', () {
      expect(ReadinessRule.standard.isReady(mastery: high, mockPassed: true), isTrue);
    });
    test('習得度が足りない、または模擬試験の合格がなければ準備完了ではない', () {
      expect(ReadinessRule.standard.isReady(mastery: low, mockPassed: true), isFalse);
      expect(ReadinessRule.standard.isReady(mastery: high, mockPassed: false), isFalse);
    });
    test('模擬試験を条件にしない設定もできる', () {
      const rule = ReadinessRule(requireMockPass: false);
      expect(rule.isReady(mastery: high, mockPassed: false), isTrue);
    });
  });

  group('CoinNotifier.recent（セッションの内訳）', () {
    test('付与だけが溜まり、取り出すと空になる。重複で付与されなかった分は入らない', () async {
      final c = _container();
      final n = c.read(coinProvider.notifier);
      await n.grant(CoinEvent.newQuestion('q1'));
      await n.grant(CoinEvent.newQuestion('q1')); // 重複 → 付与なし
      await n.grant(CoinEvent.newQuestion('q2'));
      expect(c.read(coinProvider).recent, hasLength(2));
      final taken = n.takeRecent();
      expect(taken, hasLength(2));
      expect(c.read(coinProvider).recent, isEmpty);
    });
  });

  group('OutfitNotifier', () {
    test('合格報告で合格記念の衣装が着られるようになる', () async {
      final c = _container();
      final cert = UkalabCert.bikeLicense;
      final memorial = OutfitCatalog.byId(OutfitCatalog.idOf(cert, OutfitKind.passMemorial))!;
      expect(await c.read(outfitProvider.notifier).equip(memorial.id), isFalse);
      expect(await c.read(outfitProvider.notifier).reportPassed(cert), isTrue);
      expect(await c.read(outfitProvider.notifier).reportPassed(cert), isFalse); // 2回目は初めてではない
      expect(await c.read(outfitProvider.notifier).equip(memorial.id), isTrue);
      expect(c.read(equippedOutfitProvider)?.id, memorial.id);
    });

    test('準備完了の装いは markReady のあとに着られる', () async {
      final c = _container();
      final cert = UkalabCert.bikeLicense;
      final ready = OutfitCatalog.idOf(cert, OutfitKind.readiness);
      expect(await c.read(outfitProvider.notifier).equip(ready), isFalse);
      await c.read(outfitProvider.notifier).markReady(cert);
      expect(await c.read(outfitProvider.notifier).equip(ready), isTrue);
    });
  });

  group('WardrobeScreen', () {
    Future<ProviderContainer> pump(WidgetTester tester, {int passes = 0}) async {
      _bigScreen(tester);
      final c = _container();
      await _earn(c, passes);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: WardrobeScreen(cert: UkalabCert.bikeLicense)),
      ));
      await tester.pump();
      return c;
    }

    testWidgets('strings を渡すと英語で出る（既定は日本語）', (tester) async {
      _bigScreen(tester);
      final c = _container();
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(
          home: WardrobeScreen(cert: UkalabCert.bikeLicense, strings: KitStrings.en),
        ),
      ));
      await tester.pump();
      expect(find.text('Outfits & shop'), findsOneWidget);
      expect(find.text('Unlocked when you pass'), findsOneWidget);
      expect(find.text('合格したときに解放されます'), findsNothing);
      expect(outfitLockedReason(OutfitAvailability.notPurchased, price: 300, strings: KitStrings.en), 'Buy for 300 coins');
      expect(outfitLockedReason(OutfitAvailability.notPurchased, price: 300), '300コインで購入できます');
    });

    testWidgets('コインが足りないと買えず、ロック理由が見える', (tester) async {
      await pump(tester);
      expect(find.text('合格したときに解放されます'), findsOneWidget);
      expect(find.text('準備完了の目標を達成すると解放されます'), findsOneWidget);
      expect(find.text('試験日を設定すると着られます'), findsOneWidget);
      await tester.tap(find.textContaining('コイン').last);
      await tester.pump();
      expect(find.text('コインが足りません。学習すると貯まります'), findsOneWidget);
    });

    testWidgets('十分なコインで購入して着る', (tester) async {
      final c = await pump(tester, passes: 6);
      await c.read(coinProvider.notifier).load();
      await tester.pump();
      await tester.tap(find.text('300コイン'));
      await tester.pump();
      await tester.tap(find.text('着る'));
      await tester.pump();
      expect(find.text('着ています'), findsOneWidget);
      expect(c.read(equippedOutfitProvider)?.cert, UkalabCert.bikeLicense);
    });
  });

  group('showPassReportDialog', () {
    Future<(ProviderContainer, List<PassReportResult?>)> open(WidgetTester tester) async {
      _bigScreen(tester);
      final c = _container();
      final results = <PassReportResult?>[];
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          home: Consumer(builder: (context, ref, _) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    results.add(await showPassReportDialog(
                      context,
                      ref,
                      cert: UkalabCert.bikeLicense,
                      stage: MascotStage.lv3,
                    ));
                  },
                  child: const Text('報告'),
                ),
              ),
            );
          }),
        ),
      ));
      await tester.tap(find.text('報告'));
      await tester.pumpAndSettle();
      return (c, results);
    }

    testWidgets('合格: コイン200と合格記念の衣装が付く。2回目はコインが付かない', (tester) async {
      final (c, results) = await open(tester);
      await tester.tap(find.text('合格しました'));
      await tester.pumpAndSettle();
      expect(find.text('合格おめでとうございます'), findsOneWidget);
      expect(find.textContaining('学習コイン +${CoinRules.standard.passReport}'), findsOneWidget);
      expect(find.textContaining('個人情報は入りません'), findsOneWidget);
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();
      expect(results, [PassReportResult.passed]);
      expect(c.read(coinProvider).balance, CoinRules.standard.passReport);
      expect(c.read(outfitServiceProvider).passedCerts, contains('bike_license'));

      await tester.tap(find.text('報告'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('合格しました'));
      await tester.pumpAndSettle();
      expect(find.textContaining('学習コイン +'), findsNothing); // 2回目は付与なし
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();
      expect(c.read(coinProvider).balance, CoinRules.standard.passReport);
    });

    testWidgets('合格できなかった: 責めない。コインも衣装も変わらない', (tester) async {
      final (c, results) = await open(tester);
      await tester.tap(find.text('今回は合格できなかった'));
      await tester.pumpAndSettle();
      expect(find.text('おつかれさまでした'), findsOneWidget);
      expect(find.textContaining('そのままです'), findsOneWidget);
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();
      expect(results, [PassReportResult.notPassed]);
      expect(c.read(coinProvider).balance, 0);
      expect(c.read(outfitServiceProvider).passedCerts, isEmpty);
    });

    testWidgets('まだ・結果待ち: 何も起きない', (tester) async {
      final (c, results) = await open(tester);
      await tester.tap(find.text('まだ・結果待ち'));
      await tester.pumpAndSettle();
      expect(results, [PassReportResult.notYet]);
      expect(c.read(coinProvider).balance, 0);
    });
  });

  group('CoinBreakdownCard', () {
    testWidgets('種別ごとに回数と合計が出る。付与がなければ何も出ない', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(children: [
            CoinBreakdownCard(grants: [
              CoinGrant(CoinEvent.newQuestion('a'), 1),
              CoinGrant(CoinEvent.newQuestion('b'), 1),
              CoinGrant(CoinEvent.mockDone(), 10),
            ]),
            const CoinBreakdownCard(grants: [], title: '空'),
          ]),
        ),
      ));
      expect(find.text('新しい問題 ×2'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
      expect(find.text('模擬試験の実施'), findsOneWidget);
      expect(find.text('+12'), findsOneWidget); // 合計
      expect(find.text('空'), findsNothing);
    });
  });
}
