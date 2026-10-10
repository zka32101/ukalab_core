import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'coin_ledger.dart';
import 'coin_rules.dart';
import 'shop.dart';

/// 台帳と装備の保存先。
abstract class CoinStore {
  Future<List<dynamic>?> readLedger();
  Future<void> writeLedger(List<Map<String, dynamic>> json);
  Future<Map<String, String>> readEquipped();
  Future<void> writeEquipped(Map<String, String> category2item);
}

class InMemoryCoinStore implements CoinStore {
  List<dynamic>? _ledger;
  Map<String, String> _equipped = {};

  @override
  Future<List<dynamic>?> readLedger() async => _ledger;

  @override
  Future<void> writeLedger(List<Map<String, dynamic>> json) async => _ledger = json;

  @override
  Future<Map<String, String>> readEquipped() async => Map.of(_equipped);

  @override
  Future<void> writeEquipped(Map<String, String> m) async => _equipped = Map.of(m);
}

/// 端末内の保存。財布は**アプリごと**なので、[appId] でキーを分ける。
class SharedPreferencesCoinStore implements CoinStore {
  SharedPreferencesCoinStore(this.appId);

  final String appId;

  String get _ledgerKey => 'ukalab_coin_ledger_$appId';
  String get _equippedKey => 'ukalab_coin_equipped_$appId';

  @override
  Future<List<dynamic>?> readLedger() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_ledgerKey);
    if (s == null) return null;
    try {
      return jsonDecode(s) as List<dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeLedger(List<Map<String, dynamic>> json) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_ledgerKey, jsonEncode(json));
  }

  @override
  Future<Map<String, String>> readEquipped() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_equippedKey);
    if (s == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(s) as Map);
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> writeEquipped(Map<String, String> m) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_equippedKey, jsonEncode(m));
  }
}

/// 付与の結果。
class CoinGrant {
  const CoinGrant(this.event, this.amount);

  final CoinEvent event;
  final int amount;
}

/// コインの獲得・購入。
///
/// - 獲得は [grant]。同じ契機の二重付与、1日の上限超えは付与しない（null）。
/// - 購入は [purchase]。残高が足りなければ失敗し、残高は負にならない。
/// - 有償・広告視聴での付与は実装しない。
class CoinService {
  CoinService({
    required this.store,
    this.rules = CoinRules.standard,
    this.shop = const [],
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final CoinStore store;
  final CoinRules rules;
  final List<ShopItem> shop;
  final DateTime Function() _clock;

  CoinLedger _ledger = CoinLedger();
  Map<String, String> _equipped = {};

  Future<void> load() async {
    final raw = await store.readLedger();
    _ledger = raw == null ? CoinLedger() : CoinLedger.fromJson(raw);
    _equipped = await store.readEquipped();
  }

  CoinLedger get ledger => _ledger;
  int get balance => _ledger.balance;
  int get totalEarned => _ledger.totalEarned;
  Set<String> get ownedItemIds => _ledger.ownedItemIds;

  /// カテゴリ名 → 装備中の品目ID。
  Map<String, String> get equipped => Map.unmodifiable(_equipped);

  static String dayKey(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  static const _permanent = {
    CoinEventType.newQuestion,
    CoinEventType.coverageStep,
    CoinEventType.accuracyMilestone,
    CoinEventType.mockPass,
    CoinEventType.streak,
    CoinEventType.passReport,
  };

  /// 獲得イベントを記録する。付与したら [CoinGrant]、対象外なら null。
  Future<CoinGrant?> grant(CoinEvent e) async {
    final amount = rules.amountFor(e);
    if (amount <= 0) return null;
    final now = _clock();
    final day = dayKey(now);
    final kind = e.type.name;
    final id = _permanent.contains(e.type) ? '$kind|${e.key}' : '$kind|${e.key}|$day';
    if (_ledger.contains(id)) return null;

    switch (e.type) {
      case CoinEventType.newQuestion:
        if (_ledger.earnedOn(day, kind: kind) + amount > rules.newQuestionDailyCap) return null;
      case CoinEventType.reviewCorrected:
        if (_ledger.earnedOn(day, kind: kind) + amount > rules.reviewCorrectedDailyCap) return null;
      case CoinEventType.accuracyBest:
        if (_ledger.countOn(day, kind) >= rules.accuracyBestDailyCount) return null;
      case CoinEventType.dailyConsult:
      case CoinEventType.mockDone:
      case CoinEventType.mockBest:
        // 1日1回: id に日付が入っているので、同じ日の2回目は上で弾かれる。
        // 試験ID違いでも1日1回にするため、種別単位でも数える。
        if (_ledger.countOn(day, kind) >= 1) return null;
      case CoinEventType.coverageStep:
      case CoinEventType.accuracyMilestone:
      case CoinEventType.mockPass:
      case CoinEventType.streak:
      case CoinEventType.passReport:
        break;
    }

    _ledger.add(CoinEntry(id: id, kind: kind, amount: amount, day: day, at: now));
    await store.writeLedger(_ledger.toJson());
    return CoinGrant(e, amount);
  }

  /// 品目を買う。残高が足りなければ [PurchaseResult.insufficient]（残高は変わらない）。
  Future<PurchaseResult> purchase(String itemId) async {
    final matches = shop.where((i) => i.id == itemId);
    if (matches.isEmpty) return PurchaseResult.unknownItem;
    final item = matches.first;
    if (_ledger.ownedItemIds.contains(itemId)) return PurchaseResult.alreadyOwned;
    if (_ledger.balance < item.price) return PurchaseResult.insufficient;
    final now = _clock();
    _ledger.add(CoinEntry(
      id: 'spend|$itemId',
      kind: 'spend',
      amount: -item.price,
      day: dayKey(now),
      at: now,
      ref: itemId,
    ));
    await store.writeLedger(_ledger.toJson());
    return PurchaseResult.purchased;
  }

  /// 持っている品目を着る。カテゴリごとに1つ。持っていなければ false。
  Future<bool> equip(String itemId) async {
    if (!_ledger.ownedItemIds.contains(itemId)) return false;
    final item = shop.where((i) => i.id == itemId);
    if (item.isEmpty) return false;
    _equipped[item.first.category.name] = itemId;
    await store.writeEquipped(_equipped);
    return true;
  }

  Future<void> unequip(ShopCategory category) async {
    _equipped.remove(category.name);
    await store.writeEquipped(_equipped);
  }

  /// 別端末・サーバーの台帳を統合する（端末移行・アカウント同期）。残高は統合後の台帳の合計。
  Future<void> mergeLedger(CoinLedger other) async {
    _ledger = _ledger.merge(other);
    await store.writeLedger(_ledger.toJson());
  }
}
