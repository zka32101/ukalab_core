import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';
import 'package:ukalab_core/ui.dart';

class _MemoStore implements QuestionMemoStore {
  Map<String, String> saved = {};

  @override
  Future<Map<String, String>> read() async => saved;

  @override
  Future<void> write(Map<String, String> memos) async => saved = memos;
}

class _BookmarkStore implements BookmarkStore {
  Set<String> saved = {};

  @override
  Future<Set<String>> read() async => saved;

  @override
  Future<void> write(Set<String> qids) async => saved = qids;
}

Question _q(String qid, String prompt) => Question(
      qid: qid,
      examId: 'e',
      subjectId: 's',
      topicId: 't',
      prompt: prompt,
      choices: const ['甲', '乙', '丙'],
      answerIndex: 1,
      explanation: '解説文',
      source: QuestionSource.original,
      sourceRef: 'test',
      contentVer: '2026.10.0',
    );

void main() {
  bookmarkedQuestionsScreenTests();
  testWidgets('BookmarkToggleButton: タップでブックマークが付き外れる', (tester) async {
    final service = BookmarkService(store: _BookmarkStore());
    await service.load();
    await tester.pumpWidget(ProviderScope(
      overrides: [bookmarkServiceProvider.overrideWithValue(service)],
      child: const MaterialApp(home: Scaffold(body: BookmarkToggleButton(qid: 'q1'))),
    ));
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(service.qids, {'q1'});
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(service.qids, isEmpty);
  });

  testWidgets('QuestionMemoField: フォーカスを外すと保存される', (tester) async {
    final service = QuestionMemoService(store: _MemoStore());
    await service.load();
    await tester.pumpWidget(ProviderScope(
      overrides: [questionMemoServiceProvider.overrideWithValue(service)],
      child: const MaterialApp(
        home: Scaffold(
          body: Column(children: [
            QuestionMemoField(qid: 'q1'),
            TextField(key: ValueKey('other')),
          ]),
        ),
      ),
    ));
    await tester.enterText(find.byType(TextField).first, '覚え方');
    await tester.tap(find.byKey(const ValueKey('other')));
    await tester.pump();
    expect(service.memos['q1'], '覚え方');
  });

  testWidgets('MemoListScreen: メモのある問題だけ出て、タップで詳細を開く', (tester) async {
    final service = QuestionMemoService(store: _MemoStore());
    await service.load();
    await service.setMemo(qid: 'q1', memo: '要復習');
    await tester.pumpWidget(ProviderScope(
      overrides: [questionMemoServiceProvider.overrideWithValue(service)],
      child: MaterialApp(
        home: MemoListScreen(
          loadQuestions: () async => [_q('q1', '引火点とは'), _q('q2', '指定数量とは')],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('引火点とは'), findsOneWidget);
    expect(find.text('指定数量とは'), findsNothing);
    expect(find.text('要復習'), findsOneWidget);

    await tester.tap(find.text('引火点とは'));
    await tester.pumpAndSettle();
    expect(find.text('問題の詳細'), findsOneWidget);
    expect(find.text('乙'), findsOneWidget);
  });
}

class _TagStore implements BookmarkTagStore {
  Map<String, Set<String>> saved = {};

  @override
  Future<Map<String, Set<String>>> read() async => saved;

  @override
  Future<void> write(Map<String, Set<String>> tags) async => saved = tags;
}

void bookmarkedQuestionsScreenTests() {
  testWidgets('BookmarkedQuestionsScreen: ブックマーク済みだけ出て、タグで絞り込める', (tester) async {
    final bookmarks = BookmarkService(store: _BookmarkStore());
    await bookmarks.load();
    await bookmarks.toggle('q1');
    await bookmarks.toggle('q2');
    final tags = BookmarkTagService(store: _TagStore());
    await tags.load();
    await tags.addTag('q1', '要復習');
    await tester.pumpWidget(ProviderScope(
      overrides: [
        bookmarkServiceProvider.overrideWithValue(bookmarks),
        bookmarkTagServiceProvider.overrideWithValue(tags),
      ],
      child: MaterialApp(
        home: BookmarkedQuestionsScreen(
          loadQuestions: () async => [_q('q1', '引火点とは'), _q('q2', '指定数量とは'), _q('q3', '無関係')],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('引火点とは'), findsOneWidget);
    expect(find.text('指定数量とは'), findsOneWidget);
    expect(find.text('無関係'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, '要復習'));
    await tester.pumpAndSettle();
    expect(find.text('引火点とは'), findsOneWidget);
    expect(find.text('指定数量とは'), findsNothing);

    await tester.tap(find.text('引火点とは'));
    await tester.pumpAndSettle();
    expect(find.text('問題の詳細'), findsOneWidget);
  });

  testWidgets('BookmarkedQuestionsScreen: ブックマークが無ければ案内を出す', (tester) async {
    final bookmarks = BookmarkService(store: _BookmarkStore());
    await bookmarks.load();
    final tags = BookmarkTagService(store: _TagStore());
    await tags.load();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        bookmarkServiceProvider.overrideWithValue(bookmarks),
        bookmarkTagServiceProvider.overrideWithValue(tags),
      ],
      child: MaterialApp(home: BookmarkedQuestionsScreen(loadQuestions: () async => [_q('q1', '問')])),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('ブックマークはまだありません'), findsOneWidget);
  });
}
