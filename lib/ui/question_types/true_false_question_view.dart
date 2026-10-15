import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';

import '../../engine/answer_check.dart';
import '../../progress/progress_record.dart';
import '../../question/question.dart';
import '../../term/term.dart';
import 'question_type_strings.dart';
import 'question_view_common.dart';

/// ○×問題（[QuestionType.trueFalse]）の画面。選ぶとその場で採点し、
/// 解説と間違えた理由（[AnswerFeedbackPanel]）を出す。
///
/// 色だけで判別させない（「○ 正しい」「× 誤り」と記号・文字・アイコンを併記）。
/// ボタンの高さは 48dp 以上で、読み上げは「記号 文言」。
/// 問題が変わるときは `key: ValueKey(question.qid)` を付けるか、qid を変えて再構築する
/// （qid が変わると内部の状態をリセットする）。
class TrueFalseQuestionView extends StatefulWidget {
  TrueFalseQuestionView({
    super.key,
    required this.question,
    required this.onAnswered,
    this.onCause,
    this.terms = const [],
    this.index,
    this.total,
    this.promptWidget,
    this.onNext,
    this.strings,
  }) : assert(question.type == QuestionType.trueFalse);

  final Question question;

  /// 採点した直後に1回呼ぶ。
  final ValueChanged<QuestionViewResult> onAnswered;

  /// 間違えた理由が選ばれた（取り消しは null）ときに呼ぶ。
  final ValueChanged<WrongCause?>? onCause;
  final List<Term> terms;

  /// 「第N問 / M問」の表示用。
  final int? index;
  final int? total;

  /// 問題文の表示の差し替え（用語をタップ可能にするときなど）。
  final Widget? promptWidget;

  /// 渡すと、解答後に「次へ」ボタンを出す。
  final VoidCallback? onNext;
  final QuestionTypeStrings? strings;

  @override
  State<TrueFalseQuestionView> createState() => _TrueFalseQuestionViewState();
}

class _TrueFalseQuestionViewState extends State<TrueFalseQuestionView> {
  bool? _selected;

  @override
  void didUpdateWidget(TrueFalseQuestionView old) {
    super.didUpdateWidget(old);
    if (old.question.qid != widget.question.qid) _selected = null;
  }

  void _answer(bool value) {
    if (_selected != null) return;
    setState(() => _selected = value);
    widget.onAnswered(
      QuestionViewResult(
        correct: judgeTrueFalse(widget.question, value),
        boolAnswer: value,
      ),
    );
  }

  ChoiceState _stateOf(bool tile) {
    final selected = _selected;
    if (selected == null) return ChoiceState.idle;
    final answer = widget.question.answerBool;
    if (tile == answer) return ChoiceState.correct;
    return tile == selected ? ChoiceState.incorrect : ChoiceState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings ?? QuestionTypeStrings.of(context);
    final q = widget.question;
    final selected = _selected;
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
        ChoiceTile(
          label: s.trueMark,
          text: s.trueText,
          state: _stateOf(true),
          onTap: selected == null ? () => _answer(true) : null,
        ),
        const SizedBox(height: 8),
        ChoiceTile(
          label: s.falseMark,
          text: s.falseText,
          state: _stateOf(false),
          onTap: selected == null ? () => _answer(false) : null,
        ),
        if (selected != null)
          QuestionAnsweredSection(
            question: q,
            correct: judgeTrueFalse(q, selected),
            strings: s,
            terms: widget.terms,
            onCause: widget.onCause ?? (_) {},
            onNext: widget.onNext,
          ),
      ],
    );
  }
}
