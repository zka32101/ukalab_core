import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../progress/mastery_streak.dart';
import '../data_management/data_management.dart';

/// 連続正解数・除外済み qid の保存先（`MistakeNoteStore` と同じ流儀）。
/// 解答履歴（件数上限あり）とは別の専用ストアなので、履歴が上限を超えても保持される。
/// 保存するのは問題IDと数のみ（問題文・個人情報は保存しない）。
abstract class MasteryStore {
  Future<MasteryStreak> read();
  Future<void> write(MasteryStreak value);

  /// 「正解済みの問題を出さない」の ON/OFF。既定は OFF（安全側）。
  /// 設定値なので、学習データのリセットでは変えない。
  Future<bool> readEnabled();
  Future<void> writeEnabled(bool value);
}

/// テスト・プレビュー用のインメモリ実装。
class InMemoryMasteryStore implements MasteryStore {
  MasteryStreak _value = MasteryStreak.empty;
  bool _enabled = false;

  @override
  Future<MasteryStreak> read() async => _value;

  @override
  Future<void> write(MasteryStreak value) async => _value = value;

  @override
  Future<bool> readEnabled() async => _enabled;

  @override
  Future<void> writeEnabled(bool value) async => _enabled = value;
}

/// 保存値を復元する。null・壊れた値は空として扱う。
MasteryStreak decodeMasteryStreak(String? raw) {
  if (raw == null) return MasteryStreak.empty;
  try {
    return MasteryStreak.fromJson(jsonDecode(raw));
  } catch (_) {
    return MasteryStreak.empty;
  }
}

String encodeMasteryStreak(MasteryStreak v) => jsonEncode(v.toJson());

/// 端末内（SharedPreferences）への保存。
/// キーは `ukalab_<アプリID>_streak_v1`（連続数・除外）と `ukalab_<アプリID>_streak_enabled_v1`（ON/OFF）。
class SharedPreferencesMasteryStore implements MasteryStore {
  SharedPreferencesMasteryStore(this.appId);

  final String appId;

  String get _key => 'ukalab_${appId}_streak_v1';
  String get _enabledKey => 'ukalab_${appId}_streak_enabled_v1';

  @override
  Future<MasteryStreak> read() async {
    final p = await SharedPreferences.getInstance();
    return decodeMasteryStreak(p.getString(_key));
  }

  @override
  Future<void> write(MasteryStreak value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, encodeMasteryStreak(value));
  }

  @override
  Future<bool> readEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_enabledKey) ?? false;
  }

  @override
  Future<void> writeEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_enabledKey, value);
  }
}

/// 連続数・除外をバックアップ・リセットの対象にする部品（キーは `masteryStreak`）。
/// ON/OFF の設定はバックアップ・リセットの対象外。
DataPart masteryStreakDataPart(MasteryStore store, {void Function()? onChanged}) => DataPart(
      id: 'masteryStreak',
      export: (ref) async => (await store.read()).toJson(),
      restore: (ref, json) async {
        await store.write(MasteryStreak.fromJson(json));
        onChanged?.call();
      },
      reset: (ref) async {
        await store.write(MasteryStreak.empty);
        onChanged?.call();
      },
    );
