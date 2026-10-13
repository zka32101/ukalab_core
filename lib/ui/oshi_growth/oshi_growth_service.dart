import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../oshi/oshi_growth_engine.dart';

/// 祝い済みの節目 ID の保存先（`OshiGiftStore` と同じ流儀）。
abstract class OshiGrowthStore {
  Future<Set<String>> read();
  Future<void> write(Set<String> ids);
}

class InMemoryOshiGrowthStore implements OshiGrowthStore {
  Set<String> _ids = {};

  @override
  Future<Set<String>> read() async => {..._ids};

  @override
  Future<void> write(Set<String> ids) async => _ids = {...ids};
}

class SharedPreferencesOshiGrowthStore implements OshiGrowthStore {
  SharedPreferencesOshiGrowthStore(this.appId);

  final String appId;

  String get _key => 'ukalab_oshi_growth_$appId';

  @override
  Future<Set<String>> read() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    if (s == null) return {};
    try {
      final m = jsonDecode(s) as Map;
      return {...List<String>.from((m['celebrated'] as List?) ?? const [])};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> write(Set<String> ids) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode({'celebrated': ids.toList()..sort()}));
  }
}

/// 祝い済みの記録と、節目到達の判定をまとめる。各節目は一度だけ祝う。
class OshiGrowthService {
  OshiGrowthService({required this.store, this.engine = const OshiGrowthEngine()});

  final OshiGrowthStore store;
  final OshiGrowthEngine engine;
  final Set<String> _celebrated = {};

  Set<String> get celebratedIds => Set.unmodifiable(_celebrated);

  Future<void> load() async {
    _celebrated
      ..clear()
      ..addAll(await store.read());
  }

  bool isCelebrated(String id) => _celebrated.contains(id);

  /// 累計を見て、新しく到達した節目を祝い済みとして記録して返す。同じ累計で再度呼ぶと空。
  /// 保存に失敗したときは記録せず例外を伝える（次回また祝える）。
  Future<List<OshiGrowthMilestone>> check(OshiGrowthProgress progress) async {
    final fresh = engine.newlyReached(progress, alreadyCelebrated: _celebrated);
    if (fresh.isEmpty) return fresh;
    await store.write({..._celebrated, ...fresh.map((m) => m.id)});
    _celebrated.addAll(fresh.map((m) => m.id));
    return fresh;
  }

  /// [check] して、まとめて迎えた節目のうち見せる 1 件を返す（無ければ null）。
  /// 久しぶりにアプリを開いて複数の節目を一度に迎えても、祝福は 1 回だけ。
  Future<OshiGrowthMilestone?> checkHeadline(OshiGrowthProgress progress) async {
    return engine.headlineOf(await check(progress));
  }
}
