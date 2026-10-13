import 'package:flutter/widgets.dart';

import '../coin/shop.dart';
import 'ukalab_characters.dart';

/// 推しが身につける・手に持つ小物（ショップの「小物」）。
///
/// 画像は小物を持った（かぶった）推しの全身。`assets/mascot/<id>/items/<id>_<file>.webp`。
/// 小物ごとに似合うキャラだけ画像がある（各キャラ3種）。
enum UkalabAccessory {
  helmet('helmet', 'ヘルメット'),
  hachimaki('hachimaki', 'はちまき'),
  calculator('calculator', '電卓'),
  notebookPc('notebook_pc', 'ノートPC'),
  goggles('goggles', 'ゴーグル'),
  drone('drone', 'ドローン');

  const UkalabAccessory(this.file, this.label);

  /// ファイル名の一部。
  final String file;

  /// 表示名（日本語）。
  final String label;
}

class UkalabAccessories {
  const UkalabAccessories._();

  /// ショップでの価格（小物の目安 50〜150 の中）。
  static const int price = 100;

  /// キャラごとの、画像のある小物。
  static const Map<String, List<UkalabAccessory>> byCharacter = {
    'kai': [UkalabAccessory.helmet, UkalabAccessory.hachimaki, UkalabAccessory.drone],
    'mio': [UkalabAccessory.calculator, UkalabAccessory.goggles, UkalabAccessory.notebookPc],
    'moka': [UkalabAccessory.hachimaki, UkalabAccessory.goggles, UkalabAccessory.drone],
    'mike': [UkalabAccessory.helmet, UkalabAccessory.calculator, UkalabAccessory.notebookPc],
  };

  /// キャラ [id] が使える小物（標準キャラ・未知の id は空）。
  static List<UkalabAccessory> availableFor(String id) => byCharacter[id] ?? const [];

  /// 小物を持った推しの画像。画像が無い組み合わせは null。
  static ImageProvider? image(String id, UkalabAccessory a) {
    if (!availableFor(id).contains(a)) return null;
    return AssetImage('assets/mascot/$id/items/${id}_${a.file}.webp', package: UkalabCharacters.package);
  }

  /// ショップの品目ID（`acc_<file>`）。
  static String shopId(UkalabAccessory a) => 'acc_${a.file}';

  /// ショップの品目ID から小物へ。該当なしは null。
  static UkalabAccessory? fromShopId(String id) {
    for (final a in UkalabAccessory.values) {
      if (shopId(a) == id) return a;
    }
    return null;
  }

  /// キャラ [id] 向けのショップ品目（カテゴリは [ShopCategory.accessory]）。
  static List<ShopItem> shopItems(String id) => [
    for (final a in availableFor(id))
      ShopItem(id: shopId(a), name: a.label, category: ShopCategory.accessory, price: price),
  ];
}
