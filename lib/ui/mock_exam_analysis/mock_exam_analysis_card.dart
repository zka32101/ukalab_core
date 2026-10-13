import 'package:app_common_kit/app_common_kit.dart' show KitStrings;
import 'package:flutter/material.dart';

import '../../engine/mock_exam_analysis_engine.dart';
import '../../engine/mock_exam_analysis_strings.dart';

/// 模擬試験の結果分析カード。分野別の様子・伸びしろのある分野・「今日はここを少しだけ」（上位1〜3）を見せる。
///
/// 赤などの警告色・順位・「不合格」的な表現は使わない。文言は [strings]、無ければ
/// `KitStringsScope` の言語（ja・en。他は日本語）。分野名は [topicLabel]（省略時はIDそのまま）。
class MockExamAnalysisCard extends StatelessWidget {
  const MockExamAnalysisCard({
    super.key,
    required this.analysis,
    this.strings,
    this.topicLabel,
  });

  final MockExamAnalysis analysis;
  final MockExamAnalysisStrings? strings;
  final String Function(String topicId)? topicLabel;

  /// 読み上げ用の要約。
  static String summaryOf(
    MockExamAnalysis a,
    MockExamAnalysisStrings s, {
    String Function(String topicId)? topicLabel,
  }) {
    final label = topicLabel ?? (String id) => id;
    if (a.isEmpty) return '${s.title}。${s.emptyTitle}。${s.emptyBody}';
    return [
      s.title,
      '${s.summaryLabel} ${a.answered}${s.questionsUnit}、${a.correct}${s.correctUnit}',
      if (a.nextTopics.isEmpty)
        s.allGoodBody
      else
        '${s.nextLabel} ${a.nextTopics.map((t) => label(t.topicId)).join(', ')}',
    ].join('。');
  }

  @override
  Widget build(BuildContext context) {
    final s = strings ??
        MockExamAnalysisStrings.forLanguageCode(KitStrings.of(context).languageCode);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final label = topicLabel ?? (String id) => id;
    final a = analysis;

    final children = a.isEmpty
        ? <Widget>[
            Text(s.emptyTitle, style: text.titleMedium),
            const SizedBox(height: 4),
            Text(s.emptyBody, style: text.bodyMedium),
          ]
        : <Widget>[
            Text(
              '${s.summaryLabel} ${a.answered}${s.questionsUnit}（${a.correct}${s.correctUnit}）',
              style: text.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(s.byTopicLabel, style: text.titleMedium),
            const SizedBox(height: 8),
            for (final t in a.topics) _TopicRow(score: t, name: label(t.topicId), s: s),
            if (a.weakTopics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(s.growLabel, style: text.titleMedium),
              const SizedBox(height: 4),
              Text(a.weakTopics.map((t) => label(t.topicId)).join('、'), style: text.bodyMedium),
            ],
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.nextLabel,
                        style: text.titleMedium?.copyWith(color: scheme.onPrimaryContainer)),
                    const SizedBox(height: 4),
                    if (a.nextTopics.isEmpty)
                      Text(s.allGoodBody,
                          style: text.bodyMedium?.copyWith(color: scheme.onPrimaryContainer))
                    else ...[
                      Text(s.nextLead,
                          style: text.bodyMedium?.copyWith(color: scheme.onPrimaryContainer)),
                      const SizedBox(height: 4),
                      for (final t in a.nextTopics)
                        Text('・${label(t.topicId)}',
                            style: text.bodyLarge?.copyWith(color: scheme.onPrimaryContainer)),
                    ],
                  ],
                ),
              ),
            ),
          ];

    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          container: true,
          label: summaryOf(a, s, topicLabel: topicLabel),
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.title, style: text.titleLarge),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.score, required this.name, required this.s});

  final MockExamTopicScore score;
  final String name;
  final MockExamAnalysisStrings s;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: text.bodyMedium),
          const SizedBox(height: 2),
          Text(
            '${score.answered}${s.questionsUnit}中 ${score.correct}${s.correctUnit}',
            style: text.bodySmall,
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: score.accuracy, minHeight: 8),
          ),
        ],
      ),
    );
  }
}
