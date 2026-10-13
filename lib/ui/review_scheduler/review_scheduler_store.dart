import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../progress/review_scheduler_engine.dart';
import '../data_management/data_management.dart';

/// 復習予定の保存先（`MistakeNoteStore` と同じ流儀）。
/// 保存するのは問題ID・段・日付・分野IDのみ（問題文・個人情報は保存しない）。
abstract class ReviewSchedulerStore {
  Future<List<ReviewItem>> read();
  Future<void> write(List<ReviewItem> items);
}

/// テスト・プレビュー用のインメモリ実装。
class InMemoryReviewSchedulerStore implements ReviewSchedulerStore {
  List<ReviewItem> _items = [];

  @override
  Future<List<ReviewItem>> read() async => List.unmodifiable(_items);

  @override
  Future<void> write(List<ReviewItem> items) async => _items = [...items];
}

/// 保存値を復元する。null・壊れた値・不正な要素は無視する（壊れていれば空）。
List<ReviewItem> decodeReviewItems(String? raw) {
  if (raw == null) return const [];
  try {
    final list = jsonDecode(raw) as List;
    return list.map(ReviewItem.fromJson).whereType<ReviewItem>().toList();
  } catch (_) {
    return const [];
  }
}

String encodeReviewItems(List<ReviewItem> items) =>
    jsonEncode([for (final i in items) i.toJson()]);

/// 端末内（SharedPreferences）への保存。キーは `ukalab_<アプリID>_review_schedule`。
class SharedPreferencesReviewSchedulerStore implements ReviewSchedulerStore {
  SharedPreferencesReviewSchedulerStore(this.appId);

  final String appId;

  String get _key => 'ukalab_${appId}_review_schedule';

  @override
  Future<List<ReviewItem>> read() async {
    final p = await SharedPreferences.getInstance();
    return decodeReviewItems(p.getString(_key));
  }

  @override
  Future<void> write(List<ReviewItem> items) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, encodeReviewItems(items));
  }
}

/// 復習予定をバックアップ・リセットの対象にする部品（キーは `reviewSchedule`）。
DataPart reviewSchedulerDataPart(ReviewSchedulerStore store, {void Function()? onChanged}) =>
    DataPart(
      id: 'reviewSchedule',
      export: (ref) async => [for (final i in await store.read()) i.toJson()],
      restore: (ref, json) async {
        final items = json is List
            ? json.map(ReviewItem.fromJson).whereType<ReviewItem>().toList()
            : <ReviewItem>[];
        await store.write(items);
        onChanged?.call();
      },
      reset: (ref) async {
        await store.write(const []);
        onChanged?.call();
      },
    );
