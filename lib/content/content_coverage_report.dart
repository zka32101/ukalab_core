import '../config/exam_config.dart';
import '../question/question.dart';

/// 問題数の「量」の検査（純Dart・警告のみ）。
///
/// 既存の検査（[validateQuestions] など）は問題 1 件ずつの正しさを見るが、
/// 分野ごとの件数が試験の出題数に対して足りているかは見ない。ここでは
/// 分野別・難易度別・形式別の件数と、倍率（件数 ÷ 試験 1 回の出題枠）を集計し、
/// 少なすぎる分野・難易度の偏りを [CoverageWarning] として返す。
/// 警告は検証失敗（終了コード）には影響しない。

/// 倍率の既定の下限（件数が出題枠のこの倍未満なら警告）。
const double kDefaultMinCoverageMultiplier = 5.0;

/// 難易度の偏りの既定の上限（最大の難易度が全体のこの割合を超えたら警告）。
const double kDefaultMaxDifficultyShare = 0.7;

/// 警告の種別。
const String kCoverageLowMultiplier = 'coverage-low-multiplier';
const String kCoverageDifficultySkew = 'coverage-difficulty-skew';
const String kCoverageExperienceShort = 'coverage-experience-short';

/// 件数の警告（severity は常に警告。検証失敗にはしない）。
class CoverageWarning {
  const CoverageWarning({
    required this.code,
    required this.message,
    this.subjectId,
  });

  final String code;
  final String message;

  /// 分野に紐づく警告のときの subjectId。
  final String? subjectId;

  @override
  String toString() => '[warning:$code] $message';
}

/// 分野（subject）ごとの集計。
class SubjectCoverage {
  const SubjectCoverage({
    required this.subjectId,
    required this.name,
    required this.count,
    required this.slots,
    required this.multiplier,
    required this.byDifficulty,
    required this.byType,
  });

  final String subjectId;
  final String name;
  final int count;

  /// 試験 1 回でのこの分野の出題数。定義が無ければ null。
  final int? slots;

  /// 件数 ÷ [slots]。[slots] が null のときは null。
  final double? multiplier;

  /// 難易度 → 件数。
  final Map<int, int> byDifficulty;

  /// 形式（[QuestionType.name]）→ 件数。
  final Map<String, int> byType;
}

/// 集計結果。
class ContentCoverageReport {
  const ContentCoverageReport({
    required this.examId,
    required this.levelId,
    required this.total,
    required this.examQuestionCount,
    required this.totalMultiplier,
    required this.subjects,
    required this.byDifficulty,
    required this.byType,
    required this.warnings,
    required this.minMultiplier,
    required this.maxDifficultyShare,
  });

  final String examId;

  /// 出題枠の算出に使った級。無ければ null。
  final String? levelId;

  /// 集計対象の問題数（disabled を除く）。
  final int total;

  /// 試験 1 回の出題数。分かれば。
  final int? examQuestionCount;

  /// [total] ÷ [examQuestionCount]。
  final double? totalMultiplier;

  /// exam.subjects の順（order 昇順、同順位は定義順）。exam に無い分野の問題は末尾。
  final List<SubjectCoverage> subjects;
  final Map<int, int> byDifficulty;
  final Map<String, int> byType;
  final List<CoverageWarning> warnings;
  final double minMultiplier;
  final double maxDifficultyShare;
}

/// 件数が [slots] の [minMultiplier] 倍未満なら true（境界ちょうどは警告にしない）。
bool isBelowCoverageMultiplier(int count, int slots, double minMultiplier) =>
    slots > 0 && count < slots * minMultiplier;

/// 体験型（StoryScenario など）の本数が「無料枠 [free] + プレミアム [premium]」に
/// 満たなければ警告を返す。足りていれば null。件数だけを受けるので型に依存しない。
CoverageWarning? experienceCountWarning({
  required String label,
  required int actual,
  required int free,
  required int premium,
}) {
  final need = free + premium;
  if (actual >= need) return null;
  return CoverageWarning(
    code: kCoverageExperienceShort,
    message: '$label: $actual本（必要$need本 = 無料$free本 + プレミアム$premium本、${need - actual}本不足）',
  );
}

