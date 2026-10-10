import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coin/coin_provider.dart';
import '../mascot/mascot_models.dart';
import '../theme/ukalab_palette.dart';
import 'outfit_models.dart';
import 'outfit_service.dart';

/// アプリ側で上書きして使う。
///
/// ```dart
/// ProviderScope(overrides: [
///   outfitServiceProvider.overrideWithValue(
///     OutfitService(store: SharedPreferencesOutfitStore('bike'))..load()),
/// ])
/// ```
final outfitServiceProvider = Provider<OutfitService>(
  (ref) => throw UnimplementedError('outfitServiceProvider を override してください'),
);

/// 衣装の状態。[revision] は解放・着替えのたびに増える（画面の再構築用）。
class OutfitState {
  const OutfitState({this.equipped, this.revision = 0});

  /// 着ている衣装。着ていなければ null。
  final Outfit? equipped;
  final int revision;
}

class OutfitNotifier extends Notifier<OutfitState> {
  OutfitService get _s => ref.read(outfitServiceProvider);

  @override
  OutfitState build() {
    final id = _s.equippedId;
    return OutfitState(equipped: id == null ? null : OutfitCatalog.byId(id));
  }

  OutfitState _next({Outfit? equipped, bool keepEquipped = true}) => OutfitState(
        equipped: keepEquipped ? (equipped ?? state.equipped) : equipped,
        revision: state.revision + 1,
      );

  /// 着る。着られなければ false。購入済みの品目は `coinProvider` から読む。
  Future<bool> equip(String outfitId, {ExamPhase examPhase = ExamPhase.none}) async {
    final owned = ref.read(coinProvider).owned;
    final ok = await _s.equip(outfitId, purchasedIds: owned, examPhase: examPhase);
    if (ok) state = _next(equipped: OutfitCatalog.byId(outfitId));
    return ok;
  }

  /// 合格報告で「合格」を選んだとき。初めてなら true（合格記念の衣装が解放される）。
  Future<bool> reportPassed(UkalabCert cert) async {
    final added = await _s.reportPassed(cert);
    if (added) state = _next();
    return added;
  }

  /// 準備完了の条件を満たしたとき。初めてなら true（準備完了の装いが解放される）。
  Future<bool> markReady(UkalabCert cert) async {
    final added = await _s.markReady(cert);
    if (added) state = _next();
    return added;
  }
}

final outfitProvider = NotifierProvider<OutfitNotifier, OutfitState>(OutfitNotifier.new);

/// 着ている衣装だけ欲しいとき。
final equippedOutfitProvider = Provider<Outfit?>((ref) => ref.watch(outfitProvider).equipped);
