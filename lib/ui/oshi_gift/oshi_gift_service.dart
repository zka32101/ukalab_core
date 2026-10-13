import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../oshi/oshi_gift_engine.dart';

/// 解放済みプレゼントIDの保存先（`OutfitStore` と同じ流儀）。
abstract class OshiGiftStore {
  Future<Set<String>> read();
  Future<void> write(Set<String> ids);
}

class InMemoryOshiGiftStore implements OshiGiftStore {
  Set<String> _ids = {};

  @override
  Future<Set<String>> read() async => {..._ids};

  @override
  Future<void> write(Set<String> ids) async => _ids = {...ids};
}

class SharedPreferencesOshiGiftStore implements OshiGiftStore {
  SharedPreferencesOshiGiftStore(this.appId);

  final String appId;

  String get _key => 'ukalab_oshi_gift_$appId';

  @override
  Future<Set<String>> read() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    if (s == null) return {};
    try {
      final m = jsonDecode(s) as Map;
      return {...List<String>.from((m['unlocked'] as List?) ?? const [])};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> write(Set<String> ids) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode({'unlocked': ids.toList()..sort()}));
  }
}

/// 解放済みの記録と、新規解放の判定をまとめる。
class OshiGiftService {
  OshiGiftService({required this.store, this.engine = const OshiGiftEngine()});

  final OshiGiftStore store;
  final OshiGiftEngine engine;
  final Set<String> _unlocked = {};

  Set<String> get unlockedIds => Set.unmodifiable(_unlocked);

  Future<void> load() async {
    _unlocked
      ..clear()
      ..addAll(await store.read());
  }

  bool isUnlocked(String id) => _unlocked.contains(id);

  /// 進捗を見て、新しく解放されたものを記録して返す。同じ進捗で再度呼ぶと空。
  Future<List<G>> check<G extends OshiGiftSpec>(
    OshiGiftProgress progress,
    Iterable<G> gifts,
  ) async {
    final fresh = engine.newlyUnlocked(progress: progress, gifts: gifts, alreadyUnlocked: _unlocked);
    if (fresh.isNotEmpty) {
      _unlocked.addAll(fresh.map((g) => g.id));
      await store.write(_unlocked);
    }
    return fresh;
  }
}
