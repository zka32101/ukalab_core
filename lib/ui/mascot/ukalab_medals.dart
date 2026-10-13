import 'package:flutter/widgets.dart';

import '../theme/ukalab_palette.dart';

/// 資格ごとの合格メダル画像（`assets/mascot/medals/<certId>_medal.webp`）。
///
/// [OshiMedal.image] にそのまま渡せる。
/// ```dart
/// OshiMedal(id: 'pass_g_kentei', label: 'G検定 合格', image: UkalabMedals.image('g_kentei'))
/// ```
class UkalabMedals {
  const UkalabMedals._();

  static const String package = 'ukalab_core';

  /// メダル画像のある資格ID（[UkalabCert] の全17資格）。
  static final Set<String> certIds = {for (final c in UkalabCert.values) c.id};

  /// アセットのパス（パッケージ内）。画像が無い資格は null。
  static String? assetPath(String certId) =>
      certIds.contains(certId) ? 'assets/mascot/medals/${certId}_medal.webp' : null;

  /// 資格 [certId] の合格メダル画像。画像が無い資格は null（[OshiMedalView] はコード描画に戻る）。
  static ImageProvider? image(String certId) {
    final p = assetPath(certId);
    return p == null ? null : AssetImage(p, package: package);
  }
}
