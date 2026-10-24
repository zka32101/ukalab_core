import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/progress/solve_coverage.dart';
import 'package:ukalab_core/ui/theme/ukalab_palette.dart';
import 'package:ukalab_core/ui/ui_kit/solve_coverage_view.dart';

void main() {
  group('段階の境界', () {
    SolveLevel lv(int s, int t) => solveLevel(s, t);
    test('0 / (0,1/3] / (1/3,2/3] / (2/3,1) / 100%', () {
      expect(lv(0, 30), SolveLevel.none);
      expect(lv(1, 30), SolveLevel.low);
      expect(lv(10, 30), SolveLevel.low); // ちょうど 1/3
      expect(lv(11, 30), SolveLevel.mid);
      expect(lv(20, 30), SolveLevel.mid); // ちょうど 2/3
      expect(lv(21, 30), SolveLevel.high);
      expect(lv(99, 100), SolveLevel.high); // 99%
      expect(lv(100, 100), SolveLevel.complete);
    });
    test('solved > total は complete、total=0 や負は none', () {
      expect(lv(150, 100), SolveLevel.complete);
      expect(solveRatio(150, 100), 1);
      expect(lv(0, 0), SolveLevel.none);
      expect(lv(5, 0), SolveLevel.none);
      expect(lv(-3, 10), SolveLevel.none);
      expect(SolveCoverage.empty.ratio, 0);
    });
  });

  group('aggregateCoverage', () {
    test('重複 ID は 1 問、問題集合外の解答済み ID は無視', () {
      final c = aggregateCoverage(['a', 'b', 'b', 'c'], {'a', 'b', 'x', 'y'});
      expect(c, const SolveCoverage(solved: 2, total: 3));
    });
    test('問題 0 件は 0/0', () {
      expect(aggregateCoverage([], {'a'}), SolveCoverage.empty);
    });
  });

  group('文言', () {
    test('label / semanticsLabel / percent', () {
      const c = SolveCoverage(solved: 12, total: 40);
      expect(c.label, '12/40問');
      expect(c.percent, 30);
      expect(c.semanticsLabel('標識'), '標識、40問中12問解答済み、30パーセント');
    });
    test('percent は切り捨て（99.x% を 100 にしない）・浮動小数誤差なし', () {
      expect(const SolveCoverage(solved: 29, total: 100).percent, 29);
      expect(const SolveCoverage(solved: 999, total: 1000).percent, 99);
      expect(const SolveCoverage(solved: 5, total: 0).percent, 0);
      expect(const SolveCoverage(solved: 9, total: 3).percent, 100);
    });
  });

  group('色', () {
    const surfaces = {
      Brightness.light: Color(0xFFFFFFFF),
      Brightness.dark: Color(0xFF1B2633),
    };
    const onSurfaces = {
      Brightness.light: Color(0xFF1B2430),
      Brightness.dark: Color(0xFFE8EDF3),
    };

    test('0% は surface のまま、段階が上がるほど資格色に近づく', () {
      for (final cert in UkalabCert.values) {
        for (final b in Brightness.values) {
          final s = surfaces[b]!;
          expect(solveCoverageFill(cert, b, SolveLevel.none, s), s);
          final full = solveCoverageFill(cert, b, SolveLevel.complete, s);
          final base = b == Brightness.dark ? cert.dark : cert.light;
          expect(full, Color.alphaBlend(base.withValues(alpha: 0.85), s));
        }
      }
    });

    test('全資格 x light/dark x 全段で文字コントラスト >= 4.5', () {
      for (final cert in UkalabCert.values) {
        for (final b in Brightness.values) {
          for (final level in SolveLevel.values) {
            final s = surfaces[b]!;
            final fill = solveCoverageFill(cert, b, level, s);
            final fg = solveCoverageForeground(fill, onSurface: onSurfaces[b]!, surface: s);
            expect(contrastRatio(fg, fill), greaterThanOrEqualTo(4.5),
                reason: '${cert.id} $b $level');
          }
        }
      }
    });

    test('任意の背景でも黒白フォールバックで 4.5 以上', () {
      for (final fill in const [Color(0xFF777777), Color(0xFF808080), Color(0xFF00FF00)]) {
        final fg = solveCoverageForeground(fill,
            onSurface: const Color(0xFF888888), surface: const Color(0xFF8A8A8A));
        expect(contrastRatio(fg, fill), greaterThanOrEqualTo(4.5));
      }
    });
  });

  testWidgets('SolveCoverageBadge は数字を表示し、読み上げ文言を持つ', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SolveCoverageBadge(
          coverage: const SolveCoverage(solved: 12, total: 40),
          cert: UkalabCert.bikeLicense,
          name: '標識',
        ),
      ),
    ));
    expect(find.text('12/40問'), findsOneWidget);
    expect(find.bySemanticsLabel('標識、40問中12問解答済み、30パーセント'), findsOneWidget);
    handle.dispose();
  });
}
