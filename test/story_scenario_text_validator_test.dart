import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

StoryScenario _s({
  String title = 'タイトル',
  String situation = '状況',
  String feedback = '解説',
  QuestionSource source = QuestionSource.original,
  String sourceRef = '自作(AI下書き)',
}) =>
    StoryScenario(
      scenarioId: 's1',
      examId: 'e',
      title: title,
      description: '説明',
      chapters: [
        StoryChapter(chapterId: 'c1', situation: situation, choices: [
          StoryChoice(choiceId: 'a', text: 'A', isRecommended: true, feedback: feedback),
          const StoryChoice(choiceId: 'b', text: 'B', isRecommended: false, feedback: 'x'),
        ]),
      ],
      source: source,
      sourceRef: sourceRef,
      contentVer: '1',
    );

void main() {
  test('問題のないシナリオは指摘なし', () {
    expect(validateStoryScenarioText([_s()], requireOriginalSelfMade: true), isEmpty);
  });

  test('禁止語を題名・状況・解説から検出する(語ごとに1件)', () {
    final issues = validateStoryScenarioText([
      _s(title: '公式ガイド', situation: '過去問と同じ', feedback: '合格保証します'),
    ]);
    expect(issues.map((i) => i.code).toSet(), {'forbidden-word'});
    expect(issues.length, 3);
    expect(issues.first.qid, 's1');
  });

  test('禁止語リストは差し替えられる', () {
    expect(validateStoryScenarioText([_s(title: '公式')], forbiddenWords: ['絶対']), isEmpty);
    expect(validateStoryScenarioText([_s(title: '絶対')], forbiddenWords: ['絶対']), hasLength(1));
  });

  test('requireOriginalSelfMade: 自作でなければ指摘する', () {
    final issues = validateStoryScenarioText(
      [_s(source: QuestionSource.licensed, sourceRef: '他社')],
      requireOriginalSelfMade: true,
    );
    expect(issues.map((i) => i.code), containsAll(['not-original', 'no-self-made']));
    expect(validateStoryScenarioText([_s(source: QuestionSource.licensed, sourceRef: '他社')]), isEmpty);
  });
}
