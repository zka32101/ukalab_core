import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_common_kit/parental_gate.dart';

import '../../peer/peer_stats_sender.dart';

/// installId を shared_preferences に保存する（端末ローカルのみ。アプリを消すと失われる）。
class SharedPrefsInstallIdStore implements InstallIdStore {
  SharedPrefsInstallIdStore({this.key = 'ukalab_peer_install_id'});
  final String key;

  @override
  Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(key);
    if (saved != null && InstallId.isValid(saved)) return saved;
    final id = InstallId.generate();
    await prefs.setString(key, id);
    return id;
  }

  @override
  Future<void> clear() async => (await SharedPreferences.getInstance()).remove(key);
}

class SharedPrefsPeerSentDateStore implements PeerSentDateStore {
  SharedPrefsPeerSentDateStore({this.keyPrefix = 'ukalab_peer_sent_'});
  final String keyPrefix;

  @override
  Future<String?> read(String examId) async =>
      (await SharedPreferences.getInstance()).getString('$keyPrefix$examId');

  @override
  Future<void> write(String examId, String dateKey) async =>
      (await SharedPreferences.getInstance()).setString('$keyPrefix$examId', dateKey);
}

/// app_common_kit の保護者ゲート（`requireParentalGate`）を再利用する [PeerStatsGate]。
///
/// [request] でダイアログを出し、正解したら許可を端末に記録する。以降の [isAllowed] は記録を見るだけ
/// （送信のたびにダイアログは出ない）。参加をオフにしたら [revoke] で記録を消す。
class ParentalPeerStatsGate implements PeerStatsGate {
  ParentalPeerStatsGate({
    required this.contextProvider,
    this.strings = ParentalGateStrings.ja,
    this.key = 'ukalab_peer_gate_passed',
  });

  /// ダイアログを出すための `BuildContext`（`navigatorKey.currentContext` など）。null なら通さない。
  final BuildContext? Function() contextProvider;
  final ParentalGateStrings strings;
  final String key;

  @override
  Future<bool> isAllowed() async => (await SharedPreferences.getInstance()).getBool(key) ?? false;

  @override
  Future<bool> request() async {
    final context = contextProvider();
    if (context == null || !context.mounted) return false;
    final ok = await requireParentalGate(context, strings: strings);
    if (ok) await (await SharedPreferences.getInstance()).setBool(key, true);
    return ok;
  }

  @override
  Future<void> revoke() async => (await SharedPreferences.getInstance()).remove(key);
}
