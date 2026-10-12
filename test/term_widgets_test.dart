import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

Widget _app(Widget child) => MaterialApp(
  theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
  home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
);

void main() {
  group('TermCard', () {
    testWidgets('①〜④の順に表示され、関連用語・関連問題がタップできる', (tester) async {
      String? tappedTermId;
      String? tappedQuestionId;
      await tester.pumpWidget(_app(TermCard(
        term: '過学習',
        headline: '練習問題は得意だが、新しい問題には弱くなること',
        definition: '学習データに対して過剰に適合し、未知のデータへの汎化性能が低下する現象。',
        analogy: '過去問だけを丸暗記して、少し出題形式が変わると解けなくなる状態に近い。',
        commonMistake: '「学習不足（未学習）」の反対の現象であり、どちらも汎化性能の低下につながる。',
        relatedTerms: const [RelatedTermRef(termId: 't2', label: '正則化')],
        relatedQuestions: const [RelatedQuestionRef(questionId: 'q1', label: '第12問 過学習の対策')],
        onRelatedTermTap: (id) => tappedTermId = id,
        onRelatedQuestionTap: (id) => tappedQuestionId = id,
      )));
      expect(find.text('過学習'), findsOneWidget);
      expect(find.text('練習問題は得意だが、新しい問題には弱くなること'), findsOneWidget);
      expect(find.textContaining('学習データに対して過剰に適合'), findsOneWidget);
      expect(find.textContaining('過去問だけを丸暗記'), findsOneWidget);
      expect(find.textContaining('学習不足（未学習）'), findsOneWidget);

      await tester.tap(find.text('正則化'));
      expect(tappedTermId, 't2');
      await tester.tap(find.text('第12問 過学習の対策'));
      expect(tappedQuestionId, 'q1');
    });

    testWidgets('showTermCard はボトムシートで開く', (tester) async {
      await tester.pumpWidget(_app(Builder(builder: (context) => ElevatedButton(
        onPressed: () => showTermCard(
          context,
          term: 'AI',
          headline: '人工知能のこと',
          definition: '人間の知的な作業をコンピュータで模倣する技術や、その研究分野。',
        ),
        child: const Text('開く'),
      ))));
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
      expect(find.text('AI'), findsOneWidget);
      expect(find.byType(TermCard), findsOneWidget);
    });
  });

  group('TappableTermText', () {
    testWidgets('一致した用語ごとに下線つきの TextSpan ができ、タップでコールバックが呼ばれる', (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(_app(TappableTermText(
        text: '過学習はニューラルネットワークでも起こる。',
        terms: const [
          TermReference(termId: 't1', matchText: '過学習'),
          TermReference(termId: 't2', matchText: 'ニューラルネットワーク'),
        ],
        onTermTap: tapped.add,
      )));
      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final outer = richText.text as TextSpan;
      expect(outer.toPlainText(), '過学習はニューラルネットワークでも起こる。');
      // Text.rich はスタイル適用のため、渡した TextSpan をもう1段ラップする。
      final span = outer.children!.single as TextSpan;

      final matched = span.children!
          .whereType<TextSpan>()
          .where((s) => s.recognizer is TapGestureRecognizer)
          .toList();
      expect(matched.map((s) => s.text), ['過学習', 'ニューラルネットワーク']);
      expect(matched.every((s) => s.style?.decoration == TextDecoration.underline), isTrue);

      (matched[0].recognizer as TapGestureRecognizer).onTap!();
      (matched[1].recognizer as TapGestureRecognizer).onTap!();
      expect(tapped, ['t1', 't2']);
    });

    testWidgets('一致しない場合はそのまま表示される', (tester) async {
      await tester.pumpWidget(_app(TappableTermText(
        text: 'ただの文章です。',
        terms: const [TermReference(termId: 't1', matchText: '存在しない用語')],
        onTermTap: (_) {},
      )));
      expect(find.text('ただの文章です。'), findsOneWidget);
    });
  });

}
