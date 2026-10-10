import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _tokens = ['猫', 'が', '魚', 'を', '食べた'];
const _attention = [
  [0.6, 0.1, 0.1, 0.05, 0.15],
  [0.5, 0.3, 0.05, 0.05, 0.1],
  [0.1, 0.05, 0.55, 0.15, 0.15],
  [0.05, 0.05, 0.5, 0.3, 0.1],
  [0.37, 0.05, 0.33, 0.05, 0.2],
];

Widget _app(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  testWidgets('タイトル・説明・注意書き・トークン選択を表示する', (tester) async {
    await tester.pumpWidget(_app(const AttentionVizWidget(
      scenario: AttentionVizSpec(
        title: '誰が何を食べた？',
        description: '「食べた」がどの単語に注目しているか見てみましょう。',
        tokens: _tokens,
        attention: _attention,
      ),
    )));

    expect(find.text('誰が何を食べた？'), findsOneWidget);
    expect(find.text('「食べた」がどの単語に注目しているか見てみましょう。'), findsOneWidget);
    expect(find.textContaining('実際のモデルの出力ではなく'), findsOneWidget);
    for (final t in _tokens) {
      expect(find.widgetWithText(ChoiceChip, t), findsOneWidget);
    }
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('クエリを切り替えると最も注目する単語の説明文が変わる', (tester) async {
    await tester.pumpWidget(_app(const AttentionVizWidget(
      scenario: AttentionVizSpec(
        title: '誰が何を食べた？',
        description: '説明',
        tokens: _tokens,
        attention: _attention,
      ),
    )));

    expect(find.textContaining('「猫」は「猫」に最も強く注目しています'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '食べた'));
    await tester.pumpAndSettle();

    expect(find.textContaining('「食べた」は「猫」に最も強く注目しています'), findsOneWidget);
  });
}
