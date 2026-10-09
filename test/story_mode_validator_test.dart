import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:ukalab_core/ukalab_core.dart';

final exam = ExamConfig.fromJson(
  jsonDecode(File('example/sample_exam.json').readAsStringSync())
      as Map<String, dynamic>,
);

StoryScenario scenario({
  String scenarioId = 's1',
  String examId = 'sample',
  String? subjectId = 'math',
  String title = 'AIプロジェクト経営モード',
  String description = '架空の会社でAI導入を進める。',
  List<StoryChapter> chapters = const [
    StoryChapter(
      chapterId: 'ch1',
      situation: 'データ収集の段階。どちらの方法を選ぶか。',
      choices: [
        StoryChoice(choiceId: 'a', text: '出典・ライセンスを確認して収集', isRecommended: true, feedback: '正しい。'),
        StoryChoice(choiceId: 'b', text: '手早くスクレイピングで収集', isRecommended: false, feedback: '権利の問題あり。'),
      ],
    ),
    StoryChapter(
      chapterId: 'ch2',
      situation: '評価の段階。どちらの方法を選ぶか。',
      choices: [
        StoryChoice(choiceId: 'a', text: '複数の指標で評価', isRecommended: true, feedback: '正しい。'),
        StoryChoice(choiceId: 'b', text: '正解率だけで評価', isRecommended: false, feedback: '不均衡データでは不十分。'),
      ],
    ),
  ],
  QuestionSource source = QuestionSource.original,
  String sourceRef = '自作',
  String contentVer = '1',
}) =>
    StoryScenario(
      scenarioId: scenarioId,
      examId: examId,
      subjectId: subjectId,
      title: title,
      description: description,
      chapters: chapters,
      source: source,
      sourceRef: sourceRef,
      contentVer: contentVer,
    );

Set<String> codes(List<ContentIssue> issues) => {for (final i in issues) i.code};

