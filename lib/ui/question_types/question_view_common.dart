import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';

import '../../progress/progress_record.dart';
import '../../question/question.dart';
import '../../term/term.dart';
import '../answer_feedback/answer_feedback_panel.dart';
import 'question_type_strings.dart';

/// 新しい問題タイプの画面が、解答時に返す結果。
@immutable
class QuestionViewResult {
  const QuestionViewResult({
    required this.correct,
    this.boolAnswer,
    this.blankAnswers,
    this.text,
  });

  /// 採点結果。
  final bool correct;

  /// ○×で選んだ値。
  final bool? boolAnswer;

  /// 空欄補充の入力（空欄番号 → 入力。選択式の空欄は選んだ選択肢の文字列）。
  final Map<int, String>? blankAnswers;

  /// 説明から用語の入力（または選んだ選択肢の文字列）。
  final String? text;
}

/// 解答後に出す共通部分: 結果の帯（アイコン＋文字）→ 正解 → 自己申告 → 解説 →
/// 間違えた理由（[AnswerFeedbackPanel]）→ 次へ。内部用。
class QuestionAnsweredSection extends StatelessWidget {
  const QuestionAnsweredSection({
    super.key,
    required this.question,
    required this.correct,
    required this.strings,
    required this.onCause,
    required this.terms,
    this.correctAnswerText,
    this.selfReported = false,
    this.onSelfReport,
    this.onNext,
  });

  final Question question;
  final bool correct;
  final QuestionTypeStrings strings;
  final ValueChanged<WrongCause?> onCause;
  final List<Term> terms;

  /// 不正解のときに示す正解の文字列。
  final String? correctAnswerText;
  final bool selfReported;

  /// 自己申告ボタン。null なら出さない。
  final VoidCallback? onSelfReport;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        ResultBanner(correct: correct, strings: strings),
        if (selfReported)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              strings.selfReportDone,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (!correct && correctAnswerText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              strings.correctAnswer(correctAnswerText!),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        if (!correct && onSelfReport != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                onPressed: onSelfReport,
                child: Text(strings.selfReport),
              ),
            ),
          ),
        const SizedBox(height: 12),
        ExplanationPanel(
          body: question.explanation,
          sourceRef: question.sourceRef,
        ),
        const SizedBox(height: 12),
        AnswerFeedbackPanel(
          question: question,
          selectedIndex: null,
          isCorrect: correct,
          includeCalculation: false,
          terms: terms,
          onCause: onCause,
        ),
        if (onNext != null) ...[
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: onNext,
            child: Text(strings.next),
          ),
        ],
      ],
    );
  }
}

/// 正誤の帯。色だけに頼らず、アイコンと文字を併記し、読み上げ（liveRegion）にも出す。
class ResultBanner extends StatelessWidget {
  const ResultBanner({super.key, required this.correct, required this.strings});

  final bool correct;
  final QuestionTypeStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final color = correct
        ? (dark ? const Color(0xFF5BD17F) : const Color(0xFF1E8E3E))
        : theme.colorScheme.error;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Row(
        children: [
          Icon(correct ? Icons.check_circle : Icons.cancel, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              correct ? strings.resultCorrect : strings.resultIncorrect,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 自由入力欄。入力の候補表示・自動修正・自動入力は使わない（用語を思い出す練習のため）。
/// 変換中（IME 未確定）かどうかは [isComposing] で調べる。
class AnswerTextField extends StatelessWidget {
  const AnswerTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.readOnly = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;

  /// 欄の名前（読み上げにも使う）。
  final String label;
  final String hint;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  /// 変換中（未確定の文字がある）か。確定してから判定する。
  static bool isComposing(TextEditingController c) {
    final r = c.value.composing;
    return r.isValid && !r.isCollapsed;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
