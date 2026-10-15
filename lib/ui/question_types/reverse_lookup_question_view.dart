import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';

import '../../engine/answer_check.dart';
import '../../progress/progress_record.dart';
import '../../question/question.dart';
import '../../term/term.dart';
import 'question_type_strings.dart';
import 'question_view_common.dart';

/// 説明から用語を当てる問題（[QuestionType.reverseLookup]）の画面。説明文（`clue`）を示し、
/// 選択肢つき（`choices` あり）なら選ぶとその場で採点、自由入力なら入力して「解答する」で採点する。
///
/// - 自由入力は IME の変換中は解答できない（確定してから判定）。
/// - 自由入力が不正解のとき、「合っていた（自己申告）」で打ち間違いを救済できる
///   （[onSelfReported]）。
class ReverseLookupQuestionView extends StatefulWidget {
  ReverseLookupQuestionView({
    super.key,
    required this.question,
    required this.onAnswered,
    this.onSelfReported,
    this.onCause,
    this.terms = const [],
    this.index,
    this.total,
    this.promptWidget,
    this.onNext,
    this.strings,
  }) : assert(question.type == QuestionType.reverseLookup);

  final Question question;

  /// 採点した直後に1回呼ぶ。
  final ValueChanged<QuestionViewResult> onAnswered;

  /// 自己申告で正解に直したときに呼ぶ（`PracticeSession.markLastSelfReportedCorrect` に繋ぐ）。
  final VoidCallback? onSelfReported;
  final ValueChanged<WrongCause?>? onCause;
  final List<Term> terms;
  final int? index;
  final int? total;
  final Widget? promptWidget;
  final VoidCallback? onNext;
  final QuestionTypeStrings? strings;

  @override
  State<ReverseLookupQuestionView> createState() =>
      _ReverseLookupQuestionViewState();
}

class _ReverseLookupQuestionViewState extends State<ReverseLookupQuestionView> {
  final _controller = TextEditingController();
  String? _answer; // 解答済みなら入力（または選んだ選択肢）
  bool _selfReported = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(ReverseLookupQuestionView old) {
    super.didUpdateWidget(old);
    if (old.question.qid != widget.question.qid) {
      _controller.clear();
      _answer = null;
      _selfReported = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasChoices => widget.question.choices.isNotEmpty;
  bool get _answered => _answer != null;
  bool get _composing => AnswerTextField.isComposing(_controller);
  bool get _canSubmit =>
      !_answered &&
      !_composing &&
      normalizeAnswerText(_controller.text).isNotEmpty;

  void _answerWith(String text) {
    if (_answered) return;
    setState(() => _answer = text);
    widget.onAnswered(
      QuestionViewResult(
        correct: judgeReverseLookup(widget.question, text),
        text: text,
      ),
    );
  }

  void _selfReport() {
    setState(() => _selfReported = true);
    widget.onSelfReported?.call();
  }

  ChoiceState _choiceState(String choice) {
    if (!_answered) return ChoiceState.idle;
    if (answerMatches(choice, widget.question.answers))
      return ChoiceState.correct;
    return _answer == choice ? ChoiceState.incorrect : ChoiceState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings ?? QuestionTypeStrings.of(context);
    final q = widget.question;
    final theme = Theme.of(context);
    final answer = _answer;
    final correct =
        (answer != null && judgeReverseLookup(q, answer)) || _selfReported;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuestionCard(
          text: q.prompt,
          textWidget: widget.promptWidget,
          index: widget.index,
          total: widget.total,
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.clueTitle, style: theme.textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(q.clue ?? '', style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_hasChoices)
          for (var i = 0; i < q.choices.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChoiceTile(
                label: '${i + 1}',
                text: q.choices[i],
                state: _choiceState(q.choices[i]),
                onTap: _answered ? null : () => _answerWith(q.choices[i]),
              ),
            )
        else ...[
          AnswerTextField(
            controller: _controller,
            label: q.prompt,
            hint: s.inputHint,
            readOnly: _answered,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (_canSubmit) _answerWith(_controller.text);
            },
          ),
          if (!_answered) ...[
            const SizedBox(height: 8),
            if (_composing)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(s.composingHint, style: theme.textTheme.bodySmall),
              ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: _canSubmit
                  ? () => _answerWith(_controller.text)
                  : null,
              child: Text(s.submit),
            ),
          ],
        ],
        if (_answered)
          QuestionAnsweredSection(
            question: q,
            correct: correct,
            strings: s,
            terms: widget.terms,
            onCause: widget.onCause ?? (_) {},
            correctAnswerText: _hasChoices ? null : q.answers.first,
            selfReported: _selfReported,
            onSelfReport: !_hasChoices && !_selfReported ? _selfReport : null,
            onNext: widget.onNext,
          ),
      ],
    );
  }
}
