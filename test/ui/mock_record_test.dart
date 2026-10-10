import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('模擬試験の記録カードは、本番の合格と区別でき、コインも衣装も付けない', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final coin = CoinService(store: InMemoryCoinStore(), shop: const []);
    final outfits = OutfitService(store: InMemoryOutfitStore());
    final c = ProviderContainer(overrides: [
      coinServiceProvider.overrideWithValue(coin),
      outfitServiceProvider.overrideWithValue(outfits),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: TextButton(
              onPressed: () => showMockRecordDialog(
                context,
                ref,
                cert: UkalabCert.bikeLicense,
                stage: MascotStage.lv3,
                scoreText: '正答率 86%',
                onShare: (png) async {},
              ),
              child: const Text('開く'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('開く'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('学習の記録カード'), findsOneWidget);
    expect(find.text('合格点を超えました！'), findsOneWidget);
    expect(find.text('正答率 86%'), findsOneWidget);
    expect(find.text('共有する'), findsOneWidget);
    expect(find.textContaining('本番の合格ではありません'), findsOneWidget);
    expect(coin.balance, 0);
    expect(outfits.passedCerts, isEmpty);
  });
}
