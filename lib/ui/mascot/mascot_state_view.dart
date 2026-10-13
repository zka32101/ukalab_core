import 'package:flutter/material.dart';

import 'mascot_models.dart';
import 'mascot_widget.dart';
import 'ukalab_characters.dart';

/// 推しの絵（ポーズ）。画像の無いキャラ（標準キャラ）はコード描画の [MascotWidget] に戻る。
class MascotPoseImage extends StatelessWidget {
  const MascotPoseImage({super.key, required this.pack, this.pose, this.state, this.size = 120})
    : assert(pose != null || state != null, 'pose か state のどちらかを指定する');

  final CharacterPack pack;
  final MascotPose? pose;
  final MascotState? state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final img = state != null
        ? UkalabCharacters.stateImage(pack.id, state!)
        : UkalabCharacters.poseImage(pack.id, pose!);
    final fallback = MascotWidget(pack: pack, size: size, animate: false);
    if (img == null) return fallback;
    return Image(
      image: img,
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

/// 空状態・エラー・読み込み中・ようこそ などの共通画面。推しの絵＋メッセージ＋任意のボタン。
class MascotStateView extends StatelessWidget {
  const MascotStateView({
    super.key,
    required this.pack,
    required this.state,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.imageSize = 140,
  });

  const MascotStateView.empty({
    Key? key,
    required CharacterPack pack,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) : this(
         key: key,
         pack: pack,
         state: MascotState.empty,
         message: message,
         actionLabel: actionLabel,
         onAction: onAction,
       );

  const MascotStateView.error({
    Key? key,
    required CharacterPack pack,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) : this(
         key: key,
         pack: pack,
         state: MascotState.error,
         message: message,
         actionLabel: actionLabel,
         onAction: onAction,
       );

  const MascotStateView.loading({Key? key, required CharacterPack pack, required String message})
    : this(key: key, pack: pack, state: MascotState.loading, message: message);

  const MascotStateView.welcome({
    Key? key,
    required CharacterPack pack,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) : this(
         key: key,
         pack: pack,
         state: MascotState.welcome,
         message: message,
         actionLabel: actionLabel,
         onAction: onAction,
       );

  final CharacterPack pack;
  final MascotState state;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MascotPoseImage(pack: pack, state: state, size: imageSize),
            const SizedBox(height: 16),
            Semantics(
              liveRegion: state == MascotState.loading || state == MascotState.error,
              child: Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            ),
            if (state == MascotState.loading) ...[
              const SizedBox(height: 16),
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
