import 'package:flutter/painting.dart';

import '../../oshi/oshi_gift_engine.dart';

export '../../oshi/oshi_gift_engine.dart' show OshiGiftKind, OshiGiftCondition, OshiGiftProgress;

/// アプリが渡すプレゼント定義。[image] が無ければコードで描く（後で画像に差し替え可能）。
class OshiGift extends OshiGiftSpec {
  const OshiGift({
    required super.id,
    required super.kind,
    required super.condition,
    required super.name,
    this.image,
  });

  final ImageProvider? image;
}