/// [questions] を [exam] に対して集計する。`disabled` の問題は数えない。
///
/// 出題枠は級の `subjectQuestionCounts`。[levelId] 指定があればその級、無ければ
/// `subjectQuestionCounts` を持つ最初の級（無ければ最初の級）を使う。
/// [levelId] 指定時は、その級向け（`levelId` が null か一致）の問題だけ数える。
/// 枠が定義されていない分野は倍率を出さず、倍率の警告も出さない。
ContentCoverageReport buildContentCoverageReport(
  ExamConfig exam,
  List<Question> questions, {
  String? levelId,
  double minMultiplier = kDefaultMinCoverageMultiplier,
  double maxDifficultyShare = kDefaultMaxDifficultyShare,
}) {
  LevelConfig? level;
  if (levelId != null) {
    for (final l in exam.levels) {
      if (l.levelId == levelId) level = l;
    }
  } else {
    for (final l in exam.levels) {
      if (l.subjectQuestionCounts != null) {
        level = l;
        break;
      }
    }
    if (level == null && exam.levels.isNotEmpty) level = exam.levels.first;
  }
  final slotMap = level?.subjectQuestionCounts ?? const <String, int>{};

  final active = [
    for (final q in questions)
      if (!q.disabled && (levelId == null || q.levelId == null || q.levelId == levelId)) q,
  ];

  final ordered = [...exam.subjects]..sort((a, b) => a.order.compareTo(b.order));
  final names = {for (final s in ordered) s.subjectId: s.name};
  final ids = [
    ...ordered.map((s) => s.subjectId),
    ...{
      for (final q in active)
        if (!names.containsKey(q.subjectId)) q.subjectId,
    },
  ];

  final subjects = <SubjectCoverage>[];
  for (final id in ids) {
    final qs = [for (final q in active) if (q.subjectId == id) q];
    final slots = slotMap[id];
    subjects.add(SubjectCoverage(
      subjectId: id,
      name: names[id] ?? id,
      count: qs.length,
      slots: slots,
      multiplier: slots == null || slots <= 0 ? null : qs.length / slots,
      byDifficulty: _tally(qs.map((q) => q.difficulty)),
      byType: _tally(qs.map((q) => q.type.name)),
    ));
  }

  final byDifficulty = _tally(active.map((q) => q.difficulty));
  final byType = _tally(active.map((q) => q.type.name));
  final examCount = level?.questionCount;

  final warnings = <CoverageWarning>[];
  for (final s in subjects) {
    final slots = s.slots;
    if (slots != null && isBelowCoverageMultiplier(s.count, slots, minMultiplier)) {
      warnings.add(CoverageWarning(
        code: kCoverageLowMultiplier,
        subjectId: s.subjectId,
        message:
            '${s.name}(${s.subjectId}): ${s.count}問は出題枠$slots問の${_fmt(s.multiplier!)}倍（目安${_fmt(minMultiplier)}倍＝${(slots * minMultiplier).ceil()}問）',
      ));
    }
  }
  if (active.isNotEmpty && byDifficulty.isNotEmpty) {
    final top = byDifficulty.entries.reduce((a, b) => b.value > a.value ? b : a);
    final share = top.value / active.length;
    if (share > maxDifficultyShare) {
      warnings.add(CoverageWarning(
        code: kCoverageDifficultySkew,
        message:
            '難易度${top.key}が全体の${(share * 100).toStringAsFixed(1)}%（${top.value}/${active.length}問）で偏っています（上限${(maxDifficultyShare * 100).toStringAsFixed(0)}%）',
      ));
    }
  }

  return ContentCoverageReport(
    examId: exam.examId,
    levelId: level?.levelId,
    total: active.length,
    examQuestionCount: examCount,
    totalMultiplier:
        examCount == null || examCount <= 0 ? null : active.length / examCount,
    subjects: subjects,
    byDifficulty: byDifficulty,
    byType: byType,
    warnings: warnings,
    minMultiplier: minMultiplier,
    maxDifficultyShare: maxDifficultyShare,
  );
}

Map<K, int> _tally<K>(Iterable<K> keys) {
  final m = <K, int>{};
  for (final k in keys) {
    m[k] = (m[k] ?? 0) + 1;
  }
  final sorted = m.keys.toList()
    ..sort((a, b) => '$a'.compareTo('$b'));
  return {for (final k in sorted) k: m[k]!};
}

String _fmt(double v) => v.toStringAsFixed(1);

String _dist(Map<Object, int> m) =>
    m.isEmpty ? '-' : m.entries.map((e) => '${e.key}:${e.value}').join(' ');

/// テキスト整形。[github] が true なら GitHub Actions の `::group::` 形式
/// （警告は `::warning::` 注釈。注釈は失敗扱いにならない）。
String formatContentCoverageReport(
  ContentCoverageReport r, {
  bool github = false,
}) {
  final b = StringBuffer();
  if (github) b.writeln('::group::content coverage (${r.examId})');
  final lv = r.levelId == null ? '' : ' level=${r.levelId}';
  b.writeln('${r.examId}$lv: ${r.total}問'
      '${r.examQuestionCount == null ? '' : '（出題数${r.examQuestionCount}、全体${_fmt(r.totalMultiplier!)}倍）'}');
  b.writeln('分野別（件数 / 出題枠 = 倍率）:');
  for (final s in r.subjects) {
    final ratio = s.slots == null
        ? '枠未定義'
        : '${s.count}/${s.slots} = ${_fmt(s.multiplier!)}倍';
    b.writeln('  ${s.subjectId} ${s.name}: ${s.count}問 [$ratio] 難易度 ${_dist(s.byDifficulty)} 形式 ${_dist(s.byType)}');
  }
  b.writeln('難易度別: ${_dist(r.byDifficulty)}');
  b.writeln('形式別: ${_dist(r.byType)}');
  if (r.warnings.isEmpty) {
    b.writeln('警告なし');
  } else {
    for (final w in r.warnings) {
      b.writeln(github ? '::warning title=${w.code}::${w.message}' : '$w');
    }
  }
  if (github) b.writeln('::endgroup::');
  return b.toString();
}
