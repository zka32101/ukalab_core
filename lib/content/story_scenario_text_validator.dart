import '../experience/story_mode.dart';
import '../question/question.dart' show QuestionSource;
import 'question_validator.dart' show ContentIssue;

/// 体験型シナリオ（AI下書き）の文章に使わない表現の既定。
/// 公式・本試験の再現・合否の約束と受け取られる語を避ける。
const List<String> kStoryForbiddenWords = ['公式', '本試験相当', '過去問', '合格保証'];

/// シナリオの文章（題名・説明・出典・各章の状況・選択肢と解説）を1つずつ返す。
List<String> storyScenarioTexts(StoryScenario s) => [
      s.title,
      s.description,
      s.sourceRef,
      for (final c in s.chapters) ...[
        c.situation,
        for (final ch in c.choices) ...[ch.text, ch.feedback],
      ],
    ];

/// 体験型シナリオの文章の品質ゲート（純Dart）。
///
/// - 禁止語（[forbiddenWords]）が含まれていれば `forbidden-word`（語ごとに1件）。
/// - [requireOriginalSelfMade] が true なら、`source` が original であること
///   （`not-original`）と、`sourceRef` に「自作」とあること（`no-self-made`）も確かめる。
///
/// 章立て・選択肢の形は [validateStoryScenarios] が検査するので、あわせて呼ぶ。
List<ContentIssue> validateStoryScenarioText(
  List<StoryScenario> scenarios, {
  List<String> forbiddenWords = kStoryForbiddenWords,
  bool requireOriginalSelfMade = false,
}) {
  final issues = <ContentIssue>[];
  for (final s in scenarios) {
    final all = storyScenarioTexts(s).join('\n');
    for (final w in forbiddenWords) {
      if (w.isNotEmpty && all.contains(w)) {
        issues.add(ContentIssue(s.scenarioId, 'forbidden-word', '使わない表現が含まれています: $w'));
      }
    }
    if (requireOriginalSelfMade) {
      if (s.source != QuestionSource.original) {
        issues.add(ContentIssue(
            s.scenarioId, 'not-original', 'source は original(自作)である必要があります'));
      }
      if (!s.sourceRef.contains('自作')) {
        issues.add(ContentIssue(s.scenarioId, 'no-self-made', 'sourceRef に自作である旨がありません'));
      }
    }
  }
  return issues;
}
