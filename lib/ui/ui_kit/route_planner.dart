import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';


/// 最短ルートプランナー（型④、決定76・77）が選んだ1科目の、UI層の軽量な写し。
///
/// ukalab_core の `RouteTask` と同じ構造を持つ。アプリ側がデータモデルから
/// 詰め替えて渡す（`BoundarySliderWidget` と同じ構成）。
class RouteTaskSpec {
  const RouteTaskSpec({
    required this.subjectId,
    required this.subjectName,
    required this.belowPassLine,
  });

  final String subjectId;
  final String subjectName;

  /// 足切り（科目別の最低得点率）を下回っているか。
  final bool belowPassLine;
}

/// 残り日数・弱点・配点から出した「今日やる3つ」を表示する（決定76）。
///
/// 足切りの科目は警告色と「足切りライン未達」のラベルで強調する（決定77）。
class RoutePlannerWidget extends StatelessWidget {
  const RoutePlannerWidget({super.key, required this.tasks, this.onTapTask});

  final List<RouteTaskSpec> tasks;

  /// タスクをタップしたときに subjectId を渡す。null ならタップ不可。
  final ValueChanged<String>? onTapTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (tasks.isEmpty) {
      return Text(LabStrings.of(context).routeEmpty, style: theme.textTheme.bodyMedium);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(LabStrings.of(context).routeToday(tasks.length), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < tasks.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RouteTaskTile(
              order: i + 1,
              task: tasks[i],
              onTap: onTapTask == null ? null : () => onTapTask!(tasks[i].subjectId),
            ),
          ),
      ],
    );
  }
}

class _RouteTaskTile extends StatelessWidget {
  const _RouteTaskTile({required this.order, required this.task, this.onTap});

  final int order;
  final RouteTaskSpec task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warn = task.belowPassLine;
    return Material(
      color: warn
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.4)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(radius: 14, child: Text('$order')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.subjectName, style: theme.textTheme.bodyLarge),
                    if (warn)
                      Text(
                        LabStrings.of(context).routeBelowCutoff,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
