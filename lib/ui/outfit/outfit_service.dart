import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../mascot/mascot_models.dart';
import '../theme/ukalab_palette.dart';
import 'outfit_models.dart';

/// 衣装の解放状態の保存先。
abstract class OutfitStore {
  Future<Map<String, dynamic>?> read();
  Future<void> write(Map<String, dynamic> json);
}

class InMemoryOutfitStore implements OutfitStore {
  Map<String, dynamic>? _m;

  @override
  Future<Map<String, dynamic>?> read() async => _m;

  @override
  Future<void> write(Map<String, dynamic> json) async => _m = json;
}

class SharedPreferencesOutfitStore implements OutfitStore {
  SharedPreferencesOutfitStore(this.appId);

  final String appId;

  String get _key => 'ukalab_outfit_$appId';

  @override
  Future<Map<String, dynamic>?> read() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    if (s == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(s) as Map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(Map<String, dynamic> json) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(json));
  }
}

/// 衣装を着られるか、の判定理由。
enum OutfitAvailability {
  /// 着られる
  available,

  /// 通常衣装: コインで買っていない
  notPurchased,

  /// 合格記念: 合格報告で「合格」を選んでいない
  notPassed,

  /// 試験日の装い: 試験日を設定していない（または過ぎた）
  noExamDate,

  /// 準備完了: 最短ルートの目標を達成していない
  notReady,
}

/// 衣装の解放と装備。
///
/// - 合格記念: [reportPassed]（合格報告で「合格」を選んだ場合のみ呼ぶ。コイン不要）
/// - 準備完了: [markReady]（最短ルートの目標達成で呼ぶ。無料）
/// - 通常衣装: コインで購入した品目ID（`CoinService.ownedItemIds`）を [isAvailable] に渡す
/// - 試験日の装い: 試験日を設定した人だけ（無料）
class OutfitService {
  OutfitService({required this.store});

  final OutfitStore store;

  final Set<String> _passed = {};
  final Set<String> _ready = {};
  String? _equipped;

  Set<String> get passedCerts => Set.unmodifiable(_passed);
  Set<String> get readyCerts => Set.unmodifiable(_ready);
  String? get equippedId => _equipped;

  Future<void> load() async {
    final m = await store.read();
    _passed
      ..clear()
      ..addAll(List<String>.from((m?['passed'] as List?) ?? const []));
    _ready
      ..clear()
      ..addAll(List<String>.from((m?['ready'] as List?) ?? const []));
    _equipped = m?['equipped'] as String?;
  }

  /// 端末移行・アカウント同期用に、解放状態を JSON で書き出す。
  Map<String, dynamic> toStateJson() => {
        'passed': _passed.toList()..sort(),
        'ready': _ready.toList()..sort(),
        if (_equipped != null) 'equipped': _equipped,
      };

  /// 別端末・サーバーの解放状態を統合する（端末移行・アカウント同期）。合格・準備完了は
  /// 足し合わせ、着ている衣装は端末内で決まっていればそちらを優先する。何度呼んでも同じ。
  Future<void> mergeState(Map<String, dynamic> remote) async {
    _passed.addAll(List<String>.from((remote['passed'] as List?) ?? const []));
    _ready.addAll(List<String>.from((remote['ready'] as List?) ?? const []));
    _equipped ??= remote['equipped'] as String?;
    await _save();
  }

  Future<void> _save() => store.write(toStateJson());

  /// 合格報告で「合格」を選んだとき。初めてなら true（記念衣装が解放される）。
  Future<bool> reportPassed(UkalabCert cert) async {
    final added = _passed.add(cert.id);
    if (added) await _save();
    return added;
  }

  /// 最短ルートの目標を達成したとき。初めてなら true。
  Future<bool> markReady(UkalabCert cert) async {
    final added = _ready.add(cert.id);
    if (added) await _save();
    return added;
  }

  OutfitAvailability availability(
    Outfit o, {
    Set<String> purchasedIds = const {},
    ExamPhase examPhase = ExamPhase.none,
  }) {
    switch (o.kind) {
      case OutfitKind.regular:
        return purchasedIds.contains(o.id) ? OutfitAvailability.available : OutfitAvailability.notPurchased;
      case OutfitKind.passMemorial:
        return _passed.contains(o.cert.id) ? OutfitAvailability.available : OutfitAvailability.notPassed;
      case OutfitKind.examDay:
        return examPhase == ExamPhase.none ? OutfitAvailability.noExamDate : OutfitAvailability.available;
      case OutfitKind.readiness:
        return _ready.contains(o.cert.id) ? OutfitAvailability.available : OutfitAvailability.notReady;
    }
  }

  bool isAvailable(Outfit o, {Set<String> purchasedIds = const {}, ExamPhase examPhase = ExamPhase.none}) =>
      availability(o, purchasedIds: purchasedIds, examPhase: examPhase) == OutfitAvailability.available;

  /// 着る。着られない衣装は false（状態は変わらない）。
  Future<bool> equip(
    String outfitId, {
    Set<String> purchasedIds = const {},
    ExamPhase examPhase = ExamPhase.none,
  }) async {
    final o = OutfitCatalog.byId(outfitId);
    if (o == null || !isAvailable(o, purchasedIds: purchasedIds, examPhase: examPhase)) return false;
    _equipped = outfitId;
    await _save();
    return true;
  }

  Future<void> unequip() async {
    _equipped = null;
    await _save();
  }

  /// 今着ている衣装。解放条件を満たさなくなった（試験日が過ぎたなど）ら null。
  Outfit? currentOutfit({Set<String> purchasedIds = const {}, ExamPhase examPhase = ExamPhase.none}) {
    final id = _equipped;
    if (id == null) return null;
    final o = OutfitCatalog.byId(id);
    if (o == null || !isAvailable(o, purchasedIds: purchasedIds, examPhase: examPhase)) return null;
    return o;
  }

  /// その資格の衣装を、着られるものを先頭にして並べる。
  List<Outfit> outfitsFor(
    UkalabCert cert, {
    Set<String> purchasedIds = const {},
    ExamPhase examPhase = ExamPhase.none,
  }) {
    final l = OutfitCatalog.forCert(cert);
    l.sort((a, b) {
      final av = isAvailable(a, purchasedIds: purchasedIds, examPhase: examPhase) ? 0 : 1;
      final bv = isAvailable(b, purchasedIds: purchasedIds, examPhase: examPhase) ? 0 : 1;
      return av != bv ? av - bv : a.kind.index - b.kind.index;
    });
    return l;
  }
}
