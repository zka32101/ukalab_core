import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../question/question.dart';
import 'bookmark_store.dart';
import 'bookmark_tag_store.dart';
import 'bookmarked_questions_screen.dart';
import 'memo_list_screen.dart';
import 'question_memo_store.dart';

/// ブックマーク・タグ・メモの3サービスを [appId] 別の保存先で読み込み、
/// ProviderScope に渡す override を返す。main() で1回呼ぶだけで配線が済む。
///
/// ```dart
/// ProviderScope(overrides: [...await studyNotesOverrides('g_kentei')], child: ...)
/// ```
Future<List<Override>> studyNotesOverrides(String appId) async {
  final bookmarks = BookmarkService(store: SharedPreferencesBookmarkStore(appId));
  final tags = BookmarkTagService(store: SharedPreferencesBookmarkTagStore(appId));
  final memos = QuestionMemoService(store: SharedPreferencesQuestionMemoStore(appId));
  await bookmarks.load();
  await tags.load();
  await memos.load();
  return [
    bookmarkServiceProvider.overrideWithValue(bookmarks),
    bookmarkTagServiceProvider.overrideWithValue(tags),
    questionMemoServiceProvider.overrideWithValue(memos),
  ];
}

/// ホームに並べる「ブックマーク」「自分用メモ」の2枚のカード。
/// 各アプリは [loadQuestions]（全問題）と任意の [detailBuilder] を渡すだけでよい。
class StudyNotesHomeCards extends StatelessWidget {
  const StudyNotesHomeCards({super.key, required this.loadQuestions, this.detailBuilder});

  final Future<List<Question>> Function() loadQuestions;
  final Widget Function(BuildContext context, Question question)? detailBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: const Text('ブックマーク'),
            subtitle: const Text('しおりを付けた問題を見返せます。タグでも整理できます。'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    BookmarkedQuestionsScreen(loadQuestions: loadQuestions, detailBuilder: detailBuilder),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.sticky_note_2_outlined),
            title: const Text('自分用メモ'),
            subtitle: const Text('解説の下に書き残したメモの一覧です。'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MemoListScreen(loadQuestions: loadQuestions, detailBuilder: detailBuilder),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
