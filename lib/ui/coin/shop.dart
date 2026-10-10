/// ショップの品目。使い道は見た目だけ（衣装・小物・部屋のパーツ）。
library;

enum ShopCategory { accessory, outfit, room }

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
  });

  final String id;
  final String name;
  final ShopCategory category;

  /// コイン。仕様の目安: 小物 50〜150、衣装 200〜500、部屋のパーツ 100〜300。
  final int price;
}

enum PurchaseResult {
  /// 購入できた
  purchased,

  /// コインが足りない
  insufficient,

  /// すでに持っている
  alreadyOwned,

  /// 品目がない
  unknownItem,
}

/// 目安の価格帯（仕様 §3）。範囲外の価格は [validate] で検出する。
const Map<ShopCategory, (int, int)> kPriceRanges = {
  ShopCategory.accessory: (50, 150),
  ShopCategory.outfit: (200, 500),
  ShopCategory.room: (100, 300),
};

/// 品目の一覧に問題がないか調べる。問題の文を返す（空なら問題なし）。
List<String> validateShop(List<ShopItem> items) {
  final problems = <String>[];
  final ids = <String>{};
  for (final i in items) {
    if (!ids.add(i.id)) problems.add('${i.id}: id が重複');
    final r = kPriceRanges[i.category]!;
    if (i.price < r.$1 || i.price > r.$2) {
      problems.add('${i.id}: 価格 ${i.price} が ${i.category.name} の目安 ${r.$1}〜${r.$2} の範囲外');
    }
  }
  return problems;
}
