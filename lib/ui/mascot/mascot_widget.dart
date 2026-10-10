import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../outfit/outfit_models.dart';
import 'mascot_models.dart';
import 'standard_character.dart';

/// ホームなどに置く「推し」。
///
/// 入力は成長段階・表情・試験日の装い。セリフ [line] があれば吹き出しで出す。
/// - 標準キャラはコード描画。画像パックは [CharacterPack.imageBuilder] の画像を使う
/// - [display] が hidden なら何も出さない。small なら小さく出す（設定）
/// - 「動きを減らす」設定（`MediaQuery.disableAnimations`）のときは、ゆれない
class MascotWidget extends StatefulWidget {
  const MascotWidget({
    super.key,
    this.pack = CharacterPack.standard,
    this.stage = MascotStage.lv1,
    this.expression = MascotExpression.normal,
    this.examPhase = ExamPhase.none,
    this.outfit,
    this.scene,
    this.display = MascotDisplay.normal,
    this.size = 160,
    this.animate = true,
    this.line,
    this.onTap,
  });

  final CharacterPack pack;
  final MascotStage stage;
  final MascotExpression expression;
  final ExamPhase examPhase;

  /// 着ている衣装。
  final Outfit? outfit;

  /// 場面別のポーズ。画像パックで、衣装を着ていないときだけ使う（衣装が優先）。
  final MascotScene? scene;
  final MascotDisplay display;
  final double size;

  /// false なら動かさない（共有カードの画像化など）。
  final bool animate;

  /// 吹き出しのセリフ。
  final String? line;

  /// タップされたとき（セリフを選んで [line] を更新するなど）。
  final VoidCallback? onTap;

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.display == MascotDisplay.hidden) return const SizedBox.shrink();

    final reduce = !widget.animate || (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    if (reduce) {
      if (_c.isAnimating) _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }

    final theme = Theme.of(context);
    final size = widget.display == MascotDisplay.small ? widget.size * 0.6 : widget.size;
    final accent = theme.colorScheme.primary;
    final outfit = widget.outfit;
    final scene = widget.scene;
    final image = (outfit == null
            ? null
            : widget.pack.outfitImageBuilder?.call(outfit, widget.stage)) ??
        (scene == null ? null : widget.pack.sceneImageBuilder?.call(scene, widget.stage)) ??
        widget.pack.imageBuilder?.call(widget.stage, widget.expression);

    Widget art;
    if (image != null) {
      art = Image(image: image, width: size, height: size, fit: BoxFit.contain);
    } else {
      art = AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.square(size),
          painter: StandardCharacterPainter(
            stage: widget.stage,
            expression: widget.expression,
            accent: accent,
            outline: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            examPhase: widget.examPhase,
            outfit: widget.outfit,
            bob: reduce ? 0 : math.sin(_c.value * math.pi * 2),
          ),
        ),
      );
    }

    final line = widget.line;
    return Semantics(
      button: widget.onTap != null,
      label: '${widget.pack.name} レベル${widget.stage.level}${widget.outfit == null ? '' : '、${widget.outfit!.name}'}${line == null ? '' : '。$line'}',
      excludeSemantics: true,
      child: ConstrainedBox(
        // タップ領域は 44pt 以上
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (line != null && line.isNotEmpty) _Bubble(text: line, maxWidth: math.max(size * 1.6, 200)),
              SizedBox(width: size, height: size, child: art),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.maxWidth});

  final String text;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: theme.textTheme.bodyMedium),
    );
  }
}
