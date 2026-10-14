import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../mascot/mascot_models.dart';
import '../mascot/mascot_widget.dart';
import '../ukalab_strings.dart';
import 'outfit_models.dart';
import 'share_card.dart';

/// メダルの種類。
enum OshiMedalKind { achievement, streak, mockPass }

/// メダルを置く隔。
enum OshiMedalCorner { topLeft, topRight, bottomLeft, bottomRight }

/// 推しの画像に置くメダル。[image] が無ければコードで描く（後で画像アセットに差し替える前提）。
/// **個人情報を入れる欄は無い**（id・ラベル・段階・種類のみ）。
class OshiMedal {
  const OshiMedal({
    required this.id,
    required this.label,
    this.tier = 1,
    this.kind = OshiMedalKind.achievement,
    this.image,
  });

  final String id;
  final String label;

  /// 段階（1=銅、2=銀、3以上=金）。
  final int tier;
  final OshiMedalKind kind;
  final ImageProvider? image;
}

Color _tierColor(int tier) => switch (tier) {
  <= 1 => const Color(0xFFB87333),
  2 => const Color(0xFF9EA7B0),
  _ => const Color(0xFFE0B100),
};

IconData _kindIcon(OshiMedalKind kind) => switch (kind) {
  OshiMedalKind.achievement => Icons.emoji_events,
  OshiMedalKind.streak => Icons.local_fire_department,
  OshiMedalKind.mockPass => Icons.fact_check,
};

/// メダル 1 つ。画像があれば画像、無ければ リボン+円+アイコンを描く。
class OshiMedalView extends StatelessWidget {
  const OshiMedalView({super.key, required this.medal, this.size = 72});

  final OshiMedal medal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final img = medal.image;
    final drawn = _DrawnMedal(medal: medal, size: size);
    return Semantics(
      label: medal.label,
      child: SizedBox(
        width: size,
        height: size,
        child: img == null
            ? drawn
            : Image(
                image: img,
                width: size,
                height: size,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => drawn,
              ),
      ),
    );
  }
}

class _DrawnMedal extends StatelessWidget {
  const _DrawnMedal({required this.medal, required this.size});

  final OshiMedal medal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(medal.tier);
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(size: Size(size, size), painter: _MedalPainter(color)),
        Positioned(
          top: size * 0.36,
          child: Icon(_kindIcon(medal.kind), size: size * 0.34, color: Colors.white),
        ),
      ],
    );
  }
}

class _MedalPainter extends CustomPainter {
  _MedalPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final ribbon = Paint()..color = const Color(0xFFD64545);
    // リボン（V 字の 2 本）
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.25, 0)
        ..lineTo(w * 0.5, 0)
        ..lineTo(w * 0.62, w * 0.5)
        ..lineTo(w * 0.42, w * 0.5)
        ..close(),
      ribbon,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.75, 0)
        ..lineTo(w * 0.5, 0)
        ..lineTo(w * 0.38, w * 0.5)
        ..lineTo(w * 0.58, w * 0.5)
        ..close(),
      Paint()..color = const Color(0xFFB03030),
    );
    final c = Offset(w * 0.5, w * 0.64);
    final r = w * 0.34;
    canvas.drawCircle(c, r, Paint()..color = color);
    canvas.drawCircle(
      c,
      r * 0.8,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03,
    );
  }

  @override
  bool shouldRepaint(_MedalPainter old) => old.color != color;
}

/// 推しの画像の隔にメダルを置いた共有カード（4:5）。画像化は [captureShareCard]。
/// 個人情報の欄は無い。日付・ブランド・「自己記録・非公式」の注記だけ。
class OshiMedalShareCard extends StatelessWidget {
  const OshiMedalShareCard({
    super.key,
    required this.medal,
    required this.date,
    this.pack = CharacterPack.standard,
    this.stage = MascotStage.lv1,
    this.outfit,
    this.corner = OshiMedalCorner.bottomRight,
    this.strings,
  });

  final OshiMedal medal;
  final DateTime date;
  final CharacterPack pack;
  final MascotStage stage;
  final Outfit? outfit;
  final OshiMedalCorner corner;
  final UkalabStrings? strings;

