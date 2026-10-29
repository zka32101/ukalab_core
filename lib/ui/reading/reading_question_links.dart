import 'package:flutter/material.dart';

import '../../experience/chapter_reading.dart';
import '../answer_feedback/answer_feedback_strings.dart';
import 'reading_number_wrap.dart';

/// ボタンのラベルを折り返す最大行数。
const int _kLinkMaxLines = 3;

/// 読み物から確認問題へ戻る導線。`ChapterReading.relatedQuestionIds` の問題ごとにボタンを出し、
/// タップで [onOpenQuestion]（qid）を呼ぶ。問題が無ければ何も出さない。
///
/// ボタンの文言は [labels]（qid → 表示名）、無ければ「確認問題 N」。
class ReadingQuestionLinks extends StatelessWidget {
  const ReadingQuestionLinks({
    super.key,
    required this.questionIds,
    required this.onOpenQuestion,
    this.labels = const {},
    this.strings,
  });

  ReadingQuestionLinks.forReading({
    Key? key,
    required ChapterReading reading,
    required ValueChanged<String> onOpenQuestion,
    Map<String, String> labels = const {},
    AnswerFeedbackStrings? strings,
  }) : this(
         key: key,
         questionIds: reading.relatedQuestionIds,
         onOpenQuestion: onOpenQuestion,
         labels: labels,
         strings: strings,
       );

  final List<String> questionIds;
  final ValueChanged<String> onOpenQuestion;
  final Map<String, String> labels;
  final AnswerFeedbackStrings? strings;

  @override
  Widget build(BuildContext context) {
    if (questionIds.isEmpty) return const SizedBox.shrink();
    final s = strings ?? AnswerFeedbackStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            s.readingBackToQuestion,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < questionIds.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: () => onOpenQuestion(questionIds[i]),
              child: Align(
                alignment: Alignment.centerLeft,
                // 最大3行まで折り返し、それでも長いときだけ末尾を省略（数字の途中では切らない）。
                child: readingNumberSafeText(
                  labels[questionIds[i]] ?? s.readingQuestionLabel(i + 1),
                  maxLines: _kLinkMaxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
