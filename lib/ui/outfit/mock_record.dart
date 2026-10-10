import 'package:app_common_kit/app_common_kit.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mascot/mascot_models.dart';
import '../theme/ukalab_palette.dart';
import 'outfit_models.dart';
import 'outfit_provider.dart';
import 'share_card.dart';

/// 模擬試験で合格点を超えたときの「学習の記録カード」を見せる。
///
/// 本番の合格報告（[showPassReportDialog]）とは別物で、**コインも衣装も付けない**
/// （模擬試験のコインは結果画面で付与済み）。カードの文言も「本番の合格」と
/// 取り違えないようにしてある。[onShare] を渡すと共有ボタンが出る。
/// 個人情報は入らない（推し・衣装・資格名・日付・点数のみ）。
Future<void> showMockRecordDialog(
  BuildContext context,
  WidgetRef ref, {
  required UkalabCert cert,
  required MascotStage stage,
  CharacterPack pack = CharacterPack.standard,
  String? scoreText,
  Future<void> Function(Uint8List png)? onShare,
  DateTime? now,
  KitStrings? strings,
}) {
  // ダイアログは Navigator の上に積まれるので、呼び出し側の context から文言を取っておく。
  final s = strings ?? KitStrings.of(context);
  Outfit? outfit;
  try {
    outfit = ref.read(equippedOutfitProvider);
  } catch (_) {}
  return showDialog<void>(
    context: context,
    builder: (ctx) => _MockRecordDialog(
      data: ShareCardData(
        certLabel: s.mockRecordCert(cert.label),
        date: now ?? DateTime.now(),
        packName: pack.name,
        stage: stage,
        outfit: outfit,
        scoreText: scoreText,
        message: s.mockRecordMessage,
      ),
      pack: pack,
      onShare: onShare,
      strings: s,
    ),
  );
}

class _MockRecordDialog extends StatefulWidget {
  const _MockRecordDialog({required this.data, required this.pack, required this.strings, this.onShare});

  final KitStrings strings;
  final ShareCardData data;
  final CharacterPack pack;
  final Future<void> Function(Uint8List png)? onShare;

  @override
  State<_MockRecordDialog> createState() => _MockRecordDialogState();
}

class _MockRecordDialogState extends State<_MockRecordDialog> {
  final _key = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await widget.onShare!(await captureShareCard(_key));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.strings;
    return AlertDialog(
      title: Text(s.mockRecordTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _key,
              child: PassShareCard(data: widget.data, pack: widget.pack, strings: s),
            ),
            const SizedBox(height: 12),
            Text(s.mockRecordNote, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      actions: [
        if (widget.onShare != null)
          OutlinedButton(
            onPressed: _sharing ? null : _share,
            child: Text(s.passShare),
          ),
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.close)),
      ],
    );
  }
}
