import 'package:app_common_kit/app_common_kit.dart' show StartupSplash, OrgBrandingFooter;
import 'package:flutter/material.dart';

import 'theme/ukalab_palette.dart';

/// うかラボ共通の起動画面。
///
/// 見た目は app_common_kit の `StartupSplash`（中央に進行表示、下部に組織ロゴ）と同等で、
/// 中央のアイコンだけ角丸クリップをしない（透過の foreground 画像を渡す前提）。
/// 端末側の起動画面を「背景色だけ」にして [backgroundColor] を同じ色にすると、
/// アイコンと組織ロゴが一枚の画面として見える。
///
/// 背景色は直接渡すか、[UkalabStartupSplash.cert] で資格色（[UkalabCert]）から導出する。
class UkalabStartupSplash extends StatelessWidget {
  const UkalabStartupSplash({
    super.key,
    required this.backgroundColor,
    required this.iconAsset,
    this.iconPackage,
    this.iconSize = 160,
    this.showProgress = true,
    this.footer = const OrgBrandingFooter(),
  }) : cert = null;

  /// 背景色を資格色から導出する（ライト: [UkalabCert.light]、ダーク: [UkalabCert.dark]）。
  const UkalabStartupSplash.cert({
    super.key,
    required UkalabCert this.cert,
    required this.iconAsset,
    this.iconPackage,
    this.iconSize = 160,
    this.showProgress = true,
    this.footer = const OrgBrandingFooter(),
  }) : backgroundColor = null;

  /// 背景色（[UkalabStartupSplash.cert] のときは null で、資格色から導出する）。
  final Color? backgroundColor;

  /// 背景色を導出する資格。
  final UkalabCert? cert;

  /// 透過の foreground 画像のアセットパス。角丸クリップはしない。
  final String iconAsset;

  /// [iconAsset] があるパッケージ名。null ならアプリ自身。
  final String? iconPackage;

  /// アイコンの一辺（既定 160）。
  final double iconSize;

  /// アイコンの下に進行表示を出すか。
  final bool showProgress;

  /// 下部の組織ロゴ。既定は kit 同梱のロゴ。組織ロゴを出さないときは `SizedBox.shrink()`。
  final Widget footer;

  /// 実際に使う背景色。
  Color resolveBackground(Brightness brightness) {
    final c = cert;
    if (c == null) return backgroundColor!;
    return brightness == Brightness.dark ? c.dark : c.light;
  }

  @override
  Widget build(BuildContext context) {
    final bg = resolveBackground(Theme.of(context).brightness);
    return StartupSplash(
      backgroundColor: bg,
      footer: footer,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            iconAsset,
            package: iconPackage,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
            // 画像が読めなくても起動画面は止めない（同じ大きさの空白で代える）。
            errorBuilder: (_, __, ___) => SizedBox(width: iconSize, height: iconSize),
          ),
          if (showProgress) ...[
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ],
      ),
    );
  }
}
