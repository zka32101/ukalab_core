import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'question_memo_store.dart';

/// 問題ごとの自分用メモの入力欄。間違えた理由・覚え方などを書き残せる。
/// フォーカスが外れたときに保存する。問題が変わるたびに `key: ValueKey(qid)` を付けて、
/// 入力欄を作り直すこと。[questionMemoServiceProvider] の override が前提。
class QuestionMemoField extends ConsumerStatefulWidget {
  const QuestionMemoField({super.key, required this.qid});

  final String qid;

  @override
  ConsumerState<QuestionMemoField> createState() => _QuestionMemoFieldState();
}

class _QuestionMemoFieldState extends ConsumerState<QuestionMemoField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final memo = ref.read(questionMemoProvider)[widget.qid] ?? '';
    _controller = TextEditingController(text: memo);
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _save();
  }

  void _save() {
    ref.read(questionMemoProvider.notifier).setMemo(qid: widget.qid, memo: _controller.text);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: const InputDecoration(
        labelText: '自分用メモ',
        hintText: '間違えた理由や覚え方を書き残せます',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      maxLines: 3,
      minLines: 1,
    );
  }
}
