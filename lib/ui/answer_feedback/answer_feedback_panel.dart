import 'package:flutter/material.dart';

import '../../experience/chapter_reading.dart';
import '../../experience/comparison_view.dart';
import '../../progress/progress_record.dart';
import '../../progress/weak_topics.dart';
import '../../question/question.dart';
import '../../term/term.dart';
import 'answer_feedback_strings.dart';
import 'comparison_card.dart';
import 'wrong_cause_selector.dart';

/// 解答後に置く統合ウィジェット。不正解のときだけ、次を出す（正解のときは何も出さない）。
///
/// 1. 間違えた理由の選択（[WrongCauseSelector]、任意）
/// 2. 違いの比較表示（問題に `compareWith` があり、[terms] から作れるときだけ）
/// 3. 選んだ理由に応じた対策の一言（[prescriptionFor]）
///
/// アプリは解答後の画面に置き、[onCause] で原因ラベルを履歴に反映するだけでよい
/// （履歴への反映は `attachCauseToLatest`）。
class AnswerFeedbackPanel extends StatefulWidget {
  const AnswerFeedbackPanel({
    super.key,
    required this.question,
    required this.selectedIndex,
    required this.onCause,
    this.terms = const [],
    this.isCorrect,
    this.includeCalculation = true,
    this.strings,
    this.relatedReadings = const [],
    this.onOpenReading,
  });

  /// 解答した問題。
  final Question question;

  /// 選んだ選択肢の番号（[Question.choices] の元の並びでの番号。選択肢を並べ替えて
  /// 表示しているときは、元の番号に直して渡す）。選択式でない問題は null にして [isCorrect] を渡す。
  final int? selectedIndex;

  /// 原因ラベルが選ばれた（取り消しは null）ときに呼ぶ。
  final ValueChanged<WrongCause?> onCause;

  /// 比較表示の元になる用語データ。空なら比較表示は出さない。
  final List<Term> terms;

  /// 正誤。省略時は `selectedIndex == question.answerIndex`。
  final bool? isCorrect;

  /// false なら「計算ミス」を選択肢に出さない。
  final bool includeCalculation;

  final AnswerFeedbackStrings? strings;

  /// 誤答のときに「読み物でおさらい」として出す読み物（`disabled` は出さない）。
  /// 問題から探すには `readingsForQuestion` が使える。空なら従来と同じ表示。
  final List<ChapterReading> relatedReadings;

  /// 読み物がタップされたときに呼ぶ。null なら読み物の欄は出さない。
  final ValueChanged<ChapterReading>? onOpenReading;

  @override
  State<AnswerFeedbackPanel> createState() => _AnswerFeedbackPanelState();
}

class _AnswerFeedbackPanelState extends State<AnswerFeedbackPanel> {
  WrongCause? _cause;

  bool get _correct =>
      widget.isCorrect ??
      (widget.selectedIndex != null &&
          widget.selectedIndex == widget.question.answerIndex);

  @override
  void didUpdateWidget(AnswerFeedbackPanel old) {
    super.didUpdateWidget(old);
    if (old.question.qid != widget.question.qid) _cause = null;
  }

  void _select(WrongCause? cause) {
    setState(() => _cause = cause);
    widget.onCause(cause);
  }

  @override
  Widget build(BuildContext context) {
    if (_correct) return const SizedBox.shrink();
    final s = widget.strings ?? AnswerFeedbackStrings.of(context);
    final theme = Theme.of(context);
    final comparison = buildComparison(widget.question, widget.terms);
    final cause =
        (!widget.includeCalculation && _cause == WrongCause.calculation)
        ? null
        : _cause;
    final prescription = prescriptionFor(cause);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: WrongCauseSelector(
              selected: cause,
              includeCalculation: widget.includeCalculation,
              strings: s,
              onSelected: _select,
            ),
          ),
        ),
        if (comparison != null) ...[
          const SizedBox(height: 12),
          ComparisonCard(view: comparison, strings: s),
        ],
        if (prescription != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.prescriptionTitle,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(s.prescriptionText(prescription)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        ..._readingLinks(context, s, theme),
      ],
    );
  }

  List<Widget> _readingLinks(
    BuildContext context,
    AnswerFeedbackStrings s,
    ThemeData theme,
  ) {
    final onOpen = widget.onOpenReading;
    final readings = [
      for (final r in widget.relatedReadings)
        if (!r.disabled) r,
    ];
    if (onOpen == null || readings.isEmpty) return const [];
    return [
      const SizedBox(height: 12),
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_outlined, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.relatedReadingsTitle,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              for (final r in readings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: OutlinedButton(
                    onPressed: () => onOpen(r),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(r.title),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ];
  }
}
