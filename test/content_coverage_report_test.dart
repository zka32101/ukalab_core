import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

final exam = ExamConfig.fromJson({
  'examId': 'cov',
  'name': 'カバレッジ検定',
  'audience': 'adult',
  'subjects': [
    {'subjectId': 'a', 'name': '分野A', 'order': 1},
    {'subjectId': 'b', 'name': '分野B', 'order': 2},
  ],
  'levels': [
    {
      'levelId': 'l1',
      'name': '級',
      'questionCount': 10,
      'passRule': {'totalPct': 60},
      'subjectQuestionCounts': {'a': 6, 'b': 4},
    },
  ],
});

int _n = 0;
Question q(
  String subject, {
  int difficulty = 3,
  QuestionType type = QuestionType.choice,
  bool disabled = false,
}) => Question(
  qid: 'q${_n++}',
  examId: 'cov',
  subjectId: subject,
  topicId: 't',
  prompt: 'p',
  type: type,
  choices: const ['a', 'b'],
  answerIndex: 0,
  answerBool: type == QuestionType.trueFalse ? true : null,
  explanation: 'e',
  source: QuestionSource.original,
  sourceRef: '自作',
  contentVer: '1',
  difficulty: difficulty,
  disabled: disabled,
);

List<Question> many(String s, int n, {int Function(int)? diff}) => [
  for (var i = 0; i < n; i++) q(s, difficulty: diff?.call(i) ?? (i % 3) + 1),
];

