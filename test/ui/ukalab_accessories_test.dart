import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

void main() {
  test('各キャラの小物画像が存在し、合計12枚・6種すべてが誰かに割り当て済み', () {
    var n = 0;
    final used = <UkalabAccessory>{};
    for (final p in UkalabCharacters.imagePacks) {
      for (final a in UkalabAccessories.availableFor(p.id)) {
        final img = UkalabAccessories.image(p.id, a)! as AssetImage;
        expect(File(img.assetName).existsSync(), true, reason: img.assetName);
        n++;
        used.add(a);
      }
    }
    expect(n, 12);
    expect(used, UkalabAccessory.values.toSet());
  });

  test('画像の無い組み合わせ・標準キャラは null', () {
    expect(UkalabAccessories.image('kai', UkalabAccessory.calculator), isNull);
    expect(UkalabAccessories.availableFor('standard'), isEmpty);
  });

  test('ショップ品目は accessory・価格帯内・ID往復できる', () {
    final items = UkalabAccessories.shopItems('mio');
    expect(items.length, 3);
    expect(validateShop(items), isEmpty);
    for (final i in items) {
      expect(i.category, ShopCategory.accessory);
      expect(UkalabAccessories.fromShopId(i.id), isNotNull);
    }
    expect(UkalabAccessories.fromShopId('nope'), isNull);
  });

  testWidgets('部屋: accessory を渡すと小物の絵、未指定なら従来どおり', (tester) async {
    Future<void> pump(UkalabAccessory? a) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: UkalabOshiRoom(pack: UkalabCharacters.kai, accessory: a),
          ),
        ),
      ),
    );
    await pump(UkalabAccessory.helmet);
    final imgs = tester.widgetList<Image>(find.byType(Image)).map((i) => i.image).whereType<AssetImage>();
    expect(imgs.any((i) => i.assetName.endsWith('items/kai_helmet.webp')), true);
    expect(find.byType(MascotWidget), findsNothing);

    await pump(UkalabAccessory.calculator); // カイには無い → いつもの絵
    expect(find.byType(MascotWidget), findsOneWidget);
    await pump(null);
    expect(find.byType(MascotWidget), findsOneWidget);
  });
}