void main() {
  test('正しいシナリオは指摘なし', () {
    expect(validateStoryScenarios([scenario()], exam: exam), isEmpty);
  });

  test('scenarioId の重複', () {
    expect(
      codes(validateStoryScenarios([scenario(), scenario()])),
      contains('duplicate-id'),
    );
  });

  group('必須項目', () {
    test('description が空', () {
      expect(
        codes(validateStoryScenarios([scenario(description: ' ')])),
        contains('empty-description'),
      );
    });
    test('sourceRef が空', () {
      expect(
        codes(validateStoryScenarios([scenario(sourceRef: ' ')])),
        contains('no-source'),
      );
    });
    test('contentVer が空', () {
      expect(
        codes(validateStoryScenarios([scenario(contentVer: '')])),
        contains('no-content-ver'),
      );
    });
  });

  group('章', () {
    test('章が1つだけでは不足', () {
      expect(
        codes(validateStoryScenarios([
          scenario(chapters: const [
            StoryChapter(
              chapterId: 'ch1',
              situation: '状況',
              choices: [
                StoryChoice(choiceId: 'a', text: 'A', isRecommended: true, feedback: 'f'),
                StoryChoice(choiceId: 'b', text: 'B', isRecommended: false, feedback: 'f'),
              ],
            ),
          ]),
        ])),
        contains('too-few-chapters'),
      );
    });

    test('chapterId の重複', () {
      expect(
        codes(validateStoryScenarios([
          scenario(chapters: const [
            StoryChapter(
              chapterId: 'ch1',
              situation: '状況1',
              choices: [
                StoryChoice(choiceId: 'a', text: 'A', isRecommended: true, feedback: 'f'),
                StoryChoice(choiceId: 'b', text: 'B', isRecommended: false, feedback: 'f'),
              ],
            ),
            StoryChapter(
              chapterId: 'ch1',
              situation: '状況2',
              choices: [
                StoryChoice(choiceId: 'a', text: 'A', isRecommended: true, feedback: 'f'),
                StoryChoice(choiceId: 'b', text: 'B', isRecommended: false, feedback: 'f'),
              ],
            ),
          ]),
        ])),
        contains('duplicate-chapter-id'),
      );
    });

    test('situation が空', () {
      expect(
        codes(validateStoryScenarios([
          scenario(chapters: [
            StoryChapter(
              chapterId: 'ch1',
              situation: ' ',
              choices: scenario().chapters[0].choices,
            ),
            scenario().chapters[1],
          ]),
        ])),
        contains('empty-situation'),
      );
    });
  });

  group('選択肢', () {
    test('選択肢が1つだけでは不足', () {
      expect(
        codes(validateStoryScenarios([
          scenario(chapters: [
            StoryChapter(
              chapterId: 'ch1',
              situation: '状況',
              choices: const [
                StoryChoice(choiceId: 'a', text: 'A', isRecommended: true, feedback: 'f'),
              ],
            ),
            scenario().chapters[1],
          ]),
        ])),
        contains('too-few-choices'),
      );
    });

    test('choiceId の重複', () {
      expect(
        codes(validateStoryScenarios([
          scenario(chapters: [
            StoryChapter(
              chapterId: 'ch1',
              situation: '状況',
              choices: const [
                StoryChoice(choiceId: 'a', text: 'A', isRecommended: true, feedback: 'f'),
                StoryChoice(choiceId: 'a', text: 'B', isRecommended: false, feedback: 'f'),
              ],
            ),
            scenario().chapters[1],
          ]),
        ])),
        contains('duplicate-choice-id'),
      );
    });

    test('選択肢の文言が空', () {
      expect(
        codes(validateStoryScenarios([
          scenario(chapters: [
            StoryChapter(
              chapterId: 'ch1',
              situation: '状況',
              choices: const [
                StoryChoice(choiceId: 'a', text: ' ', isRecommended: true, feedback: 'f'),
                StoryChoice(choiceId: 'b', text: 'B', isRecommended: false, feedback: 'f'),
              ],
            ),
            scenario().chapters[1],
          ]),
        ])),
        contains('empty-choice-text'),
      );
    });

    test('解説が空', () {
      expect(
        codes(validateStoryScenarios([
          scenario(chapters: [
            StoryChapter(
              chapterId: 'ch1',
              situation: '状況',
              choices: const [
                StoryChoice(choiceId: 'a', text: 'A', isRecommended: true, feedback: ' '),
                StoryChoice(choiceId: 'b', text: 'B', isRecommended: false, feedback: 'f'),
              ],
            ),
            scenario().chapters[1],
          ]),
        ])),
        contains('empty-feedback'),
      );
    });

    test('推奨の選択肢がない', () {
      expect(
        codes(validateStoryScenarios([
          scenario(chapters: [
            StoryChapter(
              chapterId: 'ch1',
              situation: '状況',
              choices: const [
                StoryChoice(choiceId: 'a', text: 'A', isRecommended: false, feedback: 'f'),
                StoryChoice(choiceId: 'b', text: 'B', isRecommended: false, feedback: 'f'),
              ],
            ),
            scenario().chapters[1],
          ]),
        ])),
        contains('no-recommended-choice'),
      );
    });

    test('推奨の選択肢が複数', () {
      expect(
        codes(validateStoryScenarios([
          scenario(chapters: [
            StoryChapter(
              chapterId: 'ch1',
              situation: '状況',
              choices: const [
                StoryChoice(choiceId: 'a', text: 'A', isRecommended: true, feedback: 'f'),
                StoryChoice(choiceId: 'b', text: 'B', isRecommended: true, feedback: 'f'),
              ],
            ),
            scenario().chapters[1],
          ]),
        ])),
        contains('multiple-recommended-choices'),
      );
    });
  });

  test('試験定義との整合', () {
    expect(
      codes(validateStoryScenarios([scenario(examId: 'other')], exam: exam)),
      contains('exam-mismatch'),
    );
    expect(
      codes(validateStoryScenarios([scenario(subjectId: 'zzz')], exam: exam)),
      contains('unknown-subject'),
    );
    expect(
      validateStoryScenarios([scenario(subjectId: null)], exam: exam),
      isEmpty,
    );
  });

  group('JSON Lines の読み込み', () {
    test('壊れた行は行番号つきの issue になり、他の行は読み込まれる', () {
      final good = jsonEncode(scenario().toJson());
      final parsed = parseStoryScenariosJsonl('$good\nこれはJSONではない\n\n[1,2]\n');
      expect(parsed.scenarios, hasLength(1));
      expect(parsed.issues.map((i) => i.qid), ['line:2', 'line:4']);
      expect(parsed.issues.every((i) => i.code == 'parse'), isTrue);
    });
  });
}
