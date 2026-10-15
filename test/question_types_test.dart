import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

Map<String, dynamic> base(String qid, Map<String, dynamic> extra) => {
  'qid': qid,
  'examId': 'sample',
  'subjectId': 'ml',
  'topicId': 't1',
  'prompt': '問題$qid',
  'explanation': '解説',
  'source': 'original',
  'sourceRef': '自作',
  'contentVer': '1',
  ...extra,
};

Map<String, dynamic> tfJson([String qid = 'tf1']) => base(qid, {
  'type': 'trueFalse',
  'prompt': '過学習は訓練データに合いすぎる状態である。',
  'answerBool': true,
});

Map<String, dynamic> clozeJson([String qid = 'cl1']) => base(qid, {
  'type': 'cloze',
  'prompt': '{{1}}は訓練データに合いすぎる状態で、{{2}}とは異なる。',
  'blanks': [
    {
      'id': 1,
      'answers': ['過学習', 'オーバーフィッティング'],
      'choices': ['過学習', '学習不足', '正則化'],
    },
    {
      'id': 2,
      'answers': ['未学習', 'アンダーフィッティング'],
    },
  ],
});

Map<String, dynamic> reverseJson([String qid = 'rv1']) => base(qid, {
  'type': 'reverseLookup',
  'prompt': '次の説明にあたる用語は何か。',
  'clue': '訓練データに合いすぎて、未知のデータで性能が落ちる状態。',
  'answers': ['過学習', 'オーバーフィッティング'],
});

Question parse(Map<String, dynamic> j) =>
    Question.fromJson(jsonDecode(jsonEncode(j)) as Map<String, dynamic>);

Set<String> codes(List<ContentIssue> issues) => {
  for (final i in issues) i.code,
};

List<ContentIssue> validate(Map<String, dynamic> j) =>
    validateQuestions([parse(j)]);