  static const _medalSize = 84.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = strings ?? UkalabStrings.of(context);
    final left = corner == OshiMedalCorner.topLeft || corner == OshiMedalCorner.bottomLeft;
    final top = corner == OshiMedalCorner.topLeft || corner == OshiMedalCorner.topRight;
    // 共有する「画像」なので、端末の文字サイズ設定で崩れないよう文字倍率は固定する
    //（拡大すると 4:5 の枠からはみ出す。画面側の説明文は拡大のまま）。
    return MediaQuery.withNoTextScaling(
      child: AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: scheme.primary, width: 4),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(s.shareCardBrand, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Expanded(
              child: Stack(
                key: const ValueKey('oshiMedalStack'),
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: MascotWidget(
                        pack: pack,
                        stage: stage,
                        expression: MascotExpression.joy,
                        outfit: outfit,
                        size: 240,
                        animate: false,
                      ),
                    ),
                  ),
                  Positioned(
                    key: const ValueKey('oshiMedalPositioned'),
                    left: left ? 0 : null,
                    right: left ? null : 0,
                    top: top ? 0 : null,
                    bottom: top ? null : 0,
                    child: OshiMedalView(medal: medal, size: _medalSize),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              medal.label,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(s.shareDate(date), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 2),
            Text(s.medalDisclaimer, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
    );
  }
}

/// メダルカードを見せ、[onShare]/[onSave] で PNG（pixelRatio 3）を渡す。null のボタンは出さない。
/// ネイティブのプラグインは持たない（共有・保存の実処理は呼び出し側）。個人情報は入らない。
Future<void> showOshiMedalDialog(
  BuildContext context, {
  required OshiMedal medal,
  CharacterPack pack = CharacterPack.standard,
  MascotStage stage = MascotStage.lv1,
  Outfit? outfit,
  OshiMedalCorner corner = OshiMedalCorner.bottomRight,
  DateTime? now,
  Future<void> Function(Uint8List png)? onShare,
  Future<void> Function(Uint8List png)? onSave,
  UkalabStrings? strings,
}) {
  final s = strings ?? UkalabStrings.of(context);
  final date = now ?? DateTime.now();
  return showDialog<void>(
    context: context,
    builder: (ctx) => _OshiMedalDialog(
      medal: medal,
      pack: pack,
      stage: stage,
      outfit: outfit,
      corner: corner,
      date: date,
      onShare: onShare,
      onSave: onSave,
      strings: s,
    ),
  );
}

class _OshiMedalDialog extends StatefulWidget {
  const _OshiMedalDialog({
    required this.medal,
    required this.pack,
    required this.stage,
    required this.outfit,
    required this.corner,
    required this.date,
    required this.strings,
    this.onShare,
    this.onSave,
  });

  final OshiMedal medal;
  final CharacterPack pack;
  final MascotStage stage;
  final Outfit? outfit;
  final OshiMedalCorner corner;
  final DateTime date;
  final UkalabStrings strings;
  final Future<void> Function(Uint8List png)? onShare;
  final Future<void> Function(Uint8List png)? onSave;

  @override
  State<_OshiMedalDialog> createState() => _OshiMedalDialogState();
}

class _OshiMedalDialogState extends State<_OshiMedalDialog> {
  final _key = GlobalKey();
  bool _busy = false;
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      _precache();
    }
  }

  Future<void> _precache() async {
    final img = widget.medal.image;
    if (img == null) return;
    try {
      await precacheImage(img, context, onError: (_, __) {});
    } catch (_) {}
  }

  Future<void> _run(Future<void> Function(Uint8List png) action) async {
    setState(() => _busy = true);
    try {
      await _precache(); // 画像化の前に読み込み済みにする
      if (!mounted) return;
      await action(await captureShareCard(_key));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.strings;
    return AlertDialog(
      // 文字を大きくした小さい画面でも、題名・ボタンまで含めてスクロールできるようにする
      scrollable: true,
      title: Text(s.medalTitle),
      content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _key,
              child: OshiMedalShareCard(
                medal: widget.medal,
                date: widget.date,
                pack: widget.pack,
                stage: widget.stage,
                outfit: widget.outfit,
                corner: widget.corner,
                strings: s,
              ),
            ),
            const SizedBox(height: 12),
            Text(s.medalNote, style: theme.textTheme.bodySmall),
          ],
      ),
      actions: [
        if (widget.onSave != null)
          OutlinedButton(
            onPressed: _busy ? null : () => _run(widget.onSave!),
            child: Text(s.medalSave),
          ),
        if (widget.onShare != null)
          OutlinedButton(
            onPressed: _busy ? null : () => _run(widget.onShare!),
            child: Text(s.passShare),
          ),
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.close)),
      ],
    );
  }
}
