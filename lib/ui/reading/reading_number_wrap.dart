import 'package:flutter/widgets.dart';

/// 数字列と続く単位の間に入れる折り返し禁止文字（U+2060 WORD JOINER、幅ゼロで見えない）。
const String kReadingWordJoiner = '⁠';

/// 数字・カンマ・通貨記号・単位が連続する語（例: `300,000円` `¥1,350,000` `△2,400万円`）。
final RegExp _numberRun = RegExp(
  r'[¥￥$]?[△▲+\-−]?\d[\d,]*(?:\.\d+)?'
  r'(?:[万億千]?[円%％個回年月日時分秒人台件点倍割本枚冊]|[万億])?',
);

/// [text] 中の数字・金額の語（4文字以上）の文字の間に [kReadingWordJoiner] を入れ、
/// 数字の途中や数字と単位の間で折り返されないようにする。
///
/// 折り返せるのは語の前後だけになる。該当が無ければ [text] をそのまま返す。
/// 元の文字列は `replaceAll(kReadingWordJoiner, '')` で復元できる。
String keepReadingNumbersTogether(String text) {
  if (text.isEmpty) return text;
  return text.replaceAllMapped(_numberRun, (m) {
    final s = m[0]!;
    if (s.length < 4) return s;
    return s.split('').join(kReadingWordJoiner);
  });
}

/// 折り返し禁止にする語（表の列幅の最小値の計算用。連結文字は入れない）。
List<String> readingUnbreakableTokens(String text) => [
  for (final m in _numberRun.allMatches(text))
    if (m[0]!.length >= 4) m[0]!,
  for (final m in RegExp(r'[A-Za-z0-9_./\-]{4,}').allMatches(text)) m[0]!,
];

/// 数字・金額を途中で折り返さない [Text]。読み上げ（semanticsLabel）は元の文字列。
Text readingNumberSafeText(
  String text, {
  TextStyle? style,
  int? maxLines,
  TextOverflow? overflow,
}) {
  final display = keepReadingNumbersTogether(text);
  return Text(
    display,
    style: style,
    maxLines: maxLines,
    overflow: overflow,
    semanticsLabel: identical(display, text) || display == text ? null : text,
  );
}
