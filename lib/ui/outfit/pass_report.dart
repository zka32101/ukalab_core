import 'package:app_common_kit/app_common_kit.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coin/coin_provider.dart';
import '../coin/coin_rules.dart';
import '../mascot/mascot_models.dart';
import '../theme/ukalab_palette.dart';
import 'outfit_models.dart';
import 'outfit_provider.dart';
import 'share_card.dart';

/// 合格報告の結果。
enum PassReportResult {
  /// 「合格しました」を選んだ（コインと合格記念の衣装を付与した）
  passed,

  /// 「まだ受けていない／結果待ち」
  notYet,

  /// 「今回は合格できなかった」（何も減らさない。応援の文言を出す）
  notPassed,
}

/// 合格報告のダイアログを出す。
///
/// - 「合格しました」: 学習コイン（[CoinEvent.passReport]。資格ごとに1回だけ）と、
///   合格記念の衣装を付与し、共有カードを見せる。**自己申告**であり、
///   試験団体への照会はしない。
/// - 「今回は合格できなかった」: 責めない。コインや衣装は一切減らさない。
/// - [onShare] を渡すと「共有する」ボタンを出す（OS の共有シートはアプリ側で実装）。
Future<PassReportResult?> showPassReportDialog(
  BuildContext context,
  WidgetRef ref, {
  required UkalabCert cert,
  required MascotStage stage,
  CharacterPack pack = CharacterPack.standard,
  String? scoreText,
  Future<void> Function(Uint8List png)? onShare,
  DateTime? now,
  KitStrings? strings,
}) async {
  // ダイアログは Navigator の上に積まれるので、呼び出し側の context から文言を取っておく。
  final s = strings ?? KitStrings.of(context);
  final choice = await showDialog<PassReportResult>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.passAskTitle(cert.label)),
      content: Text(s.passAskBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(PassReportResult.notYet),
          child: Text(s.passNotYet),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(PassReportResult.notPassed),
          child: Text(s.passNotPassed),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(PassReportResult.passed),
          child: Text(s.passPassed),
        ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return choice;

  if (choice == PassReportResult.notPassed) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.passEncourageTitle),
        content: Text(s.passEncourageBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.close),
          ),
        ],
      ),
    );
    return choice;
  }
  if (choice == PassReportResult.notYet) return choice;

  // 合格
  final grant = await ref
      .read(coinProvider.notifier)
      .grant(CoinEvent.passReport(cert.id));
  await ref.read(outfitProvider.notifier).reportPassed(cert);
  final memorial = OutfitCatalog.byId(
    OutfitCatalog.idOf(cert, OutfitKind.passMemorial),
  );
  if (!context.mounted) return choice;
  await showDialog<void>(
    context: context,
    builder: (ctx) => _PassShareDialog(
      cert: cert,
      stage: stage,
      pack: pack,
      outfit: memorial,
      coinAmount: grant?.amount ?? 0,
      scoreText: scoreText,
      date: now ?? DateTime.now(),
      onShare: onShare,
      strings: s,
    ),
  );
  return choice;
}

class _PassShareDialog extends StatefulWidget {
  const _PassShareDialog({
    required this.cert,
    required this.stage,
    required this.pack,
    required this.outfit,
    required this.coinAmount,
    required this.date,
    required this.strings,
    this.scoreText,
    this.onShare,
  });

  final UkalabCert cert;
  final MascotStage stage;
  final CharacterPack pack;
  final Outfit? outfit;
  final int coinAmount;
  final String? scoreText;
  final DateTime date;
  final KitStrings strings;
  final Future<void> Function(Uint8List png)? onShare;

  @override
  State<_PassShareDialog> createState() => _PassShareDialogState();
}

class _PassShareDialogState extends State<_PassShareDialog> {
  final _key = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final png = await captureShareCard(_key);
      await widget.onShare!(png);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.strings;
    return AlertDialog(
      title: Text(s.passCongrats),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _key,
              child: PassShareCard(
                pack: widget.pack,
                strings: s,
                data: ShareCardData(
                  certLabel: widget.cert.label,
                  date: widget.date,
                  packName: widget.pack.name,
                  stage: widget.stage,
                  outfit: widget.outfit,
                  scoreText: widget.scoreText,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.coinAmount > 0)
              Text(
                s.passCoin(widget.coinAmount),
                style: theme.textTheme.titleSmall,
              ),
            if (widget.outfit != null)
              Text(
                s.passOutfit(widget.outfit!.name),
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 4),
            Text(s.passPrivacy, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      actions: [
        if (widget.onShare != null)
          OutlinedButton(
            onPressed: _sharing ? null : _share,
            child: Text(s.passShare),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.close),
        ),
      ],
    );
  }
}
