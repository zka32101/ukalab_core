import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'exam_stats_service.dart';

/// アプリ起動時に ProviderScope.overrides で実体を差し込む。
final examStatsServiceProvider = Provider<ExamStatsService>(
  (ref) => throw UnimplementedError(
    'examStatsServiceProvider を ProviderScope.overrides で上書きしてください',
  ),
);
