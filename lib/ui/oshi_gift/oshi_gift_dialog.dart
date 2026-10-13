import 'package:app_common_kit/app_common_kit.dart' show KitStrings;
import 'package:flutter/material.dart';

import '../../oshi/oshi_gift_strings.dart';
import '../mascot/mascot_models.dart';
import '../mascot/mascot_widget.dart';
import '../outfit/outfit_models.dart';
import 'oshi_gift.dart';

/// プレゼントが解放されたことを祝うダイアログ。
///
/// 画像が無ければ、衣装は仮のアイコン、背景はコード描画のグラデーションで見せる。
/// 文言は [strings]、無ければ `KitStringsScope` の言語（ja・en。他は日本語）。
/// 「動きを減らす」設定のときは出現の動きを付けない。
Future<void> showOshiGiftDialog(
  BuildContext context, {
  required OshiGift gift,
  CharacterPack pack = CharacterPack.standard,
  MascotStage stage = MascotStage.lv1,
  Outfit? outfit,
  OshiGiftStrings? strings,
}) {
  final s = strings ?? OshiGiftStrings.forLanguageCode(KitStrings.of(context).languageCode);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.titleOf(gift.kind)),
      content: SingleChildScrollView(
        child: OshiGiftCard(gift: gift, pack: pack, stage: stage, outfit: outfit, strings: s),
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(s.close)),
      ],
    ),
  );
}

/// ダイアログの中身（単体でも使える）。
class OshiGiftCard extends StatelessWidget {
  const OshiGiftCard({
    super.key,
    required this.gift,
    required this.strings,
    this.pack = CharacterPack.standard,
    this.stage = MascotStage.lv1,
    this.outfit,
    this.previewSize = 160,
  });

  final OshiGift gift;
  final OshiGiftStrings strings;
  final CharacterPack pack;
  final MascotStage stage;
  final Outfit? outfit;
  final double previewSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final body = strings.bodyOf(gift);
    final reason = strings.reasonOf(gift);
    final preview = _Preview(
      gift: gift,
      pack: pack,
      stage: stage,
      outfit: outfit,
      size: previewSize,
      reduce: reduce,
    );
    return Semantics(
      container: true,
      label: '${strings.titleOf(gift.kind)}。$body $reason',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: reduce ? 1 : 0.85, end: 1),
              duration: reduce ? Duration.zero : const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: preview,
            ),
            const SizedBox(height: 12),
            Text(body, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(reason, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            if (gift.image == null) ...[
              const SizedBox(height: 6),
              Text(strings.placeholderNote, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.gift,
    required this.pack,
    required this.stage,
    required this.outfit,
    required this.size,
    required this.reduce,
  });

  final OshiGift gift;
  final CharacterPack pack;
  final MascotStage stage;
  final Outfit? outfit;
  final double size;
  final bool reduce;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final img = gift.image;
    final drawn = gift.kind == OshiGiftKind.background
        ? _drawnBackground(scheme)
        : _drawnOutfit(scheme);
    final box = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: size,
        height: size,
        child: img == null
            ? drawn
            : Image(
                image: img,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => drawn,
              ),
      ),
    );
    return box;
  }

  Widget _drawnOutfit(ColorScheme scheme) => Container(
    color: scheme.secondaryContainer,
    alignment: Alignment.center,
    child: Icon(Icons.checkroom, size: size * 0.5, color: scheme.onSecondaryContainer),
  );

  /// id から色相を決めた、決まった見た目のグラデーション（同じ id なら同じ色）。
  Widget _drawnBackground(ColorScheme scheme) {
    final hue = (gift.id.codeUnits.fold<int>(0, (a, c) => (a * 31 + c) % 360)).toDouble();
    final dark = scheme.brightness == Brightness.dark;
    final top = HSLColor.fromAHSL(1, hue, 0.55, dark ? 0.32 : 0.82).toColor();
    final bottom = HSLColor.fromAHSL(1, (hue + 40) % 360, 0.55, dark ? 0.22 : 0.68).toColor();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
      ),
      alignment: Alignment.bottomCenter,
      child: MascotWidget(
        pack: pack,
        stage: stage,
        outfit: outfit,
        size: size * 0.6,
        animate: !reduce,
      ),
    );
  }
}
