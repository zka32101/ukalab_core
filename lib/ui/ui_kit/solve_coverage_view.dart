import 'package:flutter/material.dart';

import '../../progress/solve_coverage.dart';
import '../theme/ukalab_palette.dart';

/// 段階ごとの背景の不透明度（資格色を面の色に重ねる）。bike の表示に合わせた値。
const Map<SolveLevel, double> kSolveCoverageAlpha = {
  SolveLevel.none: 0,
  SolveLevel.low: 0.18,
  SolveLevel.mid: 0.38,
  SolveLevel.high: 0.60,
  SolveLevel.complete: 0.85,
};

/// 資格色（[cert] の light / dark）を [surface] に重ねた背景色。0% は surface のまま。
Color solveCoverageFill(UkalabCert cert, Brightness brightness, SolveLevel level, Color surface) {
  final base = brightness == Brightness.dark ? cert.dark : cert.light;
  return Color.alphaBlend(base.withValues(alpha: kSolveCoverageAlpha[level]!), surface);
}

/// [fill] の上で 4.5:1 以上になる文字色。[onSurface]、[surface] の順に試し、
/// どちらも満たさなければ黒か白（黒白のどちらかは常に 4.5:1 以上）。
Color solveCoverageForeground(
  Color fill, {
  required Color onSurface,
  required Color surface,
}) {
  for (final c in [onSurface, surface]) {
    if (contrastRatio(c, fill) >= 4.5) return c;
  }
  return contrastRatio(Colors.black, fill) >= contrastRatio(Colors.white, fill)
      ? Colors.black
      : Colors.white;
}

/// 「12/40問」を、解いた割合の濃さで塗ったバッジ。色だけに頼らず、数字を必ず表示する。
class SolveCoverageBadge extends StatelessWidget {
  const SolveCoverageBadge({
    super.key,
    required this.coverage,
    required this.cert,
    this.name,
    this.style,
  });

  final SolveCoverage coverage;
  final UkalabCert cert;

  /// 読み上げの見出し（例: 「標識」）。省略時は [cert] の名前。
  final String? name;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = theme.brightness;
    final surface = theme.colorScheme.surface;
    final fill = solveCoverageFill(cert, b, coverage.level, surface);
    final fg = solveCoverageForeground(fill, onSurface: theme.colorScheme.onSurface, surface: surface);
    final border = b == Brightness.dark ? cert.dark : cert.light;
    return Semantics(
      label: coverage.semanticsLabel(name ?? cert.label),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border.withValues(alpha: 0.6)),
        ),
        child: Text(
          coverage.label,
          style: (style ?? theme.textTheme.labelMedium)?.copyWith(color: fg),
        ),
      ),
    );
  }
}
