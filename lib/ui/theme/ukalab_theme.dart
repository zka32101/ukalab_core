import 'package:flutter/material.dart';

import 'ukalab_palette.dart';

/// 分野（と資格）を渡すだけで ThemeData を作る。
///
/// ```dart
/// MaterialApp(
///   theme: UkalabTheme.light(field: UkalabField.ai, cert: UkalabCert.gKentei),
///   darkTheme: UkalabTheme.dark(field: UkalabField.ai, cert: UkalabCert.gKentei),
/// )
/// ```
///
/// 文字サイズ・角丸・タップ領域は共通デザイン仕様 v0.4 §3 のとおり。
class UkalabTheme {
  UkalabTheme._();

  static ThemeData light({required UkalabField field, UkalabCert? cert}) =>
      build(field: field, cert: cert, brightness: Brightness.light);

  static ThemeData dark({required UkalabField field, UkalabCert? cert}) =>
      build(field: field, cert: cert, brightness: Brightness.dark);

  static const double cardRadius = 16;
  static const double buttonRadius = 12;

  /// タップ領域の最小サイズ（pt）。
  static const double minTapTarget = 44;

  static ThemeData build({
    required UkalabField field,
    UkalabCert? cert,
    required Brightness brightness,
  }) {
    assert(cert == null || cert.field == field, '資格 ${cert.id} の分野は ${cert.field}');
    final p = UkalabPalette.resolve(field: field, cert: cert, brightness: brightness);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.fill,
      onPrimary: p.onFill,
      // コンテナ色（薄い面）。指定しないと Flutter が濃い色から補い、既定の灰色の文字が
      // 沈んで読めなくなる（評価指標ラボのチップ）。on*Container は必ず面とセットで決める。
      primaryContainer: p.primaryContainer,
      onPrimaryContainer: p.onPrimaryContainer,
      secondary: p.brand,
      onSecondary: brightness == Brightness.dark ? UkalabPalette.onFillDark : Colors.white,
      secondaryContainer: p.secondaryContainer,
      onSecondaryContainer: p.onSecondaryContainer,
      error: p.error,
      onError: brightness == Brightness.dark ? UkalabPalette.onFillDark : Colors.white,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
    );

    final text = _textTheme(p);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    );
    const minSize = Size(minTapTarget, minTapTarget);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: brightness == Brightness.dark ? 0 : 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          shape: buttonShape,
          backgroundColor: p.fill,
          foregroundColor: p.onFill,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: minSize,
          shape: buttonShape,
          backgroundColor: p.fill,
          foregroundColor: p.onFill,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minSize,
          shape: buttonShape,
          foregroundColor: p.textPrimary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: minSize,
          shape: buttonShape,
          foregroundColor: p.brand,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      dividerColor: p.textSecondary.withValues(alpha: 0.25),
    );
  }

  /// 本文16／解説17（行間1.6）／見出し20・24／注釈13（これ未満は使わない）。
  static TextTheme _textTheme(UkalabPalette p) {
    TextStyle s(double size, {FontWeight w = FontWeight.w400, double h = 1.5, Color? c}) =>
        TextStyle(fontSize: size, fontWeight: w, height: h, color: c ?? p.textPrimary);
    return TextTheme(
      headlineSmall: s(24, w: FontWeight.w700, h: 1.35),
      titleLarge: s(24, w: FontWeight.w700, h: 1.35),
      titleMedium: s(20, w: FontWeight.w700, h: 1.4),
      titleSmall: s(16, w: FontWeight.w700),
      bodyLarge: s(17, h: 1.6), // 解説
      bodyMedium: s(16),
      bodySmall: s(13, c: p.textSecondary), // 注釈
      labelLarge: s(16, w: FontWeight.w700),
      labelMedium: s(13, w: FontWeight.w600, c: p.textSecondary),
      labelSmall: s(13, c: p.textSecondary),
    );
  }
}
