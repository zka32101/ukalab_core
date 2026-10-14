import 'package:app_common_kit/app_common_kit.dart' show KitStrings;
import 'package:flutter/material.dart';

import '../../peer/peer_stats.dart';
import '../../peer/peer_stats_strings.dart';

/// 「他にも頑張っている人がいる」匿名集計のカード。ホームに置ける小さなウィジェット。
///
/// 表示する項目が1つもない（[snapshot] が null、または各項目が閾値 100 人以下）ときは
/// 何も描画しない。取得（[PeerStatsSource]）はアプリ側で行い、結果を [snapshot] に渡す。
class PeerStatsCard extends StatelessWidget {
  const PeerStatsCard({
    super.key,
    required this.snapshot,
    this.streakDays = 0,
    this.examDate,
    this.clock = DateTime.now,
    this.strings,
  });

  final PeerStatsSnapshot? snapshot;
  final int streakDays;
  final DateTime? examDate;
  final DateTime Function() clock;
  final PeerStatsStrings? strings;

  @override
  Widget build(BuildContext context) {
    final view = PeerStatsView.from(snapshot, streakDays: streakDays, examDate: examDate, today: clock());
    if (view.isEmpty) return const SizedBox.shrink();
    final s = strings ?? PeerStatsStrings.forLanguageCode(KitStrings.of(context).languageCode);
    final lines = s.lines(view);
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: [s.title, ...lines, s.anonymousNote].join('。'),
      excludeSemantics: true,
      child: Card(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.title, style: theme.textTheme.titleMedium),
              for (final l in lines) ...[
                const SizedBox(height: 8),
                Text(l, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 8),
              Text(
                s.anonymousNote,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
