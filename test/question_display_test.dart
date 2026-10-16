import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

Question _q({
  QuestionType type = QuestionType.choice,
  String prompt = '問題文',
  String? clue,
  List<String> answers = const [],
  List<ClozeBlank> blanks = const [],
  bool? answerBool,
}) =>
    Question(
      qid: 'q1',
      examId: 'sample',
      subjectId: 'law',
      topicId: 'topic',
      type: type,
      prompt: prompt,
      clue: clue,
      answers: answers,
      blanks: blanks,
      answerBool: answerBool,
      explanation: '解説文',
      source: QuestionSource.original,
      sourceRef: 'test',
      contentVer: '2026.10.0',
    );

void main() {
  group('displayPrompt', () {
    test('choice / trueFalse は prompt', () {
      expect(_q().displayPrompt, '問題文');
      expect(
        _q(type: QuestionType.trueFalse, prompt: '命題', answerBool: true)
            .displayPrompt,
        '命題',
      );
    });

    test('cloze は {{n}} を ◯ に置換', () {
      final q = _q(
        type: QuestionType.cloze,
        prompt: 'A は {{1}} で、B は {{2}} と {{1}}。',
        blanks: const [
          ClozeBlank(id: 1, answers: ['x']),
          ClozeBlank(id: 2, answers: ['y']),
        ],
      );
      expect(q.displayPrompt, 'A は ◯ で、B は ◯ と ◯。');
    });

    test('reverseLookup は clue、空・空白・nullなら prompt', () {
      expect(
        _q(type: QuestionType.reverseLookup, clue: '説明文', answers: ['a'])
            .displayPrompt,
        '説明文',
      );
      expect(
        _q(type: QuestionType.reverseLookup, clue: '', answers: ['a'])
            .displayPrompt,
        '問題文',
      );
      expect(
        _q(type: QuestionType.reverseLookup, clue: '  ', answers: ['a'])
            .displayPrompt,
        '問題文',
      );
      expect(
        _q(type: QuestionType.reverseLookup, answers: ['a']).displayPrompt,
        '問題文',
      );
    });
  });

  group('searchQuestions（新形式）', () {
    final rev = _q(
      type: QuestionType.reverseLookup,
      prompt: '次の説明に当てはまる用語は',
      clue: '契約の効力を失わせる意思表示',
      answers: ['Cancel', '取消し'],
    );
    final cloze = _q(
      type: QuestionType.cloze,
      prompt: '{{1}} は {{2}}',
      blanks: const [
        ClozeBlank(id: 1, answers: ['善意']),
        ClozeBlank(id: 2, answers: ['無過失', 'ＮｏＦａｕｌｔ']),
      ],
    );
    final pool = [rev, cloze, _q()];

    test('reverseLookup の clue / answers がヒットする', () {
      expect(searchQuestions(pool, '効力'), [rev]);
      expect(searchQuestions(pool, '取消し'), [rev]);
      expect(searchQuestions(pool, 'cancel'), [rev]);
    });

    test('cloze の blanks.answers がヒットする', () {
      expect(searchQuestions(pool, '善意'), [cloze]);
      expect(searchQuestions(pool, '無過失'), [cloze]);
    });

    test('既存の挙動は不変（空キーワードは空、通常問題は prompt で検索）', () {
      expect(searchQuestions(pool, ''), isEmpty);
      expect(searchQuestions(pool, '問題文'), [pool[2]]);
    });
  });
}
