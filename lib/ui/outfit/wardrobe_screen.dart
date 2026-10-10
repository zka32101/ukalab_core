import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coin/coin_provider.dart';
import '../coin/shop.dart';
import '../mascot/mascot_models.dart';
import '../mascot/mascot_widget.dart';
import '../theme/ukalab_palette.dart';
import 'outfit_models.dart';
import 'outfit_provider.dart';
import 'outfit_service.dart';

/// 着られない理由の文言。
String outfitLockedReason(OutfitAvailability a, {int price = 0, KitStrings strings = KitStrings.ja}) {
  switch (a) {
    case OutfitAvailability.available:
      return '';
    case OutfitAvailability.notPurchased:
      return strings.lockedNotPurchased(price);
    case OutfitAvailability.notPassed:
      return strings.lockedNotPassed;
    case OutfitAvailability.noExamDate:
      return strings.lockedNoExamDate;
    case OutfitAvailability.notReady:
      return strings.lockedNotReady;
  }
}

/// 衣装のショップ・着替え画面（資格1つぶん）。
///
/// コインは学習の成長でだけ増える（課金・広告では増えない）。衣装は見た目だけで、
/// 学習の内容には影響しない。`coinServiceProvider` の `shop` に
/// `OutfitCatalog.shopItems([cert])` を渡しておくこと。
class WardrobeScreen extends ConsumerWidget {
  const WardrobeScreen({
    super.key,
    required this.cert,
    this.examPhase = ExamPhase.none,
    this.stage = MascotStage.lv1,
    this.pack = CharacterPack.standard,
    this.title,
    this.strings,
  });

  final UkalabCert cert;
  final ExamPhase examPhase;
  final MascotStage stage;
  final CharacterPack pack;
  /// null なら [KitStrings] の既定。
  final String? title;

  /// null なら最も近い `KitStringsScope`（無ければ日本語）。
  final KitStrings? strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coin = ref.watch(coinProvider);
    final outfit = ref.watch(outfitProvider);
    final service = ref.read(outfitServiceProvider);
    final theme = Theme.of(context);
    final s = strings ?? KitStrings.of(context);

    Future<void> buy(Outfit o) async {
      final r = await ref.read(coinProvider.notifier).purchase(o.id);
      if (!context.mounted) return;
      final msg = switch (r) {
        PurchaseResult.purchased => s.wardrobePurchased(o.name),
        PurchaseResult.insufficient => s.wardrobeInsufficient,
        PurchaseResult.alreadyOwned => s.wardrobeAlreadyOwned,
        PurchaseResult.unknownItem => s.wardrobeUnknown,
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    Future<void> wear(Outfit o) async {
      final ok = await ref.read(outfitProvider.notifier).equip(o.id, examPhase: examPhase);
      if (!context.mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.wardrobeCannotWear)));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(title ?? s.wardrobeTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: MascotWidget(
                pack: pack,
                stage: stage,
                outfit: outfit.equipped,
                examPhase: examPhase,
                size: 140,
              ),
            ),
            const SizedBox(height: 8),
            Center(child: Text(s.coinBalance(coin.balance), style: theme.textTheme.titleMedium)),
            const SizedBox(height: 4),
            Center(
              child: Text(
                s.wardrobeNote,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            for (final o in OutfitCatalog.forCert(cert)) ...[
              _OutfitTile(
                outfit: o,
                availability: service.availability(o, purchasedIds: coin.owned, examPhase: examPhase),
                wearing: outfit.equipped?.id == o.id,
                onBuy: () => buy(o),
                onWear: () => wear(o),
                strings: s,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _OutfitTile extends StatelessWidget {
  const _OutfitTile({
    required this.outfit,
    required this.availability,
    required this.wearing,
    required this.onBuy,
    required this.onWear,
    required this.strings,
  });

  final Outfit outfit;
  final OutfitAvailability availability;
  final bool wearing;
  final VoidCallback onBuy;
  final VoidCallback onWear;
  final KitStrings strings;

  @override
  Widget build(BuildContext context) {
    final available = availability == OutfitAvailability.available;
    final Widget trailing;
    if (wearing) {
      trailing = const Icon(Icons.check_circle);
    } else if (available) {
      trailing = OutlinedButton(onPressed: onWear, child: Text(strings.wardrobeWear));
    } else if (availability == OutfitAvailability.notPurchased) {
      trailing = FilledButton(onPressed: onBuy, child: Text(strings.wardrobePrice(outfit.price)));
    } else {
      trailing = const Icon(Icons.lock_outline);
    }
    // ListTile の trailing は、ボタンが行の幅を使い切るとレイアウトが成り立たなくなる
    // （英語の長いボタン文言＋文字200%＋幅の狭い端末で起きる）。右側の幅に上限を付けた Row にする。
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(outfit.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    wearing
                        ? strings.wardrobeWearing
                        : available
                            ? strings.wardrobeCanWear
                            : outfitLockedReason(availability, price: outfit.price, strings: strings),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 140), child: trailing),
          ],
        ),
      ),
    );
  }
}
