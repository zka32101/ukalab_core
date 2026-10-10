import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 気になる問題のブックマーク（qid の集合）の保存先。
abstract class BookmarkStore {
  Future<Set<String>> read();
  Future<void> write(Set<String> qids);
}

/// 端末内（SharedPreferences）への保存。キーは `ukalab_<アプリID>_bookmarks`。
class SharedPreferencesBookmarkStore implements BookmarkStore {
  SharedPreferencesBookmarkStore(this.appId);

  final String appId;

  String get _key => 'ukalab_${appId}_bookmarks';

  @override
  Future<Set<String>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> write(Set<String> qids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(qids.toList()));
  }
}

/// ブックマークの読み込み・切り替え。`main()` で `load()` してから
/// [bookmarkServiceProvider] を `overrideWithValue` で渡す。
class BookmarkService {
  BookmarkService({required BookmarkStore store}) : _store = store;

  final BookmarkStore _store;
  Set<String> _qids = {};

  Set<String> get qids => _qids;

  Future<void> load() async {
    _qids = await _store.read();
  }

  /// ブックマークのアイコンをタップしたときに呼ぶ。追加済みなら外し、無ければ追加する。
  Future<Set<String>> toggle(String qid) async {
    _qids = {..._qids};
    if (!_qids.remove(qid)) _qids.add(qid);
    await _store.write(_qids);
    return _qids;
  }
}

final bookmarkServiceProvider = Provider<BookmarkService>(
  (ref) => throw UnimplementedError('bookmarkServiceProvider を override してください'),
);

class BookmarkNotifier extends Notifier<Set<String>> {
  BookmarkService get _s => ref.read(bookmarkServiceProvider);

  @override
  Set<String> build() => _s.qids;

  Future<void> toggle(String qid) async {
    state = await _s.toggle(qid);
  }
}

final bookmarkProvider = NotifierProvider<BookmarkNotifier, Set<String>>(BookmarkNotifier.new);
