import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 問題ごとの自分用メモ（qid → メモ本文）の保存先。
abstract class QuestionMemoStore {
  Future<Map<String, String>> read();
  Future<void> write(Map<String, String> memos);
}

/// 端末内（SharedPreferences）への保存。キーは `ukalab_<アプリID>_question_memos`。
class SharedPreferencesQuestionMemoStore implements QuestionMemoStore {
  SharedPreferencesQuestionMemoStore(this.appId);

  final String appId;

  String get _key => 'ukalab_${appId}_question_memos';

  @override
  Future<Map<String, String>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> write(Map<String, String> memos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(memos));
  }
}

/// 問題メモの読み込み・更新。`main()` で `load()` してから
/// [questionMemoServiceProvider] を `overrideWithValue` で渡す。
class QuestionMemoService {
  QuestionMemoService({required QuestionMemoStore store}) : _store = store;

  final QuestionMemoStore _store;
  Map<String, String> _memos = {};

  Map<String, String> get memos => _memos;

  Future<void> load() async {
    _memos = await _store.read();
  }

  /// メモを保存する。空文字（トリム後）なら削除する。
  Future<Map<String, String>> setMemo({required String qid, required String memo}) async {
    final trimmed = memo.trim();
    _memos = {..._memos};
    if (trimmed.isEmpty) {
      _memos.remove(qid);
    } else {
      _memos[qid] = trimmed;
    }
    await _store.write(_memos);
    return _memos;
  }

  /// 学習記録のリセット時に呼ぶ。初期状態に戻す。
  Future<Map<String, String>> reset() async {
    _memos = {};
    await _store.write(_memos);
    return _memos;
  }

  /// バックアップの読み込み時に呼ぶ。[memos] で上書きする。
  Future<Map<String, String>> restore(Map<String, String> memos) async {
    _memos = memos;
    await _store.write(_memos);
    return _memos;
  }
}

final questionMemoServiceProvider = Provider<QuestionMemoService>(
  (ref) => throw UnimplementedError('questionMemoServiceProvider を override してください'),
);

class QuestionMemoNotifier extends Notifier<Map<String, String>> {
  QuestionMemoService get _s => ref.read(questionMemoServiceProvider);

  @override
  Map<String, String> build() => _s.memos;

  Future<void> setMemo({required String qid, required String memo}) async {
    state = await _s.setMemo(qid: qid, memo: memo);
  }

  Future<void> reset() async {
    state = await _s.reset();
  }

  Future<void> restore(Map<String, String> memos) async {
    state = await _s.restore(memos);
  }
}

final questionMemoProvider =
    NotifierProvider<QuestionMemoNotifier, Map<String, String>>(QuestionMemoNotifier.new);
