import 'package:app_common_kit/app_common_kit.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../mascot/mascot_models.dart';
import '../mascot/mascot_widget.dart';
import 'outfit_models.dart';

/// 「推しと合格」共有カードの内容。**個人情報を入れる欄は作らない**
/// （名前・メール・ユーザーIDなし）。推し・衣装・資格名・日付だけ。点数は任意。
class ShareCardData {
  const ShareCardData({
    required this.certLabel,
    required this.date,
    required this.packName,
    required this.stage,
    this.outfit,
    this.scoreText,
    this.message,
  });

  final String certLabel;
  final DateTime date;
  final String packName;
  final MascotStage stage;
  final Outfit? outfit;

  /// 点数（任意。例: 「845点」）。出さないなら null。
  final String? scoreText;

  /// 見出しの一言。null なら [KitStrings] の既定（合格しました！）。
  final String? message;

  /// 日付（日本語表記）。言語に合わせるなら [KitStrings.shareDate] を使う。
  String get dateText => '${date.year}年${date.month}月${date.day}日';
}

/// 共有カード。幅いっぱいに広がる 4:5 の縦長。画像化は [captureShareCard] で行う。
class PassShareCard extends StatelessWidget {
  const PassShareCard({super.key, required this.data, this.pack = CharacterPack.standard, this.strings});

  final ShareCardData data;
  final CharacterPack pack;

  /// null なら最も近い `KitStringsScope`（無ければ日本語）。ダイアログ内では呼び出し側の文言を渡す。
  final KitStrings? strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = strings ?? KitStrings.of(context);
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: scheme.primary, width: 4),
        ),
        padding: const EdgeInsets.all(24),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.shareCardBrand, style: theme.textTheme.labelMedium),
                const SizedBox(height: 8),
                Text(data.certLabel, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(data.message ?? s.shareCardPassed, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                MascotWidget(
                  pack: pack,
                  stage: data.stage,
                  expression: MascotExpression.joy,
                  outfit: data.outfit,
                  size: 180,
                  animate: false,
                ),
                const SizedBox(height: 16),
                if (data.scoreText != null) Text(data.scoreText!, style: theme.textTheme.titleMedium),
                Text(s.shareDate(data.date), style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [boundaryKey] を付けた RepaintBoundary の内容を PNG にする。
Future<Uint8List> captureShareCard(GlobalKey boundaryKey, {double pixelRatio = 3}) async {
  final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}
