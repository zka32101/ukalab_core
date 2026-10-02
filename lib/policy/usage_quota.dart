/// 文字列の読み書きだけを持つ保存先。アプリ側が SharedPreferences などで実装する
/// （コアは純Dartのまま保つため、保存先は注入する）。
abstract class KeyValueStore {
  String? read(String key);
  Future<void> write(String key, String value);
}

/// テスト・プレビュー用。
class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _data = {};

  @override
  String? read(String key) => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;
}

/// 回数制限の単位。日付・月が変わると自動でリセットされる。
enum QuotaPeriod { daily, monthly }

/// 無料枠などの回数制限（例: 模擬試験は月1回、復習は1日10問）。
///
/// 使用回数は [store] にローカル保存する。端末の時計を巻き戻すと回数を
/// 稼げる点は許容する（課金の保護ではなく、無料枠の目安のため）。
class UsageQuota {
  UsageQuota({
    required this.id,
    required this.period,
    required this.limit,
    required KeyValueStore store,
    DateTime Function()? clock,
  })  : assert(limit == null || limit >= 0),
        _store = store,
        _clock = clock ?? DateTime.now;

  /// 保存キーに使う識別子（例: `mock_exam`）。
  final String id;
  final QuotaPeriod period;

  /// 期間あたりの上限。null なら無制限（プレミアムなど）。
  final int? limit;

  final KeyValueStore _store;
  final DateTime Function() _clock;

  String get _key => 'usage_quota.$id.${period.name}';

  String _periodKey(DateTime t) {
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return switch (period) {
      QuotaPeriod.daily => '${t.year}-$m-$d',
      QuotaPeriod.monthly => '${t.year}-$m',
    };
  }

  /// 現在の期間での使用回数。
  int get used {
    final raw = _store.read(_key);
    if (raw == null) return 0;
    final sep = raw.indexOf('|');
    if (sep < 0) return 0;
    if (raw.substring(0, sep) != _periodKey(_clock())) return 0; // 期間が変わった
    return int.tryParse(raw.substring(sep + 1)) ?? 0;
  }

  /// 残り回数。無制限なら null。
  int? get remaining => limit == null ? null : (limit! - used).clamp(0, limit!);

  bool get canUse => limit == null || used < limit!;

  /// 使えるなら1回分を消費して true。上限なら何もせず false。
  Future<bool> tryConsume() async {
    if (!canUse) return false;
    await _store.write(_key, '${_periodKey(_clock())}|${used + 1}');
    return true;
  }
}
