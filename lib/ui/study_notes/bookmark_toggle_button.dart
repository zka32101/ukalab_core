import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bookmark_store.dart';

/// 問題のブックマークを付け外しするしおりボタン。[bookmarkServiceProvider] の override が前提。
class BookmarkToggleButton extends ConsumerWidget {
  const BookmarkToggleButton({super.key, required this.qid});

  final String qid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarked = ref.watch(bookmarkProvider).contains(qid);
    return IconButton(
      icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
      tooltip: bookmarked ? 'ブックマークを外す' : 'ブックマークする',
      onPressed: () => ref.read(bookmarkProvider.notifier).toggle(qid),
    );
  }
}
