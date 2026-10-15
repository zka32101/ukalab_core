import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

Question q(
  String qid, {
  String? conceptId,
  QuestionAngle? angle,
  bool disabled = false,
}) => Question(
  qid: qid,
  examId: 'sample',
  subjectId: 'math',
  topicId: 't',
  prompt: '問題$qid',
  choices: const ['a', 'b', 'c', 'd'],
  answerIndex: 0,
  explanation: '解説',
  source: QuestionSource.original,
  sourceRef: '自作',
  contentVer: '1',
  conceptId: conceptId,
  angle: angle,
  disabled: disabled,
);

Set<String> codes(List<ContentIssue> issues) => {
  for (final i in issues) i.code,
};

void main() {
  group('Question の conceptId / angle', () {
    test('未指定なら toJson に出ない（既存データは無変更）', () {
      final json = q('q1').toJson();
      expect(json.containsKey('conceptId'), isFalse);
      expect(json.containsKey('angle'), isFalse);
    });

    test('指定した値は往復できる', () {
      final src = q(
        'q1',
        conceptId: 'c-gradient',
        angle: QuestionAngle.trueFalse,
      );
      final json = src.toJson();
      expect(json['conceptId'], 'c-gradient');
      expect(json['angle'], 'trueFalse');
      final back = Question.fromJson(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
      );
      expect(back.conceptId, 'c-gradient');
      expect(back.angle, QuestionAngle.trueFalse);
      expect(back.toJson(), json);
    });

    test('QuestionAngle の全値が JSON 名で往復する', () {
      for (final a in QuestionAngle.values) {
        final json = q('q', conceptId: 'c', angle: a).toJson();
        expect(Question.fromJson(json).angle, a);
      }
      expect(QuestionAngle.values.map((a) => a.name), [
        'definition',
        'scenario',
        'comparison',
        'reverse',
        'cloze',
        'trueFalse',
      ]);
    });

    test('conceptId が空文字なら読み込みエラー', () {
      final json = q('q1').toJson()..['conceptId'] = '  ';
      expect(() => Question.fromJson(json), throwsFormatException);
    });

    test('conceptId が null / 無しは未設定', () {
      final json = q('q1').toJson()..['conceptId'] = null;
      expect(Question.fromJson(json).conceptId, isNull);
    });

    test('未知の angle は null で読み込み、パーサが警告にする', () {
      final line = jsonEncode(
        q('q1', conceptId: 'c').toJson()..['angle'] = 'weird',
      );
      final parsed = parseQuestionsJsonl(line);
      expect(parsed.questions, hasLength(1));
      expect(parsed.questions.single.angle, isNull);
      expect(parsed.issues, hasLength(1));
      expect(parsed.issues.single.code, 'angle-unknown');
      expect(parsed.issues.single.severity, ContentSeverity.warning);
    });

    test('angle が文字列でない値も警告（落とさない）', () {
      final line = jsonEncode(q('q1').toJson()..['angle'] = 3);
      final parsed = parseQuestionsJsonl(line);
      expect(parsed.questions, hasLength(1));
      expect(codes(parsed.issues), {'angle-unknown'});
    });
  });

  group('後方互換', () {
    test('サンプル問題は conceptId / angle なしで読め、往復しても同一', () {
      final text = File('example/sample_questions.jsonl').readAsStringSync();
      final parsed = parseQuestionsJsonl(text);
      expect(parsed.issues, isEmpty);
      final lines = const LineSplitter()
          .convert(text)
          .where((l) => l.trim().isNotEmpty && !l.trim().startsWith('//'))
          .toList();
      expect(parsed.questions, hasLength(lines.length));
      for (var i = 0; i < lines.length; i++) {
        final original = jsonDecode(lines[i]) as Map<String, dynamic>;
        final out = parsed.questions[i].toJson();
        expect(out.containsKey('conceptId'), isFalse);
        expect(out.containsKey('angle'), isFalse);
        // 出力は元 JSON が持つキーの値を変えない（元に無い既定値キーの追加は従来どおり）
        for (final e in original.entries) {
          expect(out[e.key], e.value, reason: '${original['qid']}.${e.key}');
        }
        // 2 回目の往復は完全一致
        expect(Question.fromJson(out).toJson(), out);
      }
    });

    test('観点を持たないデータでは観点の検査は何も出さない', () {
      final qs = [q('a'), q('b')];
      expect(validateQuestionAngles(qs), isEmpty);
      expect(validateQuestionAngles(qs, strictAngles: true), isEmpty);
    });

    test('ContentIssue の既定は error で、toString は従来のまま', () {
      const i = ContentIssue('q1', 'x', 'm');
      expect(i.severity, ContentSeverity.error);
      expect(i.isWarning, isFalse);
      expect(i.toString(), '[x] q1: m');
    });
  });

  group('validateQuestionAngles', () {
    test('conceptId があり angle が無い → concept-without-angle（警告）', () {
      final issues = validateQuestionAngles([
        q('a', conceptId: 'c1'),
        q('b', conceptId: 'c1', angle: QuestionAngle.definition),
        q('c', conceptId: 'c1', angle: QuestionAngle.reverse),
      ]);
      expect(issues, hasLength(1));
      expect(issues.single.code, 'concept-without-angle');
      expect(issues.single.qid, 'a');
      expect(issues.single.isWarning, isTrue);
    });

    test('異なる angle が 2 未満 → concept-single-angle（警告）', () {
      final issues = validateQuestionAngles([
        q('a', conceptId: 'c1', angle: QuestionAngle.definition),
        q('b', conceptId: 'c1', angle: QuestionAngle.definition),
        q('c', conceptId: 'c2', angle: QuestionAngle.definition),
        q('d', conceptId: 'c2', angle: QuestionAngle.cloze),
      ]);
      expect(codes(issues), {'concept-single-angle'});
      expect(issues.single.qid, 'c1');
      expect(issues.single.isWarning, isTrue);
    });

    test('angle のない問題は観点に数えない', () {
      final issues = validateQuestionAngles([
        q('a', conceptId: 'c1', angle: QuestionAngle.definition),
        q('b', conceptId: 'c1'),
      ]);
      expect(codes(issues), {'concept-without-angle', 'concept-single-angle'});
    });

    test('disabled の問題は数えない', () {
      final issues = validateQuestionAngles([
        q('a', conceptId: 'c1', angle: QuestionAngle.definition),
        q('b', conceptId: 'c1', angle: QuestionAngle.reverse, disabled: true),
      ]);
      expect(codes(issues), {'concept-single-angle'});
    });

    test('conceptId の無い問題は concept-single-angle の対象外', () {
      final issues = validateQuestionAngles([
        q('a', angle: QuestionAngle.definition),
        q('b', angle: QuestionAngle.definition),
      ]);
      expect(issues, isEmpty);
    });

    test('--strict-angles: concept-single-angle だけエラーになる', () {
      final qs = [
        q('a', conceptId: 'c1', angle: QuestionAngle.definition),
        q('b', conceptId: 'c2'),
      ];
      final strict = validateQuestionAngles(qs, strictAngles: true);
      final single = strict.where((i) => i.code == 'concept-single-angle');
      expect(single, hasLength(2));
      expect(single.every((i) => !i.isWarning), isTrue);
      final without = strict.singleWhere(
        (i) => i.code == 'concept-without-angle',
      );
      expect(without.isWarning, isTrue);
    });

    test('結果は概念ID順で決定的', () {
      final issues = validateQuestionAngles([
        q('a', conceptId: 'zz', angle: QuestionAngle.cloze),
        q('b', conceptId: 'aa', angle: QuestionAngle.cloze),
      ]);
      expect(issues.map((i) => i.qid), ['aa', 'zz']);
    });

    test('validateQuestions 自体は観点の指摘を出さない（既存の挙動を維持）', () {
      final exam = ExamConfig.fromJson(
        jsonDecode(File('example/sample_exam.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      expect(validateQuestions([q('a', conceptId: 'c1')], exam: exam), isEmpty);
    });
  });

  group('AngleCoverageReport', () {
    final qs = [
      q('a1', conceptId: 'c1', angle: QuestionAngle.definition),
      q('a2', conceptId: 'c1', angle: QuestionAngle.reverse),
      q('a3', conceptId: 'c1', angle: QuestionAngle.reverse),
      q('b1', conceptId: 'c2', angle: QuestionAngle.cloze),
      q('c1', conceptId: 'c3'),
      q('x1'),
      q('d1', conceptId: 'c9', angle: QuestionAngle.scenario, disabled: true),
    ];

    test('集計値', () {
      final r = AngleCoverageReport.fromQuestions(qs);
      expect(r.totalQuestions, 6);
      expect(r.questionsWithConcept, 5);
      expect(r.questionsWithAngle, 4);
      expect(r.conceptCount, 3);
      expect(r.conceptsWithMultipleAngles, 1);
      expect(r.multiAngleRate, closeTo(1 / 3, 1e-9));
      expect(r.conceptIdRate, closeTo(5 / 6, 1e-9));
      expect(r.questionsByAngle[QuestionAngle.reverse], 2);
      expect(r.questionsByAngle[QuestionAngle.scenario], 0);
      expect(r.conceptsBelowTwoAngles.map((c) => c.conceptId), ['c2', 'c3']);
      final c3 = r.concepts.last;
      expect(c3.unspecifiedCount, 1);
      expect(c3.angleCount, 0);
    });

    test('conceptId が無いデータでは率は null、概念は空', () {
      final r = AngleCoverageReport.fromQuestions([q('a')]);
      expect(r.conceptCount, 0);
      expect(r.multiAngleRate, isNull);
      expect(r.conceptIdRate, 0);
      expect(AngleCoverageReport.fromQuestions([]).conceptIdRate, isNull);
      expect(r.toMarkdown(), contains('conceptId を持つ問題がありません'));
    });

    test('JSON は決定的で、キーが固定', () {
      final a = AngleCoverageReport.fromQuestions(qs).toJsonString();
      final b = AngleCoverageReport.fromQuestions(
        qs.reversed.toList(),
      ).toJsonString();
      expect(a, b);
      final j = jsonDecode(a) as Map<String, dynamic>;
      expect(j['conceptCount'], 3);
      expect((j['questionsByAngle'] as Map).keys, [
        'definition',
        'scenario',
        'comparison',
        'reverse',
        'cloze',
        'trueFalse',
      ]);
      expect(j['conceptsBelowTwoAngles'], ['c2', 'c3']);
      expect((j['concepts'] as List).first, {
        'conceptId': 'c1',
        'angleCount': 2,
        'angles': {'definition': 1, 'reverse': 2},
        'unspecified': 0,
      });
    });

    test('Markdown に主要な行が出る', () {
      final md = AngleCoverageReport.fromQuestions(qs).toMarkdown();
      expect(md, contains('# 観点カバレッジ'));
      expect(md, contains('| 2 観点以上の概念 | 1 (33.3%) |'));
      expect(md, contains('| c1 | 2 |'));
      expect(md, contains('- c2（1 観点）'));
    });
  });

  group('validate_content CLI', () {
    // dart run の起動に時間がかかることがあるため、このグループだけ長めにする
    late Directory tmp;
    late String qPath;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('angle_cli');
      qPath = '${tmp.path}/q.jsonl';
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    ProcessResult run(List<String> extra) =>
        Process.runSync('dart', [
          'run',
          'ukalab_core:validate_content',
          'example/sample_exam.json',
          ...extra,
          qPath,
        ]);

    void writeQuestions(List<Question> list) => File(
      qPath,
    ).writeAsStringSync(list.map((e) => jsonEncode(e.toJson())).join('\n'));

    test(
      '警告だけなら終了コード 0、--strict-angles で 1',
      timeout: const Timeout(Duration(minutes: 3)),
      () {
        writeQuestions([
          q('a', conceptId: 'c1', angle: QuestionAngle.definition),
        ]);
        final ok = run([]);
        expect(ok.exitCode, 0, reason: '${ok.stdout}${ok.stderr}');
        expect(ok.stdout, contains('[warning:concept-single-angle]'));
        expect(ok.stdout, contains('警告1件'));
        final strict = run(['--strict-angles']);
        expect(strict.exitCode, 1);
        expect(strict.stdout, contains('[concept-single-angle]'));
      },
    );

    test(
      '--angle-report=json / md',
      timeout: const Timeout(Duration(minutes: 3)),
      () {
        writeQuestions([
          q('a', conceptId: 'c1', angle: QuestionAngle.definition),
          q('b', conceptId: 'c1', angle: QuestionAngle.cloze),
        ]);
        final out = '${tmp.path}/r.json';
        final r = run(['--angle-report=json', '--angle-report-out=$out']);
        expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
        final j =
            jsonDecode(File(out).readAsStringSync()) as Map<String, dynamic>;
        expect(j['conceptsWithMultipleAngles'], 1);
        final md = run(['--angle-report=md']);
        expect(md.stdout, contains('# 観点カバレッジ'));
        expect(run(['--angle-report=xml']).exitCode, 64);
      },
    );
  });
}
