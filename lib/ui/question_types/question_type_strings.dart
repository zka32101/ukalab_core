import 'package:app_common_kit/app_common_kit.dart' show KitStrings;
import 'package:flutter/widgets.dart';

/// 新しい問題タイプ（○×・空欄補充・説明から用語）の画面の文言。
///
/// 言語は [KitStrings.languageCode]（`KitStringsScope`）に従う。内蔵は ja・en。それ以外は日本語。
/// 引数で [QuestionTypeStrings] を渡せば、そちらが優先される。
@immutable
class QuestionTypeStrings {
  const QuestionTypeStrings({
    required this.trueMark,
    required this.trueText,
    required this.falseMark,
    required this.falseText,
    required this.submit,
    required this.next,
    required this.resultCorrect,
    required this.resultIncorrect,
    required this.blankCorrect,
    required this.blankIncorrect,
    required this.correctAnswer,
    required this.blankName,
    required this.inputHint,
    required this.composingHint,
    required this.clueTitle,
    required this.selfReport,
    required this.selfReportDone,
  });

  /// ○ ボタンの記号と文言（色だけに頼らず、記号と文字を併記する）。
  final String trueMark;
  final String trueText;
  final String falseMark;
  final String falseText;
  final String submit;
  final String next;
  final String resultCorrect;
  final String resultIncorrect;
  final String blankCorrect;
  final String blankIncorrect;

  /// 「正解: ◯◯」。
  final String Function(String answer) correctAnswer;

  /// 「空欄1」。画面の見出しと読み上げラベルの両方に使う。
  final String Function(int id) blankName;
  final String inputHint;

  /// 変換中（IME 未確定）で解答できないときの案内。
  final String composingHint;
  final String clueTitle;

  /// 自由入力が不正解のときに出す、打ち間違い救済のボタン。
  final String selfReport;
  final String selfReportDone;

  static const ja = QuestionTypeStrings(
    trueMark: '○',
    trueText: '正しい',
    falseMark: '×',
    falseText: '誤り',
    submit: '解答する',
    next: '次へ',
    resultCorrect: '正解です',
    resultIncorrect: '不正解です',
    blankCorrect: '正解',
    blankIncorrect: '不正解',
    correctAnswer: _jaCorrectAnswer,
    blankName: _jaBlankName,
    inputHint: 'ここに入力',
    composingHint: '変換を確定すると解答できます',
    clueTitle: '説明',
    selfReport: '合っていた（自己申告）',
    selfReportDone: '自己申告で正解にしました',
  );

  static const en = QuestionTypeStrings(
    trueMark: 'T',
    trueText: 'True',
    falseMark: 'F',
    falseText: 'False',
    submit: 'Submit',
    next: 'Next',
    resultCorrect: 'Correct',
    resultIncorrect: 'Incorrect',
    blankCorrect: 'Correct',
    blankIncorrect: 'Incorrect',
    correctAnswer: _enCorrectAnswer,
    blankName: _enBlankName,
    inputHint: 'Type your answer',
    composingHint: 'Finish the text conversion to submit',
    clueTitle: 'Description',
    selfReport: 'I was right (self-report)',
    selfReportDone: 'Marked correct by your own report',
  );

  /// [KitStrings.languageCode] に対応する文言。無い言語は日本語。
  static QuestionTypeStrings forLanguageCode(String code) => switch (code) {
    'en' => en,
    _ => ja,
  };

  /// 最も近い `KitStringsScope` の言語に合う文言。無ければ日本語。
  static QuestionTypeStrings of(BuildContext context) =>
      forLanguageCode(KitStrings.of(context).languageCode);
}

String _jaCorrectAnswer(String a) => '正解: $a';
String _enCorrectAnswer(String a) => 'Answer: $a';
String _jaBlankName(int id) => '空欄$id';
String _enBlankName(int id) => 'Blank $id';
