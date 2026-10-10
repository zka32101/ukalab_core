import 'package:flutter/material.dart';

/// うかラボ共通デザイン仕様 v0.4 §2 のカラートークン。
///
/// アプリ側は色を直書きせず、[UkalabTheme] を通して使う。
/// 値は設計書どおり。コントラストは test/theme_contrast_test.dart で検査する。

/// 分野（5区切り）。
enum UkalabField {
  /// IT・データ
  it,

  /// AI
  ai,

  /// 会計・経営
  biz,

  /// 技術・安全
  tech,

  /// 言語・教育
  lang,
}

/// 資格別テーマ色（決定77）。
enum UkalabCert {
  gKentei('g_kentei', 'G検定', UkalabField.ai, Color(0xFF6D4AD8), Color(0xFFA08AE6)),
  genAiPassport('gen_ai_passport', '生成AIパスポート', UkalabField.ai, Color(0xFF9A44CC), Color(0xFFC28FE0)),
  genAiPractitioner('gen_ai_practitioner', '生成AI導入実務者検定', UkalabField.ai, Color(0xFF3D50D5), Color(0xFF8A95E6)),
  dataManagement('data_management', 'データマネジメント試験', UkalabField.it, Color(0xFF1A6FA8), Color(0xFF83C2EC)),
  infoSecurity('info_security', '情報セキュリティマネジメント', UkalabField.it, Color(0xFF236DC3), Color(0xFF86B4E9)),
  dsKentei('ds_kentei', 'DS検定', UkalabField.it, Color(0xFF16799B), Color(0xFF82D2ED)),
  itPassport('it_passport', 'ITパスポート', UkalabField.it, Color(0xFF2B5FD9), Color(0xFF86A4E9)),
  fe('fe', '基本情報技術者', UkalabField.it, Color(0xFF242EC7), Color(0xFF868CE9)),
  boki3('boki3', '簿記3級', UkalabField.biz, Color(0xFFA35600), Color(0xFFF4BB7B)),
  smeConsultant('sme_consultant', '中小企業診断士', UkalabField.biz, Color(0xFF8F2F00), Color(0xFFF4A37B)),
  smeMa('sme_ma', '中小M&Aアドバイザー', UkalabField.biz, Color(0xFF8A6A00), Color(0xFFF4D87B)),
  hazmat4('hazmat4', '危険物乙4', UkalabField.tech, Color(0xFFC23D16), Color(0xFFF0997F)),
  denken3('denken3', '電験三種', UkalabField.tech, Color(0xFFB23B26), Color(0xFFE69789)),
  drone('drone', 'ドローン国家資格', UkalabField.tech, Color(0xFFAB1319), Color(0xFFF17E83)),
  bikeLicense('bike_license', '運転免許（二輪）', UkalabField.tech, Color(0xFFB84A12), Color(0xFFF2A07A)),
  japaneseTeacher('japanese_teacher', '登録日本語教員', UkalabField.lang, Color(0xFFC2347A), Color(0xFFE18EB7)),
  kanjiKentei('kanji_kentei', '漢字検定', UkalabField.lang, Color(0xFFAE2A66), Color(0xFFEE8FB8));

  const UkalabCert(this.id, this.label, this.field, this.light, this.dark);

  final String id;
  final String label;
  final UkalabField field;

  /// ライトの塗り色（白文字）。
  final Color light;

  /// ダークの塗り色（#10151C 文字）。
  final Color dark;

  static UkalabCert? fromId(String id) {
    for (final c in values) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// 1つのテーマ（ライト or ダーク）の色一式。
class UkalabPalette {
  const UkalabPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.brand,
    required this.success,
    required this.error,
    required this.warning,
    required this.fill,
    required this.onFill,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
  });

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;

  /// ブランド色（#0B7370 / ダーク #4FD1CB）。
  final Color brand;
  final Color success;
  final Color error;
  final Color warning;

