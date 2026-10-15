import '../question/question.dart';

/// 新しい問題タイプ（○× / 空欄補充 / 説明から用語）の採点。純 Dart。
/// `journal_judge.dart` と同じ位置づけ。設計は docs/multi_angle_questions_design.md §2.2。

/// 自由入力の比較用に文字列を正規化する。
///
/// NFKC の完全実装ではなく、入力で現実に起きる揺れに絞る。
/// - 全角英数・記号（U+FF01〜FF5E）→ 半角。全角スペース → 空白
/// - 半角カタカナ → 全角カタカナ（濁点・半濁点は直前の文字と合成）
/// - 空白（全角含む）・ゼロ幅文字・中黒類（`・ ･ · • ‧ ⋅`）を取り除く
/// - ハイフン類（`- ‐ ‑ ‒ – — ― − ─`）は、直前がカタカナ・長音なら長音「ー」、
///   それ以外は半角 `-` にそろえる（「ストレ-ジ」と「ストレージ」を同一視）
/// - 英字は小文字化
///
/// ひらがな/カタカナは**同一視しない**（用語の綴りを問うため）。
/// 空文字になる入力は何にも一致しない（[answerMatches]）。
String normalizeAnswerText(String input) {
  final mapped = <int>[];
  final runes = input.runes.toList();
  for (var i = 0; i < runes.length; i++) {
    var r = runes[i];
    if (r >= 0xFF01 && r <= 0xFF5E) {
      mapped.add(r - 0xFEE0);
    } else if (r == 0x3000) {
      mapped.add(0x20);
    } else if (r >= 0xFF61 && r <= 0xFF9F) {
      if (r == 0xFF9E) {
        mapped.add(0x309B);
      } else if (r == 0xFF9F) {
        mapped.add(0x309C);
      } else {
        var full = _halfwidthKana.codeUnitAt(r - 0xFF61);
        if (i + 1 < runes.length) {
          final next = runes[i + 1];
          if (next == 0xFF9E &&
              _voicedBase.contains(String.fromCharCode(full))) {
            full = full == 0x30A6 ? 0x30F4 : full + 1;
            i++;
          } else if (next == 0xFF9F &&
              _semiVoicedBase.contains(String.fromCharCode(full))) {
            full += 2;
            i++;
          }
        }
        mapped.add(full);
      }
    } else {
      mapped.add(r);
    }
  }

  final out = <int>[];
  for (final r in mapped) {
    if (_isDropped(r)) continue;
    if (_isDash(r)) {
      out.add(out.isNotEmpty && _isKatakana(out.last) ? 0x30FC : 0x2D);
      continue;
    }
    out.add(r);
  }
  return String.fromCharCodes(out).toLowerCase();
}

/// 半角カナ（U+FF61〜FF9D）→ 全角の対応表。
const _halfwidthKana =
    '。「」、・ヲァィゥェォャュョッーアイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン';
const _voicedBase = 'ウカキクケコサシスセソタチツテトハヒフヘホ';
const _semiVoicedBase = 'ハヒフヘホ';

bool _isDropped(int r) =>
    r == 0x20 ||
    (r >= 0x09 && r <= 0x0D) ||
    r == 0xA0 ||
    r == 0x2028 ||
    r == 0x2029 ||
    (r >= 0x200B && r <= 0x200D) ||
    r == 0xFEFF ||
    r == 0x30FB ||
    r == 0xB7 ||
    r == 0x2022 ||
    r == 0x2027 ||
    r == 0x22C5;

bool _isDash(int r) =>
    r == 0x2D || (r >= 0x2010 && r <= 0x2015) || r == 0x2212 || r == 0x2500;

bool _isKatakana(int r) => r >= 0x30A1 && r <= 0x30FF && r != 0x30FB;

/// [input] が [answers] のどれかと、正規化後に完全一致するか。
bool answerMatches(String input, Iterable<String> answers) {
  final n = normalizeAnswerText(input);
  if (n.isEmpty) return false;
  for (final a in answers) {
    if (normalizeAnswerText(a) == n) return true;
  }
  return false;
}

/// ○×の採点。
bool judgeTrueFalse(Question q, bool answer) => q.answerBool == answer;

/// 空欄補充の採点結果。部分点は無い（[Question.points] は問題単位）。
class ClozeJudgeResult {
  const ClozeJudgeResult(this.blanks);

  /// 空欄番号 → その空欄が正解か（出題の空欄順）。
  final Map<int, bool> blanks;

  /// 全空欄が正解のときだけ正解。空欄が無い場合は不正解。
  bool get isCorrect => blanks.isNotEmpty && blanks.values.every((v) => v);

  int get correctCount => blanks.values.where((v) => v).length;
}

/// 空欄補充を採点する。[inputs] は空欄番号 → 入力（選択式の空欄は選んだ選択肢の文字列）。
/// 未入力の空欄は不正解。
ClozeJudgeResult judgeCloze(Question q, Map<int, String> inputs) =>
    ClozeJudgeResult({
      for (final b in q.blanks)
        b.id: answerMatches(inputs[b.id] ?? '', b.answers),
    });

/// 説明から用語を当てる問題の採点。[input] は入力、または選んだ選択肢の文字列。
bool judgeReverseLookup(Question q, String input) =>
    answerMatches(input, q.answers);

final _placeholder = RegExp(r'\{\{(\d+)\}\}');

/// prompt 中の空欄 `{{n}}` の番号を出現順に返す（重複はそのまま）。
List<int> clozePlaceholderIds(String prompt) => [
  for (final m in _placeholder.allMatches(prompt)) int.parse(m.group(1)!),
];

/// prompt を、本文と空欄の断片に分ける。例: `a{{1}}b` →
/// `[ClozeSegment.text('a'), ClozeSegment.blank(1), ClozeSegment.text('b')]`。
List<ClozeSegment> splitClozePrompt(String prompt) {
  final segments = <ClozeSegment>[];
  var last = 0;
  for (final m in _placeholder.allMatches(prompt)) {
    if (m.start > last)
      segments.add(ClozeSegment.text(prompt.substring(last, m.start)));
    segments.add(ClozeSegment.blank(int.parse(m.group(1)!)));
    last = m.end;
  }
  if (last < prompt.length)
    segments.add(ClozeSegment.text(prompt.substring(last)));
  return segments;
}

/// [splitClozePrompt] の断片。
class ClozeSegment {
  const ClozeSegment.text(String this.text) : blankId = null;
  const ClozeSegment.blank(int this.blankId) : text = null;

  final String? text;
  final int? blankId;

  bool get isBlank => blankId != null;
}