void main() {
  group('集計と倍率', () {
    test('分野別・難易度別・形式別の件数と倍率', () {
      final qs = [
        ...many('a', 30),
        ...many('b', 20),
        q('b', type: QuestionType.trueFalse),
        q('a', disabled: true),
      ];
      final r = buildContentCoverageReport(exam, qs);
      expect(r.total, 51);
      expect(r.levelId, 'l1');
      expect(r.examQuestionCount, 10);
      expect(r.totalMultiplier, closeTo(5.1, 1e-9));
      final a = r.subjects.firstWhere((s) => s.subjectId == 'a');
      final b = r.subjects.firstWhere((s) => s.subjectId == 'b');
      expect(a.count, 30);
      expect(a.slots, 6);
      expect(a.multiplier, 5.0);
      expect(b.count, 21);
      expect(b.multiplier, closeTo(5.25, 1e-9));
      expect(b.byType, {'choice': 20, 'trueFalse': 1});
      expect(a.byDifficulty, {1: 10, 2: 10, 3: 10});
      expect(r.byDifficulty.values.reduce((x, y) => x + y), 51);
      expect(r.byType['trueFalse'], 1);
    });

    test('枠が未定義の分野は倍率なし・警告なし', () {
      final e = ExamConfig.fromJson({
        'examId': 'cov',
        'name': 'n',
        'audience': 'adult',
        'subjects': [
          {'subjectId': 'a', 'name': 'A'},
        ],
        'levels': [
          {'levelId': 'l', 'name': 'l', 'questionCount': 5, 'passRule': {'totalPct': 60}},
        ],
      });
      final r = buildContentCoverageReport(e, many('a', 3));
      expect(r.subjects.single.multiplier, isNull);
      expect(r.totalMultiplier, closeTo(0.6, 1e-9));
      expect(r.warnings.where((w) => w.code == kCoverageLowMultiplier), isEmpty);
    });
  });

  group('倍率の閾値', () {
    List<CoverageWarning> low(List<Question> qs, {double min = 5}) =>
        buildContentCoverageReport(exam, qs, minMultiplier: min)
            .warnings
            .where((w) => w.code == kCoverageLowMultiplier)
            .toList();

    test('境界ちょうど（5倍）は警告なし、1問足りないと警告', () {
      expect(low([...many('a', 30), ...many('b', 20)]), isEmpty);
      final w = low([...many('a', 29), ...many('b', 20)]);
      expect(w.length, 1);
      expect(w.single.subjectId, 'a');
    });

    test('閾値は引数で変えられる', () {
      final qs = [...many('a', 12), ...many('b', 8)];
      expect(low(qs, min: 2), isEmpty);
      expect(low(qs, min: 3).length, 2);
    });

    test('isBelowCoverageMultiplier', () {
      expect(isBelowCoverageMultiplier(19, 4, 5), isTrue);
      expect(isBelowCoverageMultiplier(20, 4, 5), isFalse);
      expect(isBelowCoverageMultiplier(0, 0, 5), isFalse);
    });
  });

  group('難易度の偏り', () {
    List<CoverageWarning> skew(List<Question> qs, {double share = 0.7}) =>
        buildContentCoverageReport(exam, qs, maxDifficultyShare: share)
            .warnings
            .where((w) => w.code == kCoverageDifficultySkew)
            .toList();

    test('70%ちょうどは警告なし、超えると警告', () {
      List<Question> mix(int threes, int others) => [
        for (var i = 0; i < threes; i++) q('a', difficulty: 3),
        for (var i = 0; i < others; i++) q('b', difficulty: 1),
      ];
      expect(skew(mix(7, 3)), isEmpty);
      expect(skew(mix(71, 29)), hasLength(1));
      expect(skew(mix(71, 29)).single.message, contains('難易度3'));
    });

    test('問題が無いときは偏り警告を出さない', () {
      expect(skew([]), isEmpty);
    });
  });

  group('体験型の本数', () {
    test('無料N+プレミアムMに満たなければ警告', () {
      final w = experienceCountWarning(label: 'ストーリー', actual: 4, free: 3, premium: 3);
      expect(w, isNotNull);
      expect(w!.code, kCoverageExperienceShort);
      expect(w.message, contains('2本不足'));
    });
    test('足りていれば null', () {
      expect(experienceCountWarning(label: 'x', actual: 6, free: 3, premium: 3), isNull);
    });
  });

  group('整形', () {
    test('github 形式は ::group:: と ::warning:: を含む', () {
      final r = buildContentCoverageReport(exam, many('a', 1));
      final t = formatContentCoverageReport(r, github: true);
      expect(t, startsWith('::group::'));
      expect(t, contains('::warning title=$kCoverageLowMultiplier::'));
      expect(t.trimRight(), endsWith('::endgroup::'));
      final plain = formatContentCoverageReport(r);
      expect(plain, isNot(contains('::group::')));
      expect(plain, contains('[warning:$kCoverageLowMultiplier]'));
    });
  });

  group('CLI --coverage', () {
    late Directory tmp;
    late String qPath;
    setUp(() {
      tmp = Directory.systemTemp.createTempSync('coverage_cli');
      qPath = '${tmp.path}/q.jsonl';
      File(qPath).writeAsStringSync(
        many('a', 2).map((e) => jsonEncode(e.toJson())).join('\n'),
      );
      File('${tmp.path}/exam.json').writeAsStringSync(jsonEncode({
        'examId': 'cov',
        'name': 'n',
        'audience': 'adult',
        'subjects': [
          {'subjectId': 'a', 'name': 'A'},
        ],
        'levels': [
          {
            'levelId': 'l',
            'name': 'l',
            'questionCount': 5,
            'passRule': {'totalPct': 60},
            'subjectQuestionCounts': {'a': 5},
          },
        ],
      }));
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    ProcessResult run(List<String> extra) => Process.runSync('dart', [
      'run',
      'ukalab_core:validate_content',
      '${tmp.path}/exam.json',
      ...extra,
      qPath,
    ]);

    test(
      '警告があっても終了コードは --coverage の有無で変わらない',
      timeout: const Timeout(Duration(minutes: 3)),
      () {
        final base = run([]);
        final cov = run(['--coverage']);
        expect(cov.exitCode, base.exitCode, reason: '${cov.stdout}${cov.stderr}');
        expect(base.stdout, isNot(contains('::group::')));
        expect(cov.stdout, contains('::group::content coverage'));
        expect(cov.stdout, contains(kCoverageLowMultiplier));
        expect(cov.stdout, contains('::endgroup::'));
        final strict = run(['--coverage', '--coverage-min-multiplier=0']);
        expect(strict.exitCode, base.exitCode);
        expect(strict.stdout, contains('警告なし'));
      },
    );

    test(
      '不正な閾値は使い方エラー(64)',
      timeout: const Timeout(Duration(minutes: 3)),
      () {
        expect(run(['--coverage-min-multiplier=x']).exitCode, 64);
      },
    );
  });
}
