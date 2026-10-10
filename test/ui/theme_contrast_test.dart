import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 共通デザイン仕様 v0.4 §2 のコントラスト検査。AA（文字 4.5:1）未満は失敗。
void main() {
  const aaText = 4.5;
  // 文字ではなく図形（アイコン・枠）として使う色の基準（WCAG 1.4.11）
  const aaGraphic = 3.0;

  for (final b in Brightness.values) {
    for (final field in UkalabField.values) {
      group('${b.name} / ${field.name}', () {
        final p = UkalabPalette.resolve(field: field, brightness: b);

        test('本文・補助の文字は背景・面の上で AA', () {
          for (final bg in [p.background, p.surface]) {
            expect(contrastRatio(p.textPrimary, bg), greaterThanOrEqualTo(aaText));
            expect(contrastRatio(p.textSecondary, bg), greaterThanOrEqualTo(aaText));
          }
        });

        test('ブランド色・error・warning は背景・面の上で AA', () {
          for (final bg in [p.background, p.surface]) {
            expect(contrastRatio(p.brand, bg), greaterThanOrEqualTo(aaText), reason: 'brand');
            expect(contrastRatio(p.error, bg), greaterThanOrEqualTo(aaText), reason: 'error');
            expect(contrastRatio(p.warning, bg), greaterThanOrEqualTo(aaText), reason: 'warning');
          }
        });

        test('success は✓アイコン（図形）として 3:1 以上。文字に使うならライトは AA 未満', () {
          for (final bg in [p.background, p.surface]) {
            expect(contrastRatio(p.success, bg), greaterThanOrEqualTo(aaGraphic));
          }
        });

        test('分野色の塗りの上の文字が AA', () {
          expect(contrastRatio(p.fill, p.onFill), greaterThanOrEqualTo(aaText));
        });

        test('コンテナ（薄い面）の上の文字が AA（評価指標ラボのチップが読めない不具合の再発防止）', () {
          expect(contrastRatio(p.primaryContainer, p.onPrimaryContainer), greaterThanOrEqualTo(aaText),
              reason: 'primaryContainer');
          expect(contrastRatio(p.secondaryContainer, p.onSecondaryContainer), greaterThanOrEqualTo(aaText),
              reason: 'secondaryContainer');
        });

        test('ThemeData の colorScheme にコンテナ色が反映される（Flutter の補完に任せない）', () {
          final scheme = UkalabTheme.build(field: field, brightness: b).colorScheme;
          expect(scheme.primaryContainer, p.primaryContainer);
          expect(scheme.onPrimaryContainer, p.onPrimaryContainer);
          expect(scheme.secondaryContainer, p.secondaryContainer);
          expect(scheme.onSecondaryContainer, p.onSecondaryContainer);
        });
      });
    }
  }

  group('資格別テーマ色（決定77）', () {
    for (final cert in UkalabCert.values) {
      for (final b in Brightness.values) {
        test('${cert.label} / ${b.name}: 塗りの上の文字が AA', () {
          final p = UkalabPalette.resolve(field: cert.field, cert: cert, brightness: b);
          expect(contrastRatio(p.fill, p.onFill), greaterThanOrEqualTo(aaText));
        });

        test('${cert.label} / ${b.name}: コンテナの上の文字が AA', () {
          final p = UkalabPalette.resolve(field: cert.field, cert: cert, brightness: b);
          expect(contrastRatio(p.primaryContainer, p.onPrimaryContainer), greaterThanOrEqualTo(aaText));
          expect(contrastRatio(p.secondaryContainer, p.onSecondaryContainer), greaterThanOrEqualTo(aaText));
        });
      }
    }

    test('設計書の比と一致する（G検定ライト 5.80、ダーク 6.35）', () {
      final l = UkalabPalette.resolve(
          field: UkalabField.ai, cert: UkalabCert.gKentei, brightness: Brightness.light);
      final d = UkalabPalette.resolve(
          field: UkalabField.ai, cert: UkalabCert.gKentei, brightness: Brightness.dark);
      expect(contrastRatio(l.fill, l.onFill), closeTo(5.80, 0.02));
      expect(contrastRatio(d.fill, d.onFill), closeTo(6.35, 0.02));
    });

    test('17資格・id が一意', () {
      expect(UkalabCert.values, hasLength(17));
      expect(UkalabCert.values.map((c) => c.id).toSet(), hasLength(17));
      expect(UkalabCert.fromId('g_kentei'), UkalabCert.gKentei);
      expect(UkalabCert.fromId('nope'), isNull);
    });
  });

  test('会計・経営のライトは warning を #8A6100 に差し替える', () {
    final biz = UkalabPalette.resolve(field: UkalabField.biz, brightness: Brightness.light);
    final it = UkalabPalette.resolve(field: UkalabField.it, brightness: Brightness.light);
    expect(biz.warning, const Color(0xFF8A6100));
    expect(it.warning, const Color(0xFFA35600));
  });
}
