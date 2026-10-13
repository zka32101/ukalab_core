import 'package:app_common_kit/app_common_kit.dart' show KitStrings;
import 'package:flutter/material.dart';

import '../../progress/mistake_note_engine.dart';
import '../../progress/mistake_note_strings.dart';
import '../answer_feedback/answer_feedback_strings.dart';

/// 間違いノートの絞り込み。
enum MistakeNoteFilter { upcoming, overcome }

/// 間違いノートの一覧。「これから」と「克服」で切り替える。並びは直近の間違い順（件数順にはしない）。
///
/// 問題文は core が持たないので、[questionBuilder] でアプリが渡す。[onRetry] で
/// アプリが出題画面を開く（解き直した結果は通常の履歴に記録し、`MistakeNoteEngine.update` で反映）。
/// [celebrateQids] に新しく克服した問題IDを渡すと、上部に軽く祝う表示を出す。
/// premium で出し分けたいときは、アプリ側でこのウィジェットを包む（core では制限しない）。
/// 文言は [strings]、無ければ `KitStringsScope` の言語（ja・en。他は日本語）。
class MistakeNoteView extends StatefulWidget {
  const MistakeNoteView({
    super.key,
    required this.entries,
    required this.questionBuilder,
    required this.onRetry,
    this.strings,
    this.causeStrings,
    this.topicLabel,
    this.celebrateQids = const {},
    this.initialFilter = MistakeNoteFilter.upcoming,
  });

  final List<MistakeNoteEntry> entries;

  /// 問題の本文などを描く（core は問題本文を持たない）。
  final Widget Function(BuildContext context, MistakeNoteEntry entry) questionBuilder;

  /// 「解き直す」を押したとき。
  final ValueChanged<MistakeNoteEntry> onRetry;

  final MistakeNoteStrings? strings;

  /// 原因ラベルの文言。省略時は言語に合う `AnswerFeedbackStrings`。
  final AnswerFeedbackStrings? causeStrings;

  /// 分野IDの表示名。省略時は分野を出さない。
  final String Function(String topicId)? topicLabel;

  /// 新しく克服した問題ID（祝う表示用）。
  final Set<String> celebrateQids;

  final MistakeNoteFilter initialFilter;

  @override
  State<MistakeNoteView> createState() => _MistakeNoteViewState();
}

class _MistakeNoteViewState extends State<MistakeNoteView> {
  late MistakeNoteFilter _filter = widget.initialFilter;

  @override
  Widget build(BuildContext context) {
    final lang = KitStrings.of(context).languageCode;
    final s = widget.strings ?? MistakeNoteStrings.forLanguageCode(lang);
    final cs = widget.causeStrings ?? AnswerFeedbackStrings.forLanguageCode(lang);
    final theme = Theme.of(context);
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final shown = [
      for (final e in widget.entries)
        if (_filter == MistakeNoteFilter.overcome ? e.overcome : !e.overcome) e,
    ]..sort((a, b) {
        final c = b.lastMissedAt.compareTo(a.lastMissedAt);
        return c != 0 ? c : a.qid.compareTo(b.qid);
      });
    final celebrating = widget.celebrateQids.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Semantics(
            header: true,
            child: Text(s.title, style: theme.textTheme.titleLarge),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(s.intro, style: theme.textTheme.bodyMedium),
        ),
        if (celebrating) _Celebration(strings: s, reduce: reduce),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Wrap(
            spacing: 8,
            children: [
              for (final f in MistakeNoteFilter.values)
                Semantics(
                  button: true,
                  selected: _filter == f,
                  excludeSemantics: true,
                  label: f == MistakeNoteFilter.upcoming ? s.filterUpcoming : s.filterOvercome,
                  onTap: () => setState(() => _filter = f),
                  child: ChoiceChip(
                    label: Text(f == MistakeNoteFilter.upcoming ? s.filterUpcoming : s.filterOvercome),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? _Empty(
                  title: _filter == MistakeNoteFilter.upcoming ? s.emptyUpcomingTitle : s.emptyOvercomeTitle,
                  body: _filter == MistakeNoteFilter.upcoming ? s.emptyUpcomingBody : s.emptyOvercomeBody,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: shown.length,
                  itemBuilder: (context, i) => _EntryCard(
                    key: ValueKey('mistake_note_${shown[i].qid}'),
                    entry: shown[i],
                    strings: s,
                    causeStrings: cs,
                    topicLabel: widget.topicLabel,
                    question: widget.questionBuilder(context, shown[i]),
                    onRetry: () => widget.onRetry(shown[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Celebration extends StatelessWidget {
  const _Celebration({required this.strings, required this.reduce});

  final MistakeNoteStrings strings;
  final bool reduce;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? 1 : 0, end: 1),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 400),
      builder: (context, v, child) => Opacity(opacity: v, child: child),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Semantics(
          container: true,
          liveRegion: true,
          label: '${strings.celebrateTitle}${strings.celebrateBody}',
          excludeSemantics: true,
          child: Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.celebration_outlined, color: scheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.celebrateTitle,
                            style: t.titleMedium?.copyWith(color: scheme.onPrimaryContainer)),
                        Text(strings.celebrateBody,
                            style: t.bodyMedium?.copyWith(color: scheme.onPrimaryContainer)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: t.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(body, style: t.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    super.key,
    required this.entry,
    required this.strings,
    required this.causeStrings,
    required this.topicLabel,
    required this.question,
    required this.onRetry,
  });

  final MistakeNoteEntry entry;
  final MistakeNoteStrings strings;
  final AnswerFeedbackStrings causeStrings;
  final String Function(String topicId)? topicLabel;
  final Widget question;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final d = entry.lastMissedAt;
    final tags = <String>[
      if (entry.topicId != null && topicLabel != null) topicLabel!(entry.topicId!),
      if (entry.lastCause != null) causeStrings.causeLabel(entry.lastCause!),
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.overcome)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 20, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(strings.overcomeBadge, style: t.labelLarge?.copyWith(color: scheme.primary)),
                  ],
                ),
              ),
            question,
            const SizedBox(height: 8),
            if (tags.isNotEmpty)
              Wrap(spacing: 8, runSpacing: 4, children: [for (final x in tags) Chip(label: Text(x))]),
            Text('${strings.foundOnLabel} ${d.month}/${d.day}', style: t.bodySmall),
            Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                button: true,
                hint: strings.retryHint,
                child: FilledButton.tonal(onPressed: onRetry, child: Text(strings.retry)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
