// 共通UI部品のアクセシビリティを、まとめて機械的に確かめる。
//
// 次を、部品 × 言語（ja/en）× 文字の大きさ（標準・200%）× 明暗で確かめる。
//  - 文字を200%に拡大しても、はみ出し（overflow）や例外が出ない。幅の狭い端末（320dp）でも
//  - タップできるものは、タップ領域が Android 48dp・iOS 44pt 以上（Flutter 標準の検査）
//  - タップできるものは、読み上げ用のラベルを持つ
//  - 文字のコントラスト比が基準（Flutter 標準の検査）を満たす
//
// 部品を足したら、下の [_catalog] に1行足す。
import 'package:app_common_kit/app_common_kit.dart';
import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 検査する部品。それぞれ画面1枚（Scaffold つき）として組み立てる。
final _catalog = <String, Widget Function()>{
  'CoinBreakdownCard': () => _body(CoinBreakdownCard(grants: [
        CoinGrant(CoinEvent.newQuestion('q1'), 5),
        CoinGrant(CoinEvent.mockPass('m1'), 50),
      ])),
  'WardrobeScreen': () => const WardrobeScreen(cert: UkalabCert.bikeLicense),
  'UkalabOshiCard': () => _body(const UkalabOshiCard(cert: UkalabCert.bikeLicense, stage: MascotStage.lv1, appId: 'a11y')),
  'UkalabShell': () => UkalabShell(pages: [for (var i = 0; i < 5; i++) Center(child: Text('page $i'))]),
};

/// 部品を置く台。Flutter の検査は、画面の端に接している部品を「スクロールで一部が隠れているかも」
/// として検査から外す。端に接しないよう、周りに余白を付ける（付けないと空振りする）。
Widget _body(Widget child) => Scaffold(
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child),
    );

/// 部品を、条件を指定して組み立てる。
Widget _app(Widget page, {required KitStrings strings, required double scale, required Brightness brightness}) {
  final coin = CoinService(store: InMemoryCoinStore(), shop: OutfitCatalog.shopItems([UkalabCert.bikeLicense]));
  final outfit = OutfitService(store: InMemoryOutfitStore());
  return ProviderScope(
    overrides: [
      coinServiceProvider.overrideWithValue(coin),
      outfitServiceProvider.overrideWithValue(outfit),
    ],
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo, brightness: brightness),
      builder: (context, child) => KitStringsScope(
        strings: strings,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
      home: page,
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget Function() build, {
  required KitStrings strings,
  double scale = 1.0,
  Brightness brightness = Brightness.light,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(build(), strings: strings, scale: scale, brightness: brightness));
  // 非同期の初期化（購入商品の取得など）を進める。pumpAndSettle は無限アニメで終わらないことがあるので使わない。
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final languages = {'ja': KitStrings.ja, 'en': KitStrings.en};

  group('文字を200%に拡大しても、はみ出さない', () {
    for (final e in _catalog.entries) {
      for (final l in languages.entries) {
        testWidgets('${e.key} [${l.key}]', (tester) async {
          await _pump(tester, e.value, strings: l.value, scale: 2.0);
          expect(tester.takeException(), isNull);
        });
        testWidgets('${e.key} [${l.key}] 幅320dpの端末', (tester) async {
          await _pump(tester, e.value, strings: l.value, scale: 2.0, size: const Size(320, 640));
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('タップ領域・読み上げラベル', () {
    for (final e in _catalog.entries) {
      for (final l in languages.entries) {
        for (final scale in [1.0, 2.0]) {
          testWidgets('${e.key} [${l.key}] 文字×$scale', (tester) async {
            final handle = tester.ensureSemantics();
            await _pump(tester, e.value, strings: l.value, scale: scale);
            await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
            await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
            await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
            handle.dispose();
          });
        }
      }
    }
  });

  group('文字のコントラスト', () {
    for (final e in _catalog.entries) {
      for (final b in Brightness.values) {
        testWidgets('${e.key} [${b.name}]', (tester) async {
          final handle = tester.ensureSemantics();
          await _pump(tester, e.value, strings: KitStrings.ja, brightness: b);
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });
      }
    }
  });

  // 検査が空振りしていないこと（セマンティクスが無効、などで何でも通ってしまわないこと）の確認。
  group('この検査自体が、悪い部品を検知できる', () {
    Widget bad() => _body(Column(children: [
          // 20dp 四方で、読み上げラベルが無いタップ対象
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add),
            iconSize: 12,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          ),
          // 背景とほぼ同じ色の文字
          const Text('薄い文字', style: TextStyle(color: Color(0xFFF4F4F4))),
        ]));

    for (final g in {
      'タップ領域（Android）': androidTapTargetGuideline,
      'タップ領域（iOS）': iOSTapTargetGuideline,
      '読み上げラベル': labeledTapTargetGuideline,
      'コントラスト': textContrastGuideline,
    }.entries) {
      testWidgets(g.key, (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(tester, bad, strings: KitStrings.ja);
        // isNot(meetsGuideline(..)) は非同期マッチャーを反転できず固まるので、結果を直接取る。
        final result = await g.value.evaluate(tester);
        expect(result.passed, isFalse, reason: '${g.key}: 悪い部品を検知できていません');
        handle.dispose();
      });
    }

    testWidgets('はみ出しの検知（200%でも収まらない部品）', (tester) async {
      await _pump(tester, () => _body(Row(children: [Text('あ' * 200)])), strings: KitStrings.ja, scale: 2.0);
      expect(tester.takeException(), isNotNull);
    });
  });
}
