import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/question_filters.dart';
import '../../question/question.dart';
import 'bookmark_store.dart';
import 'bookmark_tag_edit_screen.dart';
import 'bookmark_tag_store.dart';
import 'question_detail_screen.dart';

/// ブックマークした問題の一覧。タグで絞り込み、「タグを編集」から付け外しができる。
/// 問題をタップすると [QuestionDetailScreen]（または [detailBuilder]）を開く。
/// 問題は [loadQuestions] で読み込む（アプリ側の問題データの持ち方に依らない）。
/// [bookmarkServiceProvider] と [bookmarkTagServiceProvider] の override が前提。
///
/// 一覧から続けて演習したいアプリは、自前の画面を作ってよい（この画面は読み取り専用）。
class BookmarkedQuestionsScreen extends ConsumerStatefulWidget {
  const BookmarkedQuestionsScreen({super.key, required this.loadQuestions, this.detailBuilder});

  final Future<List<Question>> Function() loadQuestions;
  final Widget Function(BuildContext context, Question question)? detailBuilder;

  @override
  ConsumerState<BookmarkedQuestionsScreen> createState() => _BookmarkedQuestionsScreenState();
}

class _BookmarkedQuestionsScreenState extends ConsumerState<BookmarkedQuestionsScreen> {
  List<Question>? _all;
  String? _tagFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await widget.loadQuestions();
    if (!mounted) return;
    setState(() => _all = all);
  }

  @override
  Widget build(BuildContext context) {
    final all = _all;
    if (all == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ブックマーク')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final qids = ref.watch(bookmarkProvider);
    final tags = ref.watch(bookmarkTagProvider);
    final marked = filterByBookmark(all, qids, onlyBookmarked: true);
    final availableTags = allBookmarkTags(tags, marked.map((q) => q.qid));
    final tagFilter = availableTags.contains(_tagFilter) ? _tagFilter : null;
    final shown = tagFilter == null
        ? marked
        : [for (final q in marked) if ((tags[q.qid] ?? const {}).contains(tagFilter)) q];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ブックマーク'),
        actions: [
          if (marked.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BookmarkTagEditScreen(questions: marked)),
              ),
              child: const Text('タグを編集'),
            ),
        ],
      ),
      body: marked.isEmpty
          ? const EmptyState(
              message: 'ブックマークはまだありません。問題のしおりアイコンから登録できます。',
              icon: Icons.bookmark_border,
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (availableTags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ChoiceChip(
                          label: const Text('すべて'),
                          selected: tagFilter == null,
                          onSelected: (_) => setState(() => _tagFilter = null),
                        ),
                        for (final t in availableTags)
                          ChoiceChip(
                            label: Text(t),
                            selected: tagFilter == t,
                            onSelected: (_) => setState(() => _tagFilter = t),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Expanded(
                    child: shown.isEmpty
                        ? const EmptyState(
                            message: '条件に合うブックマークはありません。',
                            icon: Icons.search_off,
                          )
                        : ListView.separated(
                            itemCount: shown.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final q = shown[i];
                              final qTags = (tags[q.qid] ?? const <String>{}).toList()..sort();
                              return Card(
                                child: ListTile(
                                  title: Text(q.prompt, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  subtitle: qTags.isEmpty ? null : Text(qTags.join(' / ')),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          widget.detailBuilder?.call(context, q) ??
                                          QuestionDetailScreen(question: q),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
