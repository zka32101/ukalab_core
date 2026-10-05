import 'dart:convert';

import '../config/exam_config.dart';
import '../experience/story_mode.dart';
import 'question_validator.dart' show ContentIssue;

class ParsedStoryScenarios {
  const ParsedStoryScenarios(this.scenarios, this.issues);

  final List<StoryScenario> scenarios;

  /// 読み込み（JSON 構文・必須項目）で見つかった問題。
  final List<ContentIssue> issues;
}

/// JSON Lines（1行1シナリオ）を読む。読めない行は [ParsedStoryScenarios.issues]
/// に入れて続行する。
ParsedStoryScenarios parseStoryScenariosJsonl(String text) {
  final scenarios = <StoryScenario>[];
  final issues = <ContentIssue>[];
  final lines = const LineSplitter().convert(text);
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('//')) continue;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('1行は JSON オブジェクトが必要です');
      }
      scenarios.add(StoryScenario.fromJson(decoded));
    } on FormatException catch (e) {
      issues.add(ContentIssue('line:${i + 1}', 'parse', e.message));
    }
  }
  return ParsedStoryScenarios(scenarios, issues);
}

/// 配信前の品質ゲート。章立て・選択肢の形が体験として成立しているかを
/// 検査する。
///
/// [exam] を渡すと、examId・subjectId が試験定義と整合するかも検査する。
List<ContentIssue> validateStoryScenarios(
  List<StoryScenario> scenarios, {
  ExamConfig? exam,
}) {
  final issues = <ContentIssue>[];
  void add(StoryScenario s, String code, String message) =>
      issues.add(ContentIssue(s.scenarioId, code, message));

  final seenIds = <String>{};
  for (final s in scenarios) {
    if (!seenIds.add(s.scenarioId)) {
      add(s, 'duplicate-id', 'scenarioId が重複しています');
    }

    if (s.description.trim().isEmpty) {
      add(s, 'empty-description', 'シナリオの説明(description)が空です');
    }
    if (s.sourceRef.trim().isEmpty) add(s, 'no-source', '出典の説明がありません');
    if (s.contentVer.trim().isEmpty) add(s, 'no-content-ver', 'contentVer がありません');

    if (s.chapters.length < 2) {
      add(s, 'too-few-chapters', 'chapters は2章以上必要です');
    }

    final chapterIds = <String>{};
    for (final chapter in s.chapters) {
      if (!chapterIds.add(chapter.chapterId)) {
        add(s, 'duplicate-chapter-id', 'chapterId が重複しています: ${chapter.chapterId}');
      }
      if (chapter.situation.trim().isEmpty) {
        add(s, 'empty-situation', '章の状況説明(situation)が空です: ${chapter.chapterId}');
      }

      if (chapter.choices.length < 2) {
        add(s, 'too-few-choices', 'choices は2つ以上必要です: ${chapter.chapterId}');
      }
      final choiceIds = chapter.choices.map((c) => c.choiceId).toSet();
      if (choiceIds.length != chapter.choices.length) {
        add(s, 'duplicate-choice-id', 'choices の choiceId が重複しています: ${chapter.chapterId}');
      }
      for (final c in chapter.choices) {
        if (c.text.trim().isEmpty) {
          add(s, 'empty-choice-text', 'choices の文言が空です: ${chapter.chapterId}/${c.choiceId}');
        }
        if (c.feedback.trim().isEmpty) {
          add(s, 'empty-feedback', 'choices の解説(feedback)が空です: ${chapter.chapterId}/${c.choiceId}');
        }
      }
      final recommendedCount = chapter.choices.where((c) => c.isRecommended).length;
      if (recommendedCount == 0) {
        add(s, 'no-recommended-choice', '章に推奨の選択肢がありません: ${chapter.chapterId}');
      } else if (recommendedCount > 1) {
        add(s, 'multiple-recommended-choices', '章の推奨の選択肢が複数あります: ${chapter.chapterId}');
      }
    }

    if (exam != null) {
      if (s.examId != exam.examId) {
        add(s, 'exam-mismatch', 'examId(${s.examId}) が試験(${exam.examId})と一致しません');
      }
      final subjectId = s.subjectId;
      if (subjectId != null && exam.subject(subjectId) == null) {
        add(s, 'unknown-subject', '未定義の subjectId: $subjectId');
      }
    }
  }
  return issues;
}
