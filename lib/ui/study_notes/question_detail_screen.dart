import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';

import '../../engine/answer_check.dart';
import '../../engine/question_display.dart';
import '../../question/question.dart';

/// 選択肢の記号の既定（五肢択一まで）。
const defaultChoiceLabels = ['ア', 'イ', 'ウ', 'エ', 'オ'];

/// 検索結果・メモ一覧などから開く、1問だけの読み取り専用の詳細表示。
/// 選んで答える演習ではなく、正解をそのまま示す。
/// 解説の用語をタップ可能にしたいときは [explanationBuilder] で本文の表示を差し替える。
class QuestionDetailScreen extends StatelessWidget {
  const QuestionDetailScreen({
    super.key,
    required this.question,
    this.choiceLabels = defaultChoiceLabels,
    this.explanationBuilder,
  });

  final Question question;
  final List<String> choiceLabels;

  /// 解説本文の差し替え。null なら本文をそのまま出す。
  final Widget? Function(BuildContext context, Question question)? explanationBuilder;

  @override
  Widget build(BuildContext context) {
    final q = question;
    return Scaffold(
      appBar: AppBar(title: const Text('問題の詳細')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          QuestionCard(
            text: q.type == QuestionType.cloze ? q.displayPrompt : q.prompt,
            index: 1,
            total: 1,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < q.choices.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChoiceTile(
                label: i < choiceLabels.length ? choiceLabels[i] : '${i + 1}',
                text: q.choices[i],
                state:
                    (q.type == QuestionType.reverseLookup
                        ? answerMatches(q.choices[i], q.answers)
                        : i == q.answerIndex)
                    ? ChoiceState.correct
                    : ChoiceState.idle,
                onTap: null,
              ),
            ),
          if (_answerSummary(q) case final summary?) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  summary,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          ExplanationPanel(
            body: q.explanation,
            sourceRef: q.sourceRef,
            bodyWidget: explanationBuilder?.call(context, q),
          ),
        ],
      ),
    );
  }
}

/// 選択肢で示せない型（○×・空欄補充・自由入力の説明から用語）の正解の要約。
String? _answerSummary(Question q) => switch (q.type) {
  QuestionType.trueFalse => '正解: ${q.answerBool == true ? '○ 正しい' : '× 誤り'}',
  QuestionType.cloze => [
    for (final b in q.blanks) '空欄${b.id}: ${b.answers.join(' / ')}',
  ].join('\n'),
  QuestionType.reverseLookup when q.choices.isEmpty =>
    '説明: ${q.clue ?? ''}\n正解: ${q.answers.join(' / ')}',
  QuestionType.reverseLookup => '説明: ${q.clue ?? ''}',
  _ => null,
};