  /// 分野色または資格色（ボタン・バッジの塗り）。
  final Color fill;

  /// [fill] の上の文字色（ライト: 白、ダーク: #10151C）。
  final Color onFill;

  /// 分野色の薄い面（選択中の項目・強調カードの背景）。上の文字は [onPrimaryContainer]。
  /// 面は surface に分野色を重ねて作り、文字は textPrimary（どちらも AA を満たす）。
  final Color primaryContainer;
  final Color onPrimaryContainer;

  /// ブランド色の薄い面（チップ・タグの背景）。上の文字は [onSecondaryContainer]。
  final Color secondaryContainer;
  final Color onSecondaryContainer;

  /// ダークの塗り面の文字色（白は約2.4:1で成立しないため）。
  static const Color onFillDark = Color(0xFF10151C);

  static const Map<UkalabField, (Color, Color)> _fieldColors = {
    UkalabField.it: (Color(0xFF2B5FD9), Color(0xFF7FA4FF)),
    UkalabField.ai: (Color(0xFF6D4AD8), Color(0xFFA58BFF)),
    UkalabField.biz: (Color(0xFFA35600), Color(0xFFF0A04B)),
    UkalabField.tech: (Color(0xFFC23D16), Color(0xFFFF8A65)),
    UkalabField.lang: (Color(0xFFC2347A), Color(0xFFF07DB0)),
  };

  /// 分野（と、あれば資格）から色一式を作る。
  ///
  /// 会計・経営のライトは warning を #8A6100 に差し替える（分野色 #A35600 と近いため。
  /// 必ず⚠アイコン・文言を併記する）。
  factory UkalabPalette.resolve({
    required UkalabField field,
    UkalabCert? cert,
    required Brightness brightness,
  }) {
    final dark = brightness == Brightness.dark;
    final f = _fieldColors[field]!;
    final fill = cert != null ? (dark ? cert.dark : cert.light) : (dark ? f.$2 : f.$1);
    if (dark) {
      return UkalabPalette(
        brightness: brightness,
        background: const Color(0xFF121A24),
        surface: const Color(0xFF1B2633),
        textPrimary: const Color(0xFFE8EDF3),
        textSecondary: const Color(0xFF9AA7B6),
        brand: const Color(0xFF4FD1CB),
        success: const Color(0xFF5BD17F),
        error: const Color(0xFFFF8A7A),
        warning: const Color(0xFFF0A04B),
        fill: fill,
        onFill: onFillDark,
        primaryContainer: Color.alphaBlend(fill.withValues(alpha: 0.30), const Color(0xFF1B2633)),
        onPrimaryContainer: const Color(0xFFE8EDF3),
        secondaryContainer: Color.alphaBlend(
            const Color(0xFF4FD1CB).withValues(alpha: 0.28), const Color(0xFF1B2633)),
        onSecondaryContainer: const Color(0xFFE8EDF3),
      );
    }
    return UkalabPalette(
      brightness: brightness,
      background: const Color(0xFFF6F8FB),
      surface: const Color(0xFFFFFFFF),
      textPrimary: const Color(0xFF1B2430),
      textSecondary: const Color(0xFF5B6776),
      brand: const Color(0xFF0B7370),
      success: const Color(0xFF1E8E3E),
      error: const Color(0xFFC5362B),
      warning: field == UkalabField.biz ? const Color(0xFF8A6100) : const Color(0xFFA35600),
      fill: fill,
      onFill: const Color(0xFFFFFFFF),
      primaryContainer: Color.alphaBlend(fill.withValues(alpha: 0.14), const Color(0xFFFFFFFF)),
      onPrimaryContainer: const Color(0xFF1B2430),
      secondaryContainer: Color.alphaBlend(
          const Color(0xFF0B7370).withValues(alpha: 0.14), const Color(0xFFFFFFFF)),
      onSecondaryContainer: const Color(0xFF1B2430),
    );
  }
}

/// WCAG のコントラスト比。
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
