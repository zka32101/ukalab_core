import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';

void main() {
  testWidgets('studyNotesOverrides で3サービスが使え、ホームカードから一覧を開ける', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final overrides = await studyNotesOverrides('t');
    await tester.pumpWidget(ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Scaffold(body: StudyNotesHomeCards(loadQuestions: () async => const [])),
      ),
    ));
    expect(find.text('ブックマーク'), findsOneWidget);
    expect(find.text('自分用メモ'), findsOneWidget);
    await tester.tap(find.text('自分用メモ'));
    await tester.pumpAndSettle();
    expect(find.byType(MemoListScreen), findsOneWidget);
  });
}