void main() {
  group('QuestionType の追加（後方互換）', () {
    test('既存4値の名前・順序は変えず、末尾に3値を足す', () {
      expect(QuestionType.values.map((t) => t.name).toList(), [
        'choice',
        'journal',
        'worksheet',
        'ledger',
        'trueFalse',
        'cloze',
        'reverseLookup',
      ]);
    });

    test('既存の選択式 JSON は無変更で読め、新項目を出力しない', () {
      final j = base('old', {
        'choices': ['a', 'b'],
        'answerIndex': 1,
      });
      final q = parse(j);
      expect(q.type, QuestionType.choice);
      expect(q.answerBool, isNull);
      expect(q.blanks, isEmpty);
      expect(q.clue, isNull);
      expect(q.answers, isEmpty);
      final out = q.toJson();
      for (final k in ['answerBool', 'blanks', 'clue', 'answers']) {
        expect(out.containsKey(k), isFalse, reason: k);
      }
    });
  });

  group('シリアライズ往復', () {
    test('trueFalse（true / false とも）', () {
      for (final v in [true, false]) {
        final q = parse({...tfJson(), 'answerBool': v});
        expect(q.type, QuestionType.trueFalse);
        expect(q.answerBool, v);
        final back = parse(q.toJson());
        expect(back.answerBool, v);
        expect(back.toJson(), q.toJson());
        expect(q.toJson().containsKey('choices'), isFalse);
      }
    });

    test('cloze（選択肢つき・自由入力の混在）', () {
      final q = parse(clozeJson());
      expect(q.blanks.length, 2);
      expect(q.blanks[0].hasChoices, isTrue);
      expect(q.blanks[1].hasChoices, isFalse);
      expect(q.blanks[0].answers, ['過学習', 'オーバーフィッティング']);
      final json = q.toJson();
      expect((json['blanks'] as List)[1].containsKey('choices'), isFalse);
      final back = parse(json);
      expect(back.blanks, q.blanks);
      expect(back.toJson(), json);
    });

    test('reverseLookup（自由入力 / 選択肢つき）', () {
      final free = parse(reverseJson());
      expect(free.clue, contains('訓練データ'));
      expect(free.answers.length, 2);
      expect(free.choices, isEmpty);
      expect(free.toJson().containsKey('choices'), isFalse);
      expect(parse(free.toJson()).toJson(), free.toJson());

      final withChoices = parse({
        ...reverseJson(),
        'choices': ['過学習', '正則化', '特徴量'],
      });
      expect(withChoices.choices.length, 3);
      final json = withChoices.toJson();
      expect(json['choices'], ['過学習', '正則化', '特徴量']);
      expect(json.containsKey('answerIndex'), isFalse);
      expect(parse(json).toJson(), json);
    });

    test('conceptId / angle と併用できる', () {
      final q = parse({
        ...tfJson(),
        'conceptId': 'c-overfit',
        'angle': 'trueFalse',
      });
      expect(q.conceptId, 'c-overfit');
      expect(q.angle, QuestionAngle.trueFalse);
      expect(parse(q.toJson()).angle, QuestionAngle.trueFalse);
    });

    test('Question コンストラクタ: trueFalse に answerBool が無いとアサーション', () {
      expect(
        () => Question(
          qid: 'x',
          examId: 'e',
          subjectId: 's',
          topicId: 't',
          prompt: 'p',
          explanation: 'e',
          source: QuestionSource.original,
          sourceRef: 'r',
          contentVer: '1',
          type: QuestionType.trueFalse,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('fromJson の形の検査（不正は FormatException）', () {
    void expectFormat(Map<String, dynamic> j, String part) {
      expect(
        () => parse(j),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains(part),
          ),
        ),
      );
    }

    test('trueFalse: answerBool が無い・bool でない', () {
      expectFormat(base('a', {'type': 'trueFalse'}), 'answerBool');
      expectFormat(
        base('a', {'type': 'trueFalse', 'answerBool': 'true'}),
        'answerBool',
      );
      expectFormat(
        base('a', {'type': 'trueFalse', 'answerBool': 1}),
        'answerBool',
      );
    });

    test('cloze: blanks が無い・配列でない・要素がオブジェクトでない・answers が不正', () {
      expectFormat(base('a', {'type': 'cloze', 'prompt': '{{1}}'}), 'blanks');
      expectFormat(base('a', {'type': 'cloze', 'blanks': {}}), 'blanks');
      expectFormat(
        base('a', {
          'type': 'cloze',
          'blanks': ['x'],
        }),
        'blanks',
      );
      expectFormat(
        base('a', {
          'type': 'cloze',
          'blanks': [
            {'id': 1},
          ],
        }),
        'answers',
      );
      expectFormat(
        base('a', {
          'type': 'cloze',
          'blanks': [
            {
              'id': '1',
              'answers': ['x'],
            },
          ],
        }),
        'id',
      );
      expectFormat(
        base('a', {
          'type': 'cloze',
          'blanks': [
            {
              'id': 1,
              'answers': ['x'],
              'choices': [1],
            },
          ],
        }),
        'choices',
      );
    });

    test('reverseLookup: clue / answers が無い・型が違う', () {
      expectFormat(
        base('a', {
          'type': 'reverseLookup',
          'answers': ['x'],
        }),
        'clue',
      );
      expectFormat(
        base('a', {'type': 'reverseLookup', 'clue': 'c'}),
        'answers',
      );
      expectFormat(
        base('a', {'type': 'reverseLookup', 'clue': 'c', 'answers': 'x'}),
        'answers',
      );
      expectFormat(
        base('a', {
          'type': 'reverseLookup',
          'clue': 'c',
          'answers': ['x'],
          'choices': 'y',
        }),
        'choices',
      );
    });

    test('未知の type は従来どおり FormatException', () {
      expectFormat(base('a', {'type': 'numeric'}), '未対応の type');
    });

    test('parseQuestionsJsonl は不正行を parse 指摘にして続行する', () {
      final text = [
        jsonEncode(tfJson('ok')),
        jsonEncode(base('bad', {'type': 'trueFalse'})),
      ].join('\n');
      final parsed = parseQuestionsJsonl(text);
      expect(parsed.questions.map((q) => q.qid), ['ok']);
      expect(codes(parsed.issues), {'parse'});
    });
  });

  group('validateQuestions: 新タイプ', () {
    test('正しいデータは指摘なし', () {
      expect(validate(tfJson()), isEmpty);
      expect(validate(clozeJson()), isEmpty);
      expect(validate(reverseJson()), isEmpty);
      expect(
        validate({
          ...reverseJson(),
          'choices': ['過学習', '正則化', '特徴量'],
        }),
        isEmpty,
      );
    });

    test('trueFalse: choices は使えない', () {
      expect(
        codes(validate({...tfJson(), 'type': 'trueFalse', 'prompt': 'p'})),
        isEmpty,
      );
      // choices を持たせるには Question を直接作る
      final q = Question(
        qid: 'tf',
        examId: 'sample',
        subjectId: 'ml',
        topicId: 't',
        prompt: 'p',
        explanation: 'e',
        source: QuestionSource.original,
        sourceRef: 'r',
        contentVer: '1',
        type: QuestionType.trueFalse,
        answerBool: true,
        choices: const ['a', 'b'],
      );
      expect(codes(validateQuestions([q])), {'truefalse-choices'});
    });

    test('cloze: blanks が空', () {
      expect(
        codes(validate({...clozeJson(), 'blanks': []})),
        contains('cloze-no-blanks'),
      );
    });

    test('cloze: 空欄 id の重複・0 以下', () {
      final dup = clozeJson();
      (dup['blanks'] as List)[1]['id'] = 1;
      expect(codes(validate(dup)), contains('cloze-blank-id'));
      final zero = clozeJson();
      (zero['blanks'] as List)[0]['id'] = 0;
      expect(codes(validate(zero)), contains('cloze-blank-id'));
    });

    test('cloze: prompt の {{n}} と blanks の不一致（双方向・空欄なし・重複）', () {
      final noBlankForPlaceholder = {
        ...clozeJson(),
        'prompt': '{{1}}と{{2}}と{{3}}',
      };
      final i1 = validate(noBlankForPlaceholder);
      expect(codes(i1), contains('cloze-placeholder'));
      expect(i1.map((i) => i.message).join(), contains('{{3}}'));

      final unused = {...clozeJson(), 'prompt': '{{1}}だけ'};
      final i2 = validate(unused);
      expect(i2.map((i) => i.message).join(), contains('{{2}}'));

      final none = {...clozeJson(), 'prompt': '空欄がない'};
      expect(codes(validate(none)), contains('cloze-placeholder'));

      final twice = {...clozeJson(), 'prompt': '{{1}}と{{1}}と{{2}}'};
      expect(codes(validate(twice)), contains('cloze-placeholder'));
    });

    test('cloze: answers が空・空白のみ・正規化で重複', () {
      for (final answers in [
        <String>[],
        ['  '],
        ['過学習', '過学習 '],
        ['ABC', 'ａｂｃ'],
      ]) {
        final j = clozeJson();
        (j['blanks'] as List)[1]['answers'] = answers;
        expect(
          codes(validate(j)),
          contains('cloze-answers'),
          reason: '$answers',
        );
      }
    });

    test('cloze: 選択肢の数・重複・空・正解との整合', () {
      Set<String> run(void Function(Map<String, dynamic> blank0) edit) {
        final j = clozeJson();
        edit((j['blanks'] as List)[0] as Map<String, dynamic>);
        return codes(validate(j));
      }

      expect(run((b) => b['choices'] = ['過学習']), contains('cloze-choices'));
      expect(
        run((b) => b['choices'] = ['過学習', '過学習']),
        contains('cloze-choices'),
      );
      expect(
        run((b) => b['choices'] = ['過学習', ' ']),
        contains('cloze-choices'),
      );
      expect(
        run((b) => b['choices'] = ['a', 'b', 'c']),
        contains('cloze-choices'),
      ); // 正解なし
      expect(
        run((b) => b['choices'] = ['過学習', 'オーバーフィッティング', 'c']),
        contains('cloze-choices'), // 正解が2個
      );
    });

    test('reverseLookup: answers が空・空白・重複', () {
      for (final answers in [
        <String>[],
        [''],
        ['過学習', '過学習'],
      ]) {
        expect(
          codes(validate({...reverseJson(), 'answers': answers})),
          contains('reverse-answers'),
          reason: '$answers',
        );
      }
    });

    test('reverseLookup: 選択肢つきの検査', () {
      expect(
        codes(
          validate({
            ...reverseJson(),
            'choices': ['過学習'],
          }),
        ),
        contains('reverse-choices'),
      );
      expect(
        codes(
          validate({
            ...reverseJson(),
            'choices': ['正則化', '特徴量'],
          }),
        ),
        contains('reverse-choices'),
      );
      expect(
        codes(
          validate({
            ...reverseJson(),
            'choices': ['過学習', 'オーバーフィッティング'],
          }),
        ),
        contains('reverse-choices'),
      );
      expect(
        codes(
          validate({
            ...reverseJson(),
            'choices': ['過学習', '正則化', '特徴量', 'a', 'b', 'c', 'd'],
          }),
        ),
        contains('reverse-choices'),
      );
    });

    test('reverseLookup: clue に答えが含まれると警告（エラーではない）', () {
      final issues = validate({
        ...reverseJson(),
        'clue': '過学習とは、訓練データに合いすぎる状態。',
      });
      final leak = issues
          .where((i) => i.code == 'reverse-answer-leak')
          .toList();
      expect(leak.length, 1);
      expect(leak.single.isWarning, isTrue);
    });

    test('共通の検査（解説・出典・difficulty）も新タイプに効く', () {
      expect(
        codes(validate({...tfJson(), 'difficulty': 9})),
        contains('difficulty'),
      );
      expect(
        codes(validate({...clozeJson(), 'difficulty': 0})),
        contains('difficulty'),
      );
      expect(
        codes(validate({...reverseJson(), 'points': 0})),
        contains('points'),
      );
    });
  });

  group('normalizeAnswerText', () {
    test('前後・途中の空白（全角含む）を除く', () {
      expect(normalizeAnswerText('  過 学　習 \n'), '過学習');
    });

    test('全角英数・記号 → 半角、英字は小文字', () {
      expect(normalizeAnswerText('ＡＢＣ１２３'), 'abc123');
      expect(normalizeAnswerText('Ｋ－ｍｅａｎｓ'), 'k-means');
      expect(normalizeAnswerText('（ａ）'), '(a)');
    });

    test('半角カナ → 全角カナ（濁点・半濁点を合成）', () {
      expect(normalizeAnswerText('ﾃﾞｨｰﾌﾟﾗｰﾆﾝｸﾞ'), 'ディープラーニング');
      expect(normalizeAnswerText('ﾊﾟｲｿﾝ'), 'パイソン');
      expect(normalizeAnswerText('ｳﾞｪｸﾄﾙ'), 'ヴェクトル');
      expect(normalizeAnswerText('ﾊﾞｯﾁ'), 'バッチ');
      // 濁点の対象でない文字に続く ﾞ は単独の濁点になる
      expect(normalizeAnswerText('ｱﾞ'), 'ア゛');
    });

    test('半角カナの対応表が全角と1対1（先頭・末尾を確認）', () {
      expect(normalizeAnswerText('ｦｧｨｩｪｫｬｭｮｯｰｱﾝ'), 'ヲァィゥェォャュョッーアン');
      expect(normalizeAnswerText('｡｢｣､･'), '。「」、'); // ･（中黒）は除かれる
    });

    test('長音・ハイフンの揺れ: カタカナの直後は長音、それ以外は半角ハイフン', () {
      expect(normalizeAnswerText('ストレ-ジ'), 'ストレージ');
      expect(normalizeAnswerText('ストレ―ジ'), 'ストレージ');
      expect(normalizeAnswerText('ストレ−ジ'), 'ストレージ');
      expect(normalizeAnswerText('ストレージ'), 'ストレージ');
      expect(normalizeAnswerText('k‐means'), 'k-means');
      expect(normalizeAnswerText('k–means'), 'k-means');
      expect(normalizeAnswerText('Tf−Idf'), 'tf-idf');
    });

    test('中黒の揺れを除く', () {
      expect(normalizeAnswerText('ソフトウェア・エンジニア'), 'ソフトウェアエンジニア');
      expect(normalizeAnswerText('ソフトウェア･エンジニア'), 'ソフトウェアエンジニア');
      expect(normalizeAnswerText('ソフトウェア·エンジニア'), 'ソフトウェアエンジニア');
    });

    test('ひらがなとカタカナは同一視しない', () {
      expect(normalizeAnswerText('ぱいそん'), isNot(normalizeAnswerText('パイソン')));
    });

    test('ゼロ幅文字・BOM を除く', () {
      expect(normalizeAnswerText('﻿過​学習'), '過学習');
    });

    test('空文字・空白のみ・記号のみで空になるものは空', () {
      expect(normalizeAnswerText(''), '');
      expect(normalizeAnswerText(' 　 '), '');
      expect(normalizeAnswerText('・'), '');
    });

    test('冪等（2回かけても同じ）', () {
      for (final s in ['ﾃﾞｨｰﾌﾟ ﾗｰﾆﾝｸﾞ', 'Ｋ－Ｍｅａｎｓ', 'ストレ-ジ', '過 学 習']) {
        final once = normalizeAnswerText(s);
        expect(normalizeAnswerText(once), once, reason: s);
      }
    });
  });

  group('answerMatches / 採点', () {
    test('複数の正解のどれでも正解、揺れも許す', () {
      const answers = ['過学習', 'オーバーフィッティング', 'ディープ・ラーニング'];
      expect(answerMatches('過学習', answers), isTrue);
      expect(answerMatches(' 過学習 ', answers), isTrue);
      expect(answerMatches('ｵｰﾊﾞｰﾌｨｯﾃｨﾝｸﾞ', answers), isTrue);
      expect(answerMatches('ディープラーニング', answers), isTrue);
      expect(answerMatches('ﾃﾞｨｰﾌﾟﾗｰﾆﾝｸﾞ', answers), isTrue);
      expect(answerMatches('過学', answers), isFalse);
      expect(answerMatches('おーばーふぃってぃんぐ', answers), isFalse);
    });

    test('空入力は、正解が空でも一致しない', () {
      expect(answerMatches('', ['']), isFalse);
      expect(answerMatches('  ', ['x']), isFalse);
    });

    test('judgeTrueFalse', () {
      final q = parse(tfJson());
      expect(judgeTrueFalse(q, true), isTrue);
      expect(judgeTrueFalse(q, false), isFalse);
      final f = parse({...tfJson(), 'answerBool': false});
      expect(judgeTrueFalse(f, false), isTrue);
      expect(judgeTrueFalse(f, true), isFalse);
    });

    test('judgeCloze: 空欄ごとの正誤と、全空欄正解のときだけ正解', () {
      final q = parse(clozeJson());
      final ok = judgeCloze(q, {1: 'オーバーフィッティング', 2: 'アンダーフィッティング'});
      expect(ok.isCorrect, isTrue);
      expect(ok.blanks, {1: true, 2: true});

      final partial = judgeCloze(q, {1: '過学習', 2: '正則化'});
      expect(partial.isCorrect, isFalse);
      expect(partial.blanks, {1: true, 2: false});
      expect(partial.correctCount, 1);

      final missing = judgeCloze(q, {1: '過学習'});
      expect(missing.isCorrect, isFalse);
      expect(missing.blanks[2], isFalse);

      expect(judgeCloze(q, {}).isCorrect, isFalse);
      // 余分なキーは無視
      expect(judgeCloze(q, {1: '過学習', 2: '未学習', 9: 'x'}).isCorrect, isTrue);
    });

    test('judgeCloze: 空欄が無い問題は不正解扱い', () {
      expect(const ClozeJudgeResult({}).isCorrect, isFalse);
    });

    test('judgeReverseLookup: 自由入力・選択肢の文字列どちらも', () {
      final q = parse(reverseJson());
      expect(judgeReverseLookup(q, '　過学習　'), isTrue);
      expect(judgeReverseLookup(q, 'ｵｰﾊﾞｰﾌｨｯﾃｨﾝｸﾞ'), isTrue);
      expect(judgeReverseLookup(q, '正則化'), isFalse);
      expect(judgeReverseLookup(q, ''), isFalse);
    });
  });

  group('空欄の分割', () {
    test('clozePlaceholderIds / splitClozePrompt', () {
      expect(clozePlaceholderIds('a{{1}}b{{12}}c'), [1, 12]);
      expect(clozePlaceholderIds('空欄なし'), isEmpty);
      expect(clozePlaceholderIds('{{ 1 }}{{a}}'), isEmpty);
      final segs = splitClozePrompt('a{{1}}b{{2}}');
      expect(segs.map((s) => s.isBlank), [false, true, false, true]);
      expect(segs[0].text, 'a');
      expect(segs[1].blankId, 1);
      expect(segs[3].blankId, 2);
      expect(splitClozePrompt('{{1}}').single.isBlank, isTrue);
      expect(splitClozePrompt('').isEmpty, isTrue);
    });
  });

  group('PracticeSession', () {
    PracticeSession session(List<Question> qs) =>
        PracticeSession(pool: qs, size: qs.length, seed: 1);

    test('answerTrueFalse / answerCloze / answerReverseLookup が記録を残す', () {
      final s = PracticeSession(
        pool: [parse(tfJson()), parse(clozeJson()), parse(reverseJson())],
        size: 3,
        priorityQids: ['tf1', 'cl1', 'rv1'],
      );
      final a = s.answerTrueFalse(true);
      expect(a.correct, isTrue);
      expect(a.boolAnswer, isTrue);
      final b = s.answerCloze({1: '過学習', 2: '正則化'});
      expect(b.correct, isFalse);
      expect(b.clozeAnswers, {1: '過学習', 2: '正則化'});
      final c = s.answerReverseLookup('過学習');
      expect(c.correct, isTrue);
      expect(c.textAnswer, '過学習');
      expect(s.finished, isTrue);
      expect(s.correctCount, 2);
    });

    test('型の違うメソッドは StateError', () {
      final s = session([parse(tfJson())]);
      expect(() => s.answer(0), throwsStateError);
      expect(() => s.answerCloze({}), throwsStateError);
      expect(() => s.answerReverseLookup('x'), throwsStateError);
      final c = session([parse(clozeJson())]);
      expect(() => c.answerTrueFalse(true), throwsStateError);
      final r = session([parse(reverseJson())]);
      expect(() => r.answerTrueFalse(true), throwsStateError);
    });

    test('従来のメソッドで新タイプには答えられない（choice 専用の answer）', () {
      final s = session([parse(clozeJson())]);
      expect(() => s.answer(0), throwsStateError);
    });

    test('自己申告: 不正解を正解に直せる（cloze / reverseLookup のみ）', () {
      final s = PracticeSession(
        pool: [parse(reverseJson()), parse(clozeJson()), parse(tfJson())],
        size: 3,
        priorityQids: ['rv1', 'cl1', 'tf1'],
      );
      expect(() => s.markLastSelfReportedCorrect(), throwsStateError); // 記録なし
      s.answerReverseLookup('かがくしゅう');
      expect(s.correctCount, 0);
      final fixed = s.markLastSelfReportedCorrect();
      expect(fixed.correct, isTrue);
      expect(fixed.selfReported, isTrue);
      expect(fixed.textAnswer, 'かがくしゅう');
      expect(s.correctCount, 1);
      expect(s.records.length, 1);

      s.answerCloze({1: '過学習', 2: '未学習'}); // 正解
      final same = s.markLastSelfReportedCorrect();
      expect(same.selfReported, isFalse); // すでに正解なら何もしない

      s.answerTrueFalse(false);
      expect(() => s.markLastSelfReportedCorrect(), throwsStateError);
    });
  });

  group('模擬試験', () {
    const level = LevelConfig(
      levelId: 'l',
      name: 'L',
      questionCount: 10,
      passRule: PassRule(totalPct: 60),
    );

    Question choiceQ(String id) => parse(
      base(id, {
        'choices': ['a', 'b'],
        'answerIndex': 0,
      }),
    );

    test('既定では新タイプを出題しない', () {
      final pool = [
        choiceQ('c1'),
        choiceQ('c2'),
        parse(tfJson()),
        parse(clozeJson()),
        parse(reverseJson()),
      ];
      final picked = pickMockExamQuestions(pool: pool, level: level);
      expect(picked.map((q) => q.qid).toSet(), {'c1', 'c2'});
      final custom = pickCustomMockExamQuestions(
        pool: pool,
        subjectIds: ['ml'],
        count: 10,
      );
      expect(custom.map((q) => q.qid).toSet(), {'c1', 'c2'});
      expect(defaultMockExamTypes.contains(QuestionType.trueFalse), isFalse);
      expect(defaultMockExamTypes.contains(QuestionType.cloze), isFalse);
      expect(
        defaultMockExamTypes.contains(QuestionType.reverseLookup),
        isFalse,
      );
    });

    test('allowedTypes で明示すれば出題できる', () {
      final pool = [
        choiceQ('c1'),
        parse(tfJson()),
        parse(clozeJson()),
        parse(reverseJson()),
      ];
      final picked = pickMockExamQuestions(
        pool: pool,
        level: level,
        allowedTypes: {...defaultMockExamTypes, QuestionType.trueFalse},
      );
      expect(picked.map((q) => q.qid).toSet(), {'c1', 'tf1'});
      final all = pickCustomMockExamQuestions(
        pool: pool,
        subjectIds: ['ml'],
        count: 10,
        allowedTypes: QuestionType.values.toSet(),
      );
      expect(all.length, 4);
    });

    test('scoreMockExam: 新タイプの採点（型違い・未回答は不正解）', () {
      final qs = [parse(tfJson()), parse(clozeJson()), parse(reverseJson())];
      const rule = PassRule(totalPct: 60);
      final all = scoreMockExam(
        questions: qs,
        answers: {
          'tf1': true,
          'cl1': {1: '過学習', 2: 'アンダーフィッティング'},
          'rv1': 'ｵｰﾊﾞｰﾌｨｯﾃｨﾝｸﾞ',
        },
        rule: rule,
      );
      expect(all.total.score, 3);

      final bad = scoreMockExam(
        questions: qs,
        answers: {
          'tf1': 'true', // 型違い
          'cl1': {1: '過学習'}, // 空欄不足
          // rv1 未回答
        },
        rule: rule,
      );
      expect(bad.total.score, 0);

      // Map<int, dynamic> のように型引数が緩くても、中身が int→String なら採点できる
      final loose = scoreMockExam(
        questions: [qs[1]],
        answers: <String, Object?>{
          'cl1': <int, dynamic>{1: '過学習', 2: '未学習'},
        },
        rule: rule,
      );
      expect(loose.total.score, 1);
    });
  });

  group('その他の型別処理', () {
    test('TimeBoxedPlan の既定秒数が新タイプにも定義されている', () {
      for (final t in QuestionType.values) {
        expect(
          QuestionTimeEstimator.defaultSeconds.containsKey(t),
          isTrue,
          reason: t.name,
        );
      }
    });

    test('サンプル問題データ（example）の新タイプが検証を通る', () {
      final text = File(
        'example/sample_question_types.jsonl',
      ).readAsStringSync();
      final parsed = parseQuestionsJsonl(text);
      expect(parsed.issues, isEmpty);
      final types = parsed.questions.map((q) => q.type).toSet();
      expect(
        types,
        containsAll([
          QuestionType.trueFalse,
          QuestionType.cloze,
          QuestionType.reverseLookup,
        ]),
      );
      expect(validateQuestions(parsed.questions), isEmpty);
      expect(validateQuestionAngles(parsed.questions), isEmpty);
    });
  });
}
