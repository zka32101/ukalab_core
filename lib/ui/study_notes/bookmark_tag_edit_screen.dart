import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../question/question.dart';
import 'bookmark_tag_store.dart';

/// ブックマークした問題にタグを付ける・外す画面。問題ごとに現在のタグをチップで
/// 表示し、タップで削除、「タグを追加」から新しいタグ名を入力して追加できる。
/// [bookmarkTagServiceProvider] を override しておくこと。
class BookmarkTagEditScreen extends ConsumerWidget {
  const BookmarkTagEditScreen({super.key, required this.questions});

  final List<Question> questions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tags = ref.watch(bookmarkTagProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('タグを編集')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        separatorBuilder: (_, __) => const Divider(height: 24),
        itemBuilder: (context, index) {
          final q = questions[index];
          final qTags = tags[q.qid] ?? const <String>{};
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                q.prompt,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final t in qTags)
                    InputChip(
                      label: Text(t),
                      onDeleted: () => ref.read(bookmarkTagProvider.notifier).removeTag(q.qid, t),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: const Text('タグを追加'),
                    onPressed: () => _showAddTagDialog(context, ref, q.qid),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddTagDialog(BuildContext context, WidgetRef ref, String qid) async {
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タグを追加'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '例: 要復習・暗記・計算問題'),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('キャンセル')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('追加'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (tag == null || tag.trim().isEmpty) return;
    await ref.read(bookmarkTagProvider.notifier).addTag(qid, tag);
  }
}
