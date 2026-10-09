import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:ukalab_core/ukalab_core.dart';

final exam = ExamConfig.fromJson(
  jsonDecode(File('example/sample_exam.json').readAsStringSync())
      as Map<String, dynamic>,
);

Term t({
  String termId = 't1',
  String examId = 'sample',
  String? subjectId = 'math',
  String term = '用語',
  String headline = 'ひとこと',
  String definition = '定義',
  List<String> relatedTermIds = const [],
  List<String> relatedQuestionIds = const [],
  QuestionSource source = QuestionSource.original,
  String sourceRef = '自作',
  String? license,
  String? lawVersion,
  String contentVer = '1',
  String? era,
}) =>
    Term(
      termId: termId,
      examId: examId,
      subjectId: subjectId,
      term: term,
      headline: headline,
      definition: definition,
      relatedTermIds: relatedTermIds,
      relatedQuestionIds: relatedQuestionIds,
      source: source,
      sourceRef: sourceRef,
      license: license,
      lawVersion: lawVersion,
      contentVer: contentVer,
      era: era,
    );

Set<String> codes(List<ContentIssue> issues) => {for (final i in issues) i.code};

void main() {
  test('サンプル用語データは検証を通る', () {
    final parsed = parseTermsJsonl(
      File('example/sample_terms.jsonl').readAsStringSync(),
    );
    expect(parsed.issues, isEmpty);
    expect(parsed.terms, hasLength(2));
    expect(validateTerms(parsed.terms, exam: exam), isEmpty);
  });

  test('正しい用語は指摘なし', () {
    expect(validateTerms([t()], exam: exam), isEmpty);
  });

  test('era は fromJson/toJson を往復する', () {
    final json = t(era: 'generative_ai').toJson();
    expect(json['era'], 'generative_ai');
    expect(Term.fromJson(json).era, 'generative_ai');
  });

  test('era 未指定なら toJson に含まれず、fromJson は null', () {
    final json = t().toJson();
    expect(json.containsKey('era'), isFalse);
    expect(Term.fromJson(json).era, isNull);
  });

  test('termId の重複', () {
    expect(codes(validateTerms([t(), t()])), contains('duplicate-id'));
  });

  test('見出し語(term)の重複は同義語として指摘', () {
    expect(
      codes(validateTerms([t(termId: 't1', term: 'AI'), t(termId: 't2', term: 'AI')])),
      contains('duplicate-term'),
    );
  });

  group('必須項目', () {
    test('term が空', () {
      expect(codes(validateTerms([t(term: ' ')])), contains('empty-term'));
    });
    test('headline が空', () {
      expect(codes(validateTerms([t(headline: ' ')])), contains('empty-headline'));
    });
    test('definition が空', () {
      expect(codes(validateTerms([t(definition: ' ')])), contains('empty-definition'));
    });
    test('contentVer が空', () {
      expect(codes(validateTerms([t(contentVer: '')])), contains('no-content-ver'));
    });
  });

  group('出典', () {
    test('sourceRef が空', () {
      expect(codes(validateTerms([t(sourceRef: ' ')])), contains('no-source'));
    });
    test('licensed は license が必要', () {
      expect(
        codes(validateTerms([t(source: QuestionSource.licensed)])),
        contains('no-license'),
      );
      expect(
        validateTerms([t(source: QuestionSource.licensed, license: '許諾済 2026-10-01')]),
        isEmpty,
      );
    });
    test('statute は lawVersion が必要', () {
      expect(
        codes(validateTerms([t(source: QuestionSource.statute)])),
        contains('no-law-version'),
      );
      expect(
        validateTerms([t(source: QuestionSource.statute, lawVersion: '2026-04')]),
        isEmpty,
      );
    });
  });

  group('関連用語・関連問題', () {
    test('未定義の関連用語', () {
      expect(
        codes(validateTerms([t(relatedTermIds: ['zzz'])])),
        contains('unknown-related-term'),
      );
    });
    test('自分自身を関連用語に指定', () {
      expect(
        codes(validateTerms([t(termId: 't1', relatedTermIds: ['t1'])])),
        contains('self-related-term'),
      );
    });
    test('関連用語が実在すれば指摘なし', () {
      expect(
        validateTerms([
          t(termId: 't1', term: 'A', relatedTermIds: ['t2']),
          t(termId: 't2', term: 'B'),
        ]),
        isEmpty,
      );
    });
    test('questions を渡すと関連問題のリンク切れを検査する', () {
      final questions = [
        Question(
          qid: 'q1',
          examId: 'sample',
          subjectId: 'math',
          topicId: 'x',
          prompt: 'p',
          choices: const ['a', 'b'],
          answerIndex: 0,
          explanation: 'e',
          source: QuestionSource.original,
          sourceRef: '自作',
          contentVer: '1',
        ),
      ];
      expect(
        codes(validateTerms([t(relatedQuestionIds: ['zzz'])], questions: questions)),
        contains('unknown-related-question'),
      );
      expect(
        validateTerms([t(relatedQuestionIds: ['q1'])], questions: questions),
        isEmpty,
      );
      // questions を渡さなければ検査しない
      expect(validateTerms([t(relatedQuestionIds: ['zzz'])]), isEmpty);
    });
  });

  test('試験定義との整合', () {
    expect(codes(validateTerms([t(examId: 'other')], exam: exam)), contains('exam-mismatch'));
    expect(
      codes(validateTerms([t(subjectId: 'zzz')], exam: exam)),
      contains('unknown-subject'),
    );
    // subjectId が null なら分野を問わない用語として許容する
    expect(validateTerms([t(subjectId: null)], exam: exam), isEmpty);
  });

  group('JSON Lines の読み込み', () {
    test('壊れた行は行番号つきの issue になり、他の行は読み込まれる', () {
      const good =
          '{"termId":"a","examId":"sample","term":"用語","headline":"h","definition":"d","source":"original","sourceRef":"自作","contentVer":"1"}';
      final parsed = parseTermsJsonl('$good\nこれはJSONではない\n\n[1,2]\n');
      expect(parsed.terms, hasLength(1));
      expect(parsed.issues.map((i) => i.qid), ['line:2', 'line:4']);
      expect(parsed.issues.every((i) => i.code == 'parse'), isTrue);
    });

    test('source が不正だと読み込みエラー', () {
      final parsed = parseTermsJsonl(
        '{"termId":"a","examId":"sample","term":"用語","headline":"h","definition":"d","source":"unknown","sourceRef":"x","contentVer":"1"}',
      );
      expect(parsed.terms, isEmpty);
      expect(parsed.issues.single.message, contains('source'));
    });

    test('toJson → fromJson で往復できる', () {
      final original = t(
        relatedTermIds: ['t2'],
        relatedQuestionIds: ['q1'],
        source: QuestionSource.statute,
        lawVersion: '2026-04',
      );
      final again = Term.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(again.toJson(), original.toJson());
    });
  });
}
