/// 「解いた割合」の集計（純 Dart）。頑張りの量を表すもので、正誤は問わない。
///
/// 色の付け方は `package:ukalab_core/ui.dart` の `solveCoverageFill` /
/// `SolveCoverageBadge`（資格色 [UkalabCert] を使う）。
library;

/// 解いた割合の段階。
///
/// 境界: 0 → none / (0, 1/3] → low / (1/3, 2/3] → mid / (2/3, 1) → high / 100% → complete。
enum SolveLevel { none, low, mid, high, complete }

/// 解いた問題数と総数。
class SolveCoverage {
  const SolveCoverage({required this.solved, required this.total});

  static const empty = SolveCoverage(solved: 0, total: 0);

  final int solved;
  final int total;

  /// 0.0〜1.0。総数 0 のときは 0。solved > total のときは 1 に丸める。
  double get ratio => solveRatio(solved, total);

  /// 0〜100 の整数（切り捨て。99.9% は 99、100% になるのは全問解いたときだけ）。
  int get percent => _clamped.$2 == 0 ? 0 : _clamped.$1 * 100 ~/ _clamped.$2;

  SolveLevel get level => solveLevel(solved, total);

  /// 例: 「12/40問」
  String get label => '$solved/$total問';

  /// 読み上げ用。例: 「運転免許、40問中12問解答済み、30パーセント」
  String semanticsLabel(String name) => '$name、$total問中$solved問解答済み、$percentパーセント';

  (int, int) get _clamped {
    if (total <= 0) return (0, 0);
    final s = solved < 0 ? 0 : (solved > total ? total : solved);
    return (s, total);
  }

  @override
  bool operator ==(Object other) =>
      other is SolveCoverage && other.solved == solved && other.total == total;

  @override
  int get hashCode => Object.hash(solved, total);

  @override
  String toString() => 'SolveCoverage($solved/$total)';
}

/// 解答済み問題数 / 問題数。範囲外は 0〜1 に丸める。総数 0 以下は 0。
double solveRatio(int solved, int total) {
  if (total <= 0 || solved <= 0) return 0;
  if (solved >= total) return 1;
  return solved / total;
}

/// 段階を決める。境界は [SolveLevel] の説明のとおり。
SolveLevel solveLevel(int solved, int total) {
  final r = solveRatio(solved, total);
  if (r <= 0) return SolveLevel.none;
  if (r >= 1) return SolveLevel.complete;
  if (r <= 1 / 3) return SolveLevel.low;
  if (r <= 2 / 3) return SolveLevel.mid;
  return SolveLevel.high;
}

/// 問題 ID 一覧と解答済み ID 集合から集計する。重複 ID は 1 問として数え、
/// [solvedIds] のうち [questionIds] に無いものは無視する（solved が total を超えない）。
SolveCoverage aggregateCoverage(Iterable<String> questionIds, Set<String> solvedIds) {
  final ids = questionIds.toSet();
  return SolveCoverage(solved: ids.where(solvedIds.contains).length, total: ids.length);
}
