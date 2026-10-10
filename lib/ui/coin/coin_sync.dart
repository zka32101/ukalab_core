/// コイン台帳の共通アカウント同期。
///
/// Firebase には直接依存しない。サーバーとの読み書きは [CoinRemote] をアプリ側が実装して渡す
/// （Firestore などに `CoinLedger.toJson()` をそのまま保存すればよい）。
library;

import 'coin_ledger.dart';
import 'coin_service.dart';

/// サーバー側の台帳の保存先（アプリ側が実装する）。
abstract class CoinRemote {
  /// 保存済みの台帳。まだ無ければ null。
  Future<List<dynamic>?> readLedger();

  Future<void> writeLedger(List<Map<String, dynamic>> json);
}

class InMemoryCoinRemote implements CoinRemote {
  List<dynamic>? _ledger;

  @override
  Future<List<dynamic>?> readLedger() async => _ledger;

  @override
  Future<void> writeLedger(List<Map<String, dynamic>> json) async => _ledger = json;
}

enum CoinSyncResult { synced, failed }

/// 端末の台帳とサーバーの台帳を統合して、双方に書き戻す。
///
/// 台帳の各行は id で一意なので、何度同期しても二重にならない。
/// 失敗しても端末内の台帳は変えない（次回やり直せる）。
class CoinSync {
  CoinSync({required this.service, required this.remote});

  final CoinService service;
  final CoinRemote remote;

  Future<CoinSyncResult> sync() async {
    try {
      final raw = await remote.readLedger();
      if (raw != null) {
        await service.mergeLedger(CoinLedger.fromJson(raw));
      }
      await remote.writeLedger(service.ledger.toJson());
      return CoinSyncResult.synced;
    } catch (_) {
      return CoinSyncResult.failed;
    }
  }
}
