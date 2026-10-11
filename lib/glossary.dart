/// 用語集の共通部品。一覧（検索・分野での絞り込み・「覚えた」チェック）と、
/// 用語カードを開く処理、「覚えた」の端末内保存を受け持つ。
///
/// 使い方: 用語（`Term`）の一覧をアプリ側で読み込み、[GlossaryListView] に渡す。
/// `Riverpod` は使わないので、どのアプリの画面にも差し込める。
library;

import 'package:app_common_kit/app_common_kit.dart' show EmptyState, RelatedTermRef, showTermCard;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'term/term.dart';
import 'ui/data_management/data_management.dart';

/// 「覚えた」にした用語の `termId` の端末内保存。キーは `ukalab_<アプリID>_learned_term_ids`。
class LearnedTermsStore {
  LearnedTermsStore(this.appId);

  final String appId;

  String get _key => 'ukalab_${appId}_learned_term_ids';

  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key)?.toSet() ?? {};
  }

  Future<void> setLearned(String termId, bool learned) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key)?.toSet() ?? {};
    if (learned) {
      ids.add(termId);
    } else {
      ids.remove(termId);
    }
    await prefs.setStringList(_key, ids.toList());
  }

  /// バックアップの読み込み用。[ids] で置き換える。
  Future<void> replace(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.toList());
  }
}

/// 「覚えた」をバックアップ・リセットの対象にする部品（キーは `learnedTerms`）。
/// 画面が開いたままでも反映できるよう、[onChanged] で再読み込みなどを呼べる。
DataPart learnedTermsDataPart(LearnedTermsStore store, {void Function()? onChanged}) => DataPart(
      id: 'learnedTerms',
      export: (ref) async => (await store.load()).toList()..sort(),
      restore: (ref, json) async {
        await store.replace((json as List).cast<String>().toSet());
        onChanged?.call();
      },
      reset: (ref) async {
        await store.replace({});
        onChanged?.call();
      },
    );

/// [term] を用語カードのボトムシートで開く。関連用語をタップすると、
/// 前のカードを閉じて該当の用語カードを開き直す（再帰的に辿れる）。
void openTermCard(BuildContext context, List<Term> all, Term term) {
  Term? findTerm(String termId) {
    for (final t in all) {
      if (t.termId == termId) return t;
    }
    return null;
  }

  void open(Term t) {
    showTermCard(
      context,
      term: t.term,
      headline: t.headline,
      definition: t.definition,
      analogy: t.analogy,
      commonMistake: t.commonMistake,
      relatedTerms: [
        for (final id in t.relatedTermIds)
          if (findTerm(id) case final related?) RelatedTermRef(termId: related.termId, label: related.term),
      ],
      onRelatedTermTap: (termId) {
        final related = findTerm(termId);
        if (related != null) {
          Navigator.of(context).pop();
          open(related);
        }
      },
    );
  }

  open(term);
}

enum _LearnedFilter { all, learned, unlearned }

/// 用語集の一覧（Scaffold を含まない本体）。検索、分野での絞り込み、「覚えた」チェックと
/// 「すべて／覚えた／未習得」の切り替え。タップで用語カードを開く。
///
/// [subjects]（`subjectId` → 表示名）を渡すと分野のチップが並ぶ。
/// [initialSubjectId] を渡すと、その分野の未習得の用語に絞った状態で開く
/// （苦手分野カードからの導線向け。チップで「すべて」に戻せる）。
class GlossaryListView extends StatefulWidget {
  const GlossaryListView({
    super.key,
    required this.terms,
    required this.store,
    this.subjects = const {},
    this.initialSubjectId,
    this.initialSubjectLabel,
  });

  final List<Term> terms;
  final LearnedTermsStore store;
  final Map<String, String> subjects;
  final String? initialSubjectId;

  /// [subjects] を渡さないときの、絞り込み中の分野の表示名。「で絞り込み中 ×」のチップで解除できる。
  final String? initialSubjectLabel;

  @override
  State<GlossaryListView> createState() => _GlossaryListViewState();
}

class _GlossaryListViewState extends State<GlossaryListView> {
  final _searchController = TextEditingController();
  Set<String> _learnedIds = {};
  late _LearnedFilter _filter;
  late String? _subjectFilter;

  @override
  void initState() {
    super.initState();
    _subjectFilter = widget.initialSubjectId;
    _filter = widget.initialSubjectId != null ? _LearnedFilter.unlearned : _LearnedFilter.all;
    widget.store.load().then((ids) {
      if (mounted) setState(() => _learnedIds = ids);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleLearned(Term term) async {
    final learned = !_learnedIds.contains(term.termId);
    await widget.store.setLearned(term.termId, learned);
    if (!mounted) return;
    setState(() {
      _learnedIds = learned ? {..._learnedIds, term.termId} : ({..._learnedIds}..remove(term.termId));
    });
  }

  List<Term> get _filtered {
    final query = _searchController.text.trim();
    return [
      for (final t in widget.terms)
        if ((_subjectFilter == null || t.subjectId == _subjectFilter) &&
            (query.isEmpty || t.term.contains(query) || t.headline.contains(query)) &&
            switch (_filter) {
              _LearnedFilter.all => true,
              _LearnedFilter.learned => _learnedIds.contains(t.termId),
              _LearnedFilter.unlearned => !_learnedIds.contains(t.termId),
            })
          t,
    ]..sort((a, b) => a.term.compareTo(b.term));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.terms.isEmpty) {
      return const EmptyState(message: '用語データがまだありません。');
    }
    final theme = Theme.of(context);
    final filtered = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: '用語を検索',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<_LearnedFilter>(
              segments: const [
                ButtonSegment(value: _LearnedFilter.all, label: Text('すべて')),
                ButtonSegment(value: _LearnedFilter.learned, label: Text('覚えた')),
                ButtonSegment(value: _LearnedFilter.unlearned, label: Text('未習得')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
          ),
        ),
        if (widget.subjects.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('すべての分野'),
                    selected: _subjectFilter == null,
                    onSelected: (_) => setState(() => _subjectFilter = null),
                  ),
                ),
                for (final e in widget.subjects.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: _subjectFilter == e.key,
                      onSelected: (_) => setState(() => _subjectFilter = e.key),
                    ),
                  ),
              ],
            ),
          ),
        if (widget.subjects.isEmpty && _subjectFilter != null && widget.initialSubjectLabel != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.filter_alt, size: 16),
                label: Text('「${widget.initialSubjectLabel}」で絞り込み中 ×'),
                onPressed: () => setState(() => _subjectFilter = null),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(message: '該当する用語が見つかりません。', icon: Icons.search_off)
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final t = filtered[i];
                    return ListTile(
                      leading: Checkbox(value: _learnedIds.contains(t.termId), onChanged: (_) => _toggleLearned(t)),
                      title: Text(t.term),
                      subtitle: Text(
                        t.headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                      onTap: () => openTermCard(context, widget.terms, t),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
