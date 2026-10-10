import '../coin/shop.dart';
import '../theme/ukalab_palette.dart';

/// 衣装の種類（推し×資格連動要素 v0.1）。
enum OutfitKind {
  /// 資格別の衣装・小物。コインで買う
  regular,

  /// 合格記念。合格報告で「合格」を選んだ場合のみ解放（コイン不要）
  passMemorial,

  /// 試験日の装い。試験日を設定した人だけ（日程連動。無料）
  examDay,

  /// 準備完了の装い。最短ルートの目標達成で解放（達成連動。無料）
  readiness,
}

/// 衣装1着の定義。
///
/// 試験団体のロゴ・制服・公式の意匠は使わない（誤認防止）。
/// 見た目は分野の小物と資格のシンボルだけで表す。
class Outfit {
  const Outfit({
    required this.id,
    required this.kind,
    required this.cert,
    required this.name,
    this.price = 0,
  });

  final String id;
  final OutfitKind kind;
  final UkalabCert cert;
  final String name;

  /// コイン。[OutfitKind.regular] だけ 0 より大きい。
  final int price;

  bool get isPurchasable => kind == OutfitKind.regular;

  /// 見た目に使う小物の分野。
  UkalabField get field => cert.field;
}

/// 衣装の台帳。資格ごとに4着（通常・合格記念・試験日・準備完了）。
class OutfitCatalog {
  const OutfitCatalog._();

  /// 通常衣装の価格（衣装の目安 200〜500 の中央）。
  static const int regularPrice = 300;

  static String idOf(UkalabCert cert, OutfitKind kind) => '${kind.name}.${cert.id}';

  static final List<Outfit> all = List.unmodifiable([
    for (final c in UkalabCert.values) ...[
      Outfit(id: idOf(c, OutfitKind.regular), kind: OutfitKind.regular, cert: c, name: '${c.label}の衣装', price: regularPrice),
      Outfit(id: idOf(c, OutfitKind.passMemorial), kind: OutfitKind.passMemorial, cert: c, name: '${c.label} 合格記念'),
      Outfit(id: idOf(c, OutfitKind.examDay), kind: OutfitKind.examDay, cert: c, name: '${c.label} 試験日の装い'),
      Outfit(id: idOf(c, OutfitKind.readiness), kind: OutfitKind.readiness, cert: c, name: '${c.label} 準備完了'),
    ],
  ]);

  static Outfit? byId(String id) {
    for (final o in all) {
      if (o.id == id) return o;
    }
    return null;
  }

  static List<Outfit> forCert(UkalabCert cert) => [for (final o in all) if (o.cert == cert) o];

  /// ショップに並べる品目（通常衣装だけ。ほかは無料で解放される）。
  static List<ShopItem> shopItems([Iterable<UkalabCert>? certs]) => [
        for (final c in certs ?? UkalabCert.values)
          ShopItem(
            id: idOf(c, OutfitKind.regular),
            name: '${c.label}の衣装',
            category: ShopCategory.outfit,
            price: regularPrice,
          ),
      ];
}
