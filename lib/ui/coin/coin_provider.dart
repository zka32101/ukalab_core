import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'coin_rules.dart';
import 'coin_service.dart';
import 'coin_sync.dart';
import 'shop.dart';

/// アプリ側で上書きして使う。
///
/// ```dart
/// ProviderScope(overrides: [
///   coinServiceProvider.overrideWithValue(CoinService(
///     store: SharedPreferencesCoinStore('bike'), shop: myShopItems)),
/// ])
/// ```
final coinServiceProvider = Provider<CoinService>(
  (ref) => throw UnimplementedError('coinServiceProvider を override してください'),
);

class CoinState {
  const CoinState({
    this.balance = 0,
    this.totalEarned = 0,
    this.owned = const {},
    this.equipped = const {},
    this.lastGrant,
    this.recent = const [],
  });

  final int balance;
  final int totalEarned;
  final Set<String> owned;
  final Map<String, String> equipped;

  /// 直近の付与（画面で小さく控えめに知らせる用）。
  final CoinGrant? lastGrant;

  /// [CoinNotifier.takeRecent] を最後に呼んでから付与された分（新しい順ではなく付与順）。
  /// 結果画面のコイン内訳（`CoinBreakdownCard`）に使う。
  final List<CoinGrant> recent;
}

class CoinNotifier extends Notifier<CoinState> {
  CoinService get _s => ref.read(coinServiceProvider);

  @override
  CoinState build() => _snapshot();

  final List<CoinGrant> _recent = [];

  CoinState _snapshot({CoinGrant? grant}) => CoinState(
        balance: _s.balance,
        totalEarned: _s.totalEarned,
        owned: _s.ownedItemIds,
        equipped: _s.equipped,
        lastGrant: grant,
        recent: List.unmodifiable(_recent),
      );

  /// 溜まった付与の履歴を取り出して空にする（学習セッションの開始時・終了時に呼ぶ）。
  List<CoinGrant> takeRecent() {
    final taken = List<CoinGrant>.of(_recent);
    _recent.clear();
    state = _snapshot();
    return taken;
  }

  Future<void> load() async {
    await _s.load();
    state = _snapshot();
  }

  Future<CoinGrant?> grant(CoinEvent e) async {
    final g = await _s.grant(e);
    if (g != null) _recent.add(g);
    state = _snapshot(grant: g);
    return g;
  }

  Future<PurchaseResult> purchase(String itemId) async {
    final r = await _s.purchase(itemId);
    state = _snapshot();
    return r;
  }

  DateTime? _lastSync;
  bool _syncing = false;

  /// サーバー（共通アカウント）の台帳と統合して、画面の状態を更新する。
  ///
  /// アプリ起動時・購入の後などに呼ぶ。[minInterval] 以内に同期済み、または同期中なら
  /// 何もせず null を返す。失敗（オフライン等）は [CoinSyncResult.failed]（例外は出さない）。
  Future<CoinSyncResult?> syncWith(
    CoinRemote remote, {
    Duration minInterval = Duration.zero,
    DateTime Function()? clock,
  }) async {
    final now = (clock ?? DateTime.now)();
    final last = _lastSync;
    if (_syncing || (last != null && now.difference(last) < minInterval)) return null;
    _syncing = true;
    try {
      final r = await CoinSync(service: _s, remote: remote).sync();
      if (r == CoinSyncResult.synced) _lastSync = now;
      state = _snapshot();
      return r;
    } finally {
      _syncing = false;
    }
  }

  Future<bool> equip(String itemId) async {
    final ok = await _s.equip(itemId);
    state = _snapshot();
    return ok;
  }
}

final coinProvider = NotifierProvider<CoinNotifier, CoinState>(CoinNotifier.new);
