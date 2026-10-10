import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/question_filters.dart';
import '../../question/question.dart';
import 'question_detail_screen.dart';
import 'question_memo_store.dart';

/// 書き残した自分用メモをまとめて見返せる一覧。メモ本文・問題文でキーワード絞り込みができる。
/// 問題をタップすると [QuestionDetailScreen]（または [detailBuilder]）で読み取り専用の詳細を開く。
/// 問題は [loadQuestions] で読み込む（アプリ側の問題データの持ち方に依らない）。
class MemoListScreen extends ConsumerStatefulWidget {
  const MemoListScreen({super.key, required this.loadQuestions, this.detailBuilder});

  final Future<List<Question>> Function() loadQuestions;
  final Widget Function(BuildContext context, Question question)? detailBuilder;

  @override
  ConsumerState<MemoListScreen> createState() => _MemoListScreenState();
}

class _MemoListScreenState extends ConsumerState<MemoListScreen> {
  final _controller = TextEditingController();
  List<Question>? _all;
  String _keyword = '';

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = _all;
    final memos = ref.watch(questionMemoProvider);
    final memoed = all == null ? const <Question>[] : filterMemoedQuestions(all, memos, '');
    final filtered = all == null ? const <Question>[] : filterMemoedQuestions(all, memos, _keyword);

    return Scaffold(
      appBar: AppBar(title: const Text('自分用メモの一覧')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'メモ・問題文で絞り込む',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _keyword = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: all == null
                  ? const Center(child: CircularProgressIndicator())
                  : memoed.isEmpty
                      ? const EmptyState(
                          message: 'まだメモはありません。解説の下から書き残せます。',
                          icon: Icons.sticky_note_2_outlined,
                        )
                      : filtered.isEmpty
                          ? const EmptyState(
                              message: '一致するメモは見つかりませんでした。',
                              icon: Icons.search_off,
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final q = filtered[i];
                                return Card(
                                  child: ListTile(
                                    title: Text(q.prompt, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    subtitle: Text(
                                      memos[q.qid] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall,
                                    ),
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
