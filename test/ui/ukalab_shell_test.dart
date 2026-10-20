import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

void main() {
  group('UkalabShell', () {
    testWidgets('下部タブは5つで、押すと画面が切り替わる', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: UkalabTheme.light(field: UkalabField.it),
        home: UkalabShell(pages: [for (final n in ['H', 'M', 'E', 'R', 'S']) Text('page-$n')]),
      ));
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      for (final l in UkalabShell.defaultLabels) {
        expect(find.text(l), findsOneWidget);
      }
      expect(UkalabShell.defaultLabels[1], '解く');
      expect(find.text('学ぶ'), findsNothing);
      await tester.tap(find.text('設定'));
      await tester.pump();
      expect(find.text('page-S'), findsOneWidget);
    });
  });
}
