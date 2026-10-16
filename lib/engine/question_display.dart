import '../question/question.dart';

final _clozePlaceholder = RegExp(r'\{\{\d+\}\}');

/// 一覧表示（ブックマーク・メモ・タグ編集など）用の問題テキスト。
///
/// - choice / trueFalse / journal / worksheet / ledger: `prompt`
/// - cloze: `prompt` 中の `{{n}}` を「◯」に置き換えたもの
/// - reverseLookup: `clue`（空なら `prompt`）
///
/// 既存の `Question` の項目・JSON は変えない（拡張メソッドのみの追加）。
extension QuestionDisplay on Question {
  String get displayPrompt {
    switch (type) {
      case QuestionType.cloze:
        return prompt.replaceAll(_clozePlaceholder, '◯');
      case QuestionType.reverseLookup:
        final c = clue;
        return (c == null || c.trim().isEmpty) ? prompt : c;
      case QuestionType.choice:
      case QuestionType.journal:
      case QuestionType.worksheet:
      case QuestionType.ledger:
      case QuestionType.trueFalse:
        return prompt;
    }
  }
}
