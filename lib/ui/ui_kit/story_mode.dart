import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';


/// ストーリー型の体験（決定38）の1章での選択肢1つ。
class StoryChoiceSpec {
  const StoryChoiceSpec({
    required this.choiceId,
    required this.text,
    required this.isRecommended,
    required this.feedback,
  });

  final String choiceId;
  final String text;
  final bool isRecommended;
  final String feedback;
}

/// ストーリー型の体験（決定38）の1章。
class StoryChapterSpec {
  const StoryChapterSpec({
    required this.situation,
    required this.choices,
  });

  final String situation;
  final List<StoryChoiceSpec> choices;
}

/// ストーリー型の体験（決定38）の1シナリオ。
class StoryScenarioSpec {
  const StoryScenarioSpec({
    required this.title,
    required this.description,
    required this.chapters,
  });

  final String title;
  final String description;
  final List<StoryChapterSpec> chapters;
}

/// ストーリー型の共通エンジン（決定38。簿記3級の会社経営モード・乙4の
/// 現場の1日モード・G検定のAIプロジェクト経営モードなど複数資格で共用）。
///
/// 体験: 章を順に進み、各章の [StoryChapterSpec.situation] に対して
/// [StoryChapterSpec.choices] から判断を選ぶ→[StoryChoiceSpec.feedback] で
/// 理由を見る→次の章へ。最後の章まで進むと、章ごとの判断を振り返る。
/// コード描画のみ（AI呼び出しなし）。
class StoryModeWidget extends StatefulWidget {
  const StoryModeWidget({super.key, required this.scenario});

  final StoryScenarioSpec scenario;

  @override
  State<StoryModeWidget> createState() => _StoryModeWidgetState();
}

class _StoryModeWidgetState extends State<StoryModeWidget> {
  int _chapterIndex = 0;
  StoryChoiceSpec? _selected;
  final List<StoryChoiceSpec> _history = [];

  bool get _isLastChapter => _chapterIndex == widget.scenario.chapters.length - 1;
  bool get _isDone => _chapterIndex >= widget.scenario.chapters.length;

  void _select(StoryChoiceSpec choice) {
    setState(() => _selected = choice);
  }

  void _next() {
    setState(() {
      _history.add(_selected!);
      _selected = null;
      _chapterIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.scenario;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(s.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(s.description, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        if (_isDone)
          _StoryReview(chapters: s.chapters, history: _history)
        else
          _StoryChapterStep(
            chapterIndex: _chapterIndex,
            chapterCount: s.chapters.length,
            chapter: s.chapters[_chapterIndex],
            selected: _selected,
            onSelect: _select,
            onNext: _next,
            isLastChapter: _isLastChapter,
          ),
      ],
    );
  }
}

class _StoryChapterStep extends StatelessWidget {
  const _StoryChapterStep({
    required this.chapterIndex,
    required this.chapterCount,
    required this.chapter,
    required this.selected,
    required this.onSelect,
    required this.onNext,
    required this.isLastChapter,
  });

  final int chapterIndex;
  final int chapterCount;
  final StoryChapterSpec chapter;
  final StoryChoiceSpec? selected;
  final void Function(StoryChoiceSpec) onSelect;
  final VoidCallback onNext;
  final bool isLastChapter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          LabStrings.of(context).storyChapterOf(chapterIndex + 1, chapterCount),
          style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(chapter.situation, style: theme.textTheme.bodyLarge),
          ),
        ),
        const SizedBox(height: 12),
        if (selected == null) ...[
          Text(LabStrings.of(context).storyHowJudge, style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          // 選択肢は長い文になるため、横いっぱいに広げて折り返す（チップだと1行で切れる）。
          for (final c in chapter.choices) ...[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onPressed: () => onSelect(c),
              child: Text(c.text, textAlign: TextAlign.left),
            ),
            const SizedBox(height: 8),
          ],
        ] else ...[
          Card(
            margin: EdgeInsets.zero,
            color: (selected!.isRecommended
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.errorContainer)
                .withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        selected!.isRecommended ? Icons.check_circle : Icons.error_outline,
                        size: 18,
                        color: selected!.isRecommended
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        selected!.isRecommended ? LabStrings.of(context).storyGood : LabStrings.of(context).storyOther,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: selected!.isRecommended
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(selected!.feedback, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onNext,
            child: Text(isLastChapter ? LabStrings.of(context).storySeeResult : LabStrings.of(context).storyNext),
          ),
        ],
      ],
    );
  }
}

class _StoryReview extends StatelessWidget {
  const _StoryReview({required this.chapters, required this.history});

  final List<StoryChapterSpec> chapters;
  final List<StoryChoiceSpec> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recommendedCount = history.where((c) => c.isRecommended).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          LabStrings.of(context).storyEnd(recommendedCount, chapters.length),
          style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < chapters.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                history[i].isRecommended ? Icons.check_circle : Icons.error_outline,
                size: 18,
                color: history[i].isRecommended ? theme.colorScheme.primary : theme.colorScheme.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  LabStrings.of(context).storyChapterLine(i + 1, history[i].text),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (i != chapters.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}
