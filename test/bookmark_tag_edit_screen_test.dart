import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';
import 'package:ukalab_core/ui.dart';

class _FakeTagStore implements BookmarkTagStore {
  Map<String, Set<String>> saved = {};

  @override
  Future<Map<String, Set<String>>> read() async => saved;

  @override
  Future<void> write(Map<String, Set<String>> tags) async => saved = tags;
}

Question _q(String qid, String prompt) => Question(
      qid: qid,
      examId: 'e',
      subjectId: 's',
      topicId: 't',
      prompt: prompt,
      explanation: '解説',
      source: QuestionSource.original,
      sourceRef: 'test',
      contentVer: '2026.10.0',
    );

void main() {
  testWidgets('タグの追加と削除ができる', (tester) async {
    final service = BookmarkTagService(store: _FakeTagStore());
    await service.load();
    await tester.pumpWidget(ProviderScope(
      overrides: [bookmarkTagServiceProvider.overrideWithValue(service)],
      child: MaterialApp(
        home: BookmarkTagEditScreen(questions: [_q('q1', '引火点とは'), _q('q2', '指定数量とは')]),
      ),
    ));
    expect(find.text('引火点とは'), findsOneWidget);
    expect(find.text('タグを追加'), findsNWidgets(2));

    await tester.tap(find.text('タグを追加').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '要復習');
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
    expect(find.text('要復習'), findsOneWidget);
    expect(service.tags['q1'], {'要復習'});

    await tester.tap(find.byIcon(Icons.cancel));
    await tester.pumpAndSettle();
    expect(find.text('要復習'), findsNothing);
  });
}
