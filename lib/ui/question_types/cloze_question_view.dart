import 'package:app_common_kit/app_common_kit.dart';
import '../../learning.dart';
import 'package:flutter/material.dart';

import '../../engine/answer_check.dart';
import '../../progress/progress_record.dart';
import '../../question/question.dart';
import '../../term/term.dart';
import 'question_type_strings.dart';
import 'question_view_common.dart';

/// 空欄補充（[QuestionType.cloze]）の画面。prompt の `{{n}}` を枠つきの番号で示し、
/// 空欄ごとの入力欄（選択肢つきの空欄は選択肢）を下に並べる。全空欄が正解のときだけ正解
/// （部分点なし。空欄ごとの正誤は表示する）。
///
/// - 空欄は `Semantics(label: '空欄n')` つき。折り返しレイアウトなので文字を大きくしても崩れない。
/// - 自由入力は IME の変換中は解答できない（確定してから判定）。
/// - 自由入力が不正解のとき、「合っていた（自己申告）」で打ち間違いを救済できる
///   （[onSelfReported]）。
class ClozeQuestionView extends StatefulWidget {
  ClozeQuestionView({
    super.key,
    required this.question,
    required this.onAnswered,
    this.onSelfReported,
    this.onCause,
    this.terms = const [],
    this.index,
    this.total,
    this.onNext,
    this.strings,
  }) : assert(question.type == QuestionType.cloze);

  final Question question;

  /// 採点した直後に1回呼ぶ。
  final ValueChanged<QuestionViewResult> onAnswered;

  /// 自己申告で正解に直したときに呼ぶ（`PracticeSession.markLastSelfReportedCorrect` に繋ぐ）。
  final VoidCallback? onSelfReported;
  final ValueChanged<WrongCause?>? onCause;
  final List<Term> terms;
  final int? index;
  final int? total;
  final VoidCallback? onNext;
  final QuestionTypeStrings? strings;

  @override
  State<ClozeQuestionView> createState() => _ClozeQuestionViewState();
}

class _ClozeQuestionViewState extends State<ClozeQuestionView> {
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, String> _picked = {};
  ClozeJudgeResult? _result;
  bool _selfReported = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void didUpdateWidget(ClozeQuestionView old) {
    super.didUpdateWidget(old);
    if (old.question.qid != widget.question.qid) {
      _teardown();
      _picked.clear();
      _result = null;
      _selfReported = false;
      _setup();
    }
  }

  void _setup() {
    for (final b in widget.question.blanks) {
      if (!b.hasChoices) {
        _controllers[b.id] = TextEditingController()..addListener(_onChanged);
      }
    }
  }

  void _teardown() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
  }

  @override
  void dispose() {
    _teardown();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  bool get _answered => _result != null;

  String _valueOf(ClozeBlank b) =>
      b.hasChoices ? (_picked[b.id] ?? '') : (_controllers[b.id]?.text ?? '');

  bool get _composing => _controllers.values.any(AnswerTextField.isComposing);

  bool get _canSubmit =>
      !_answered &&
      !_composing &&
      widget.question.blanks.every(
        (b) => normalizeAnswerText(_valueOf(b)).isNotEmpty,
      );

  bool get _hasFreeInput => widget.question.blanks.any((b) => !b.hasChoices);

  void _submit() {
    if (!_canSubmit) return;
    final inputs = {for (final b in widget.question.blanks) b.id: _valueOf(b)};
    final result = judgeCloze(widget.question, inputs);
    setState(() => _result = result);
    widget.onAnswered(
      QuestionViewResult(correct: result.isCorrect, blankAnswers: inputs),
    );
  }

  void _selfReport() {
    setState(() => _selfReported = true);
    widget.onSelfReported?.call();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings ?? QuestionTypeStrings.of(context);
    final q = widget.question;
    final theme = Theme.of(context);
    final result = _result;
    final correct = (result?.isCorrect ?? false) || _selfReported;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuestionCard(
          text: q.prompt,
          textWidget: Text.rich(_promptSpan(context, s)),
          index: widget.index,
          total: widget.total,
        ),
        const SizedBox(height: 12),
        for (final b in q.blanks) ...[
          _blankSection(context, b, s, theme),
          const SizedBox(height: 12),
        ],
        if (!_answered) ...[
          if (_composing)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(s.composingHint, style: theme.textTheme.bodySmall),
            ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: _canSubmit ? _submit : null,
            child: Text(s.submit),
          ),
        ] else
          QuestionAnsweredSection(
            question: q,
            correct: correct,
            strings: s,
            terms: widget.terms,
            onCause: widget.onCause ?? (_) {},
            selfReported: _selfReported,
            onSelfReport: _hasFreeInput && !_selfReported ? _selfReport : null,
            onNext: widget.onNext,
          ),
      ],
    );
  }

  /// prompt の `{{n}}` を、番号つきの枠（読み上げは「空欄n」）にした本文。
  InlineSpan _promptSpan(BuildContext context, QuestionTypeStrings s) {
    final theme = Theme.of(context);
    return TextSpan(
      children: [
        for (final seg in splitClozePrompt(widget.question.prompt))
          if (seg.isBlank)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Semantics(
                label: s.blankName(seg.blankId!),
                excludeSemantics: true,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${seg.blankId}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            )
          else
            TextSpan(text: seg.text),
      ],
    );
  }

  Widget _blankSection(
    BuildContext context,
    ClozeBlank b,
    QuestionTypeStrings s,
    ThemeData theme,
  ) {
    final result = _result;
    final ok = result?.blanks[b.id];
    final shownOk =
        ok == true || (_selfReported && ok == false && !b.hasChoices);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(s.blankName(b.id), style: theme.textTheme.titleSmall),
            ),
            if (ok != null) ...[
              Icon(
                shownOk ? Icons.check_circle : Icons.cancel,
                size: 20,
                color: shownOk
                    ? const Color(0xFF1E8E3E)
                    : theme.colorScheme.error,
              ),
              const SizedBox(width: 4),
              Text(
                shownOk ? s.blankCorrect : s.blankIncorrect,
                style: theme.textTheme.labelMedium,
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        if (b.hasChoices)
          for (var i = 0; i < b.choices.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChoiceTile(
                label: '${i + 1}',
                text: b.choices[i],
                state: _choiceState(b, b.choices[i]),
                onTap: _answered
                    ? null
                    : () => setState(() => _picked[b.id] = b.choices[i]),
              ),
            )
        else
          AnswerTextField(
            controller: _controllers[b.id]!,
            label: s.blankName(b.id),
            hint: s.inputHint,
            readOnly: _answered,
            textInputAction: TextInputAction.next,
          ),
        if (_answered && ok == false && !_selfReported)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              s.correctAnswer(b.answers.first),
              style: theme.textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }

  ChoiceState _choiceState(ClozeBlank b, String choice) {
    final picked = _picked[b.id];
    if (!_answered)
      return picked == choice ? ChoiceState.selected : ChoiceState.idle;
    if (answerMatches(choice, b.answers)) return ChoiceState.correct;
    return picked == choice ? ChoiceState.incorrect : ChoiceState.idle;
  }
}
