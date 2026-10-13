import 'package:app_common_kit/app_common_kit.dart' show KitStrings;
import 'package:flutter/material.dart';

import '../../engine/mock_exam_analysis_engine.dart';
import '../../engine/mock_exam_analysis_strings.dart';
import 'mock_exam_analysis_card.dart';

/// 模擬試験の結果分析画面。アプリは分野名と回答リストを渡すだけでよい。
///
/// ```dart
/// MockExamAnalysisScreen(
///   answers: [for (final q in result) MockExamAnswer(topicId: q.chapter, correct: q.ok)],
///   topicLabel: (id) => chapterNames[id] ?? id,
/// )
/// ```
class MockExamAnalysisScreen extends StatelessWidget {
  const MockExamAnalysisScreen({
    super.key,
    required this.answers,
    this.topicLabel,
    this.strings,
    this.engine = const MockExamAnalysisEngine(),
  });

  final List<MockExamAnswer> answers;
  final String Function(String topicId)? topicLabel;
  final MockExamAnalysisStrings? strings;
  final MockExamAnalysisEngine engine;

  @override
  Widget build(BuildContext context) {
    final analysis = engine.analyze(answers);
    final s = strings ?? MockExamAnalysisStrings.forLanguageCode(KitStrings.of(context).languageCode);
    return Scaffold(
      appBar: AppBar(title: Text(s.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: MockExamAnalysisCard(analysis: analysis, strings: s, topicLabel: topicLabel),
        ),
      ),
    );
  }
}
