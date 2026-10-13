import 'package:app_common_kit/app_common_kit.dart' show KitStrings;
import 'package:flutter/material.dart';

import '../../engine/exam_countdown_engine.dart';
import '../../engine/exam_countdown_strings.dart';

ExamCountdownStrings _stringsOf(BuildContext context, ExamCountdownStrings? s) =>
    s ?? ExamCountdownStrings.forLanguageCode(KitStrings.of(context).languageCode);

Widget _fadeIn(BuildContext context, Widget child) {
  final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: reduce ? 1 : 0, end: 1),
    duration: reduce ? Duration.zero : const Duration(milliseconds: 300),
    builder: (context, v, child) => Opacity(opacity: v, child: child),
    child: child,
  );
}

/// 試験日カウントダウンの小さなチップ。ホームの AppBar 付近や `ExamPrepCard` の中に置ける。
///
/// 未設定（[ExamCountdownPhase.none]）のときは何も出さない。試験日を過ぎたら日数は消えて
/// 「おつかれさまでした」だけを静かに出す（出し続けるかどうかはアプリ側で決める）。
/// [onTap] は試験日設定を開く想定。基準日は [clock]（テスト用に注入可）。
class ExamCountdownChip extends StatelessWidget {
  const ExamCountdownChip({
    super.key,
    required this.examDate,
    this.onTap,
    this.clock = DateTime.now,
    this.strings,
  });

  final DateTime? examDate;
  final VoidCallback? onTap;
  final DateTime Function() clock;
  final ExamCountdownStrings? strings;

  @override
  Widget build(BuildContext context) {
    final c = const ExamCountdownEngine().compute(examDate, today: clock());
    if (c.phase == ExamCountdownPhase.none) return const SizedBox.shrink();
    final s = _stringsOf(context, strings);
    final text = s.chip(c);
    final label = onTap == null ? text : '$text。${s.tapHint}';
    final chip = onTap == null
        ? Chip(label: Text(text))
        : ActionChip(label: Text(text), onPressed: onTap);
    return _fadeIn(
      context,
      Semantics(
        container: true,
        button: onTap != null,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: chip,
      ),
    );
  }
}

/// 試験日カウントダウンのカード。気持ちの向け方と「今日できること」の短い提案を添える。
///
/// 未設定のときは何も出さない。試験日を過ぎたら日数を消し、「おつかれさまでした」だけを出す。
/// [onTap] は試験日設定を開く想定。基準日は [clock]（テスト用に注入可）。
class ExamCountdownCard extends StatelessWidget {
  const ExamCountdownCard({
    super.key,
    required this.examDate,
    this.onTap,
    this.clock = DateTime.now,
    this.strings,
  });

  final DateTime? examDate;
  final VoidCallback? onTap;
  final DateTime Function() clock;
  final ExamCountdownStrings? strings;

  @override
  Widget build(BuildContext context) {
    final c = const ExamCountdownEngine().compute(examDate, today: clock());
    if (c.phase == ExamCountdownPhase.none) return const SizedBox.shrink();
    final s = _stringsOf(context, strings);
    final today = s.todaySuggestion(c.phase);
    final lines = [s.title(c), s.pace(c.phase), ?today];
    final semantic = onTap == null ? lines.join('。') : '${lines.join('。')}。${s.tapHint}';
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.title(c), style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(s.pace(c.phase), style: textTheme.bodyMedium),
          if (today != null) ...[
            const SizedBox(height: 8),
            Text(today, style: textTheme.bodyMedium),
          ],
        ],
      ),
    );

    return _fadeIn(
      context,
      Semantics(
        container: true,
        button: onTap != null,
        label: semantic,
        excludeSemantics: true,
        onTap: onTap,
        child: Card(
          color: scheme.surfaceContainerHighest,
          clipBehavior: Clip.antiAlias,
          child: onTap == null ? content : InkWell(onTap: onTap, child: content),
        ),
      ),
    );
  }
}
