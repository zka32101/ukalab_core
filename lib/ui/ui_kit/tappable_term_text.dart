import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 本文中で検出してタップ可能にする用語1件。
class TermReference {
  const TermReference({required this.termId, required this.matchText});

  final String termId;

  /// 本文中で検出する文字列（表記ゆれがあれば複数の [TermReference] を用意する）。
  final String matchText;
}

/// 問題文・解説文などの本文中にある専門用語に、下線つきのタップ領域を重ねる
/// （決定50「どこでもタップして、やさしい解説が読める」）。下線は色だけに
/// 頼らない合図として使う。
class TappableTermText extends StatefulWidget {
  const TappableTermText({
    super.key,
    required this.text,
    required this.terms,
    required this.onTermTap,
    this.style,
  });

  final String text;
  final List<TermReference> terms;
  final void Function(String termId) onTermTap;
  final TextStyle? style;

  @override
  State<TappableTermText> createState() => _TappableTermTextState();
}

class _TappableTermTextState extends State<TappableTermText> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _clearRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _clearRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _clearRecognizers();
    final baseStyle = widget.style ?? DefaultTextStyle.of(context).style;
    return Text.rich(
      TextSpan(children: _buildSpans(baseStyle)),
      style: baseStyle,
    );
  }

  List<InlineSpan> _buildSpans(TextStyle baseStyle) {
    final text = widget.text;
    final terms = widget.terms;
    if (terms.isEmpty || text.isEmpty) return [TextSpan(text: text)];

    // 長い一致を優先する（例:「ニューラルネットワーク」を「ニューラル」より先に拾う）。
    final sorted = [...terms]
      ..sort((a, b) => b.matchText.length.compareTo(a.matchText.length));
    final underline = baseStyle.copyWith(
      decoration: TextDecoration.underline,
      decorationThickness: 2,
      fontWeight: FontWeight.w600,
    );

    final spans = <InlineSpan>[];
    final plain = StringBuffer();
    var i = 0;
    while (i < text.length) {
      TermReference? matched;
      var matchLen = 0;
      for (final t in sorted) {
        final m = t.matchText;
        if (m.isEmpty) continue;
        if (i + m.length <= text.length && text.startsWith(m, i)) {
          matched = t;
          matchLen = m.length;
          break;
        }
      }
      if (matched != null) {
        if (plain.isNotEmpty) {
          spans.add(TextSpan(text: plain.toString()));
          plain.clear();
        }
        final termId = matched.termId;
        final recognizer = TapGestureRecognizer()
          ..onTap = () => widget.onTermTap(termId);
        _recognizers.add(recognizer);
        spans.add(TextSpan(
          text: text.substring(i, i + matchLen),
          style: underline,
          recognizer: recognizer,
        ));
        i += matchLen;
      } else {
        plain.write(text[i]);
        i++;
      }
    }
    if (plain.isNotEmpty) spans.add(TextSpan(text: plain.toString()));
    return spans;
  }
}
