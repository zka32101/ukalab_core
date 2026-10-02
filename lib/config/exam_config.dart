import '../src/json_util.dart';

/// 対象年齢。kids は保護者ゲート・児童向け広告設定が必要になる。
enum Audience { adult, kids }

/// 合格基準。足切り（科目別の最低点）を持てる。
class PassRule {
  const PassRule({required this.totalPct, this.subjectMinPct});

  /// 総合得点率の合格ライン（%）。
  final double totalPct;

  /// 科目別の最低得点率（%）。null なら足切りなし。
  final double? subjectMinPct;

  factory PassRule.fromJson(Map<String, dynamic> j, [String where = 'passRule']) {
    final total = reqNum(j, 'totalPct', where);
    final subject = optNum(j, 'subjectMinPct', where);
    for (final (name, v) in [('totalPct', total), ('subjectMinPct', subject)]) {
      if (v != null && (v < 0 || v > 100)) fail(where, '"$name" は0〜100');
    }
    return PassRule(totalPct: total, subjectMinPct: subject);
  }

  Map<String, dynamic> toJson() => {
        'totalPct': totalPct,
        if (subjectMinPct != null) 'subjectMinPct': subjectMinPct,
      };
}

class SubjectConfig {
  const SubjectConfig({
    required this.subjectId,
    required this.name,
    this.order = 0,
  });

  final String subjectId;
  final String name;
  final int order;

  factory SubjectConfig.fromJson(Map<String, dynamic> j) {
    const where = 'subject';
    return SubjectConfig(
      subjectId: reqString(j, 'subjectId', where),
      name: reqString(j, 'name', where),
      order: optInt(j, 'order', where, 0),
    );
  }

  Map<String, dynamic> toJson() =>
      {'subjectId': subjectId, 'name': name, 'order': order};
}

/// 級・コース。資格に級が無ければ1件だけ定義する。
class LevelConfig {
  const LevelConfig({
    required this.levelId,
    required this.name,
    required this.questionCount,
    required this.passRule,
    this.timeLimitSec,
  });

  final String levelId;
  final String name;

  /// 模擬試験の出題数。
  final int questionCount;
  final PassRule passRule;

  /// 制限時間（秒）。null なら無制限。
  final int? timeLimitSec;

  factory LevelConfig.fromJson(Map<String, dynamic> j) {
    const where = 'level';
    final count = reqInt(j, 'questionCount', where);
    if (count <= 0) fail(where, '"questionCount" は1以上');
    final limit = j['timeLimitSec'];
    if (limit != null && (limit is! int || limit <= 0)) {
      fail(where, '"timeLimitSec" は1以上の整数');
    }
    final rule = j['passRule'];
    if (rule is! Map<String, dynamic>) fail(where, '"passRule" が必要です');
    return LevelConfig(
      levelId: reqString(j, 'levelId', where),
      name: reqString(j, 'name', where),
      questionCount: count,
      timeLimitSec: limit as int?,
      passRule: PassRule.fromJson(rule, '$where.passRule'),
    );
  }

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'name': name,
        'questionCount': questionCount,
        if (timeLimitSec != null) 'timeLimitSec': timeLimitSec,
        'passRule': passRule.toJson(),
      };
}

/// 試験（資格）の定義。ジャンル追加 = ExamConfig(JSON) + 問題データ + テーマ。
class ExamConfig {
  const ExamConfig({
    required this.examId,
    required this.name,
    required this.audience,
    required this.subjects,
    required this.levels,
    this.examDates = const [],
  });

  final String examId;
  final String name;
  final Audience audience;
  final List<SubjectConfig> subjects;
  final List<LevelConfig> levels;

  /// 試験日（試験日ドリブンの学習プラン・カウントダウン用）。
  final List<DateTime> examDates;

  factory ExamConfig.fromJson(Map<String, dynamic> j) {
    const where = 'exam';
    final audienceName = reqString(j, 'audience', where);
    final audience = Audience.values.where((a) => a.name == audienceName);
    if (audience.isEmpty) fail(where, '"audience" は adult か kids');

    final subjects = [
      for (final s in reqObjectList(j, 'subjects', where))
        SubjectConfig.fromJson(s),
    ];
    final levels = [
      for (final l in reqObjectList(j, 'levels', where)) LevelConfig.fromJson(l),
    ];
    _requireUnique(subjects.map((s) => s.subjectId), 'subjectId');
    _requireUnique(levels.map((l) => l.levelId), 'levelId');

    final dates = j['examDates'];
    return ExamConfig(
      examId: reqString(j, 'examId', where),
      name: reqString(j, 'name', where),
      audience: audience.first,
      subjects: subjects,
      levels: levels,
      examDates: [
        if (dates != null)
          for (final d in dates as List<dynamic>)
            DateTime.tryParse('$d') ?? fail(where, '"examDates" の日付が不正: $d'),
      ],
    );
  }

  static void _requireUnique(Iterable<String> ids, String what) {
    final seen = <String>{};
    for (final id in ids) {
      if (!seen.add(id)) fail('exam', '$what が重複しています: $id');
    }
  }

  SubjectConfig? subject(String id) {
    for (final s in subjects) {
      if (s.subjectId == id) return s;
    }
    return null;
  }

  LevelConfig? level(String id) {
    for (final l in levels) {
      if (l.levelId == id) return l;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'examId': examId,
        'name': name,
        'audience': audience.name,
        'subjects': [for (final s in subjects) s.toJson()],
        'levels': [for (final l in levels) l.toJson()],
        'examDates': [
          for (final d in examDates) d.toIso8601String().split('T').first,
        ],
      };
}
