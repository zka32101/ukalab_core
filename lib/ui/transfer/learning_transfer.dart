/// 学習の引き継ぎ（機種変更で学習履歴・購入した衣装・コインを復元する）。
///
/// Firebase には直接依存しない。端末内のデータは [TransferSource]（部品ごと）、
/// サーバー側は [TransferRemote] をアプリが渡す。キット側の実装は
/// [FirebaseTransferRemote]（`firebase_transfer_remote.dart`）。
///
/// 復元は「統合」で行い、端末内のデータを消さない。何度実行しても二重にならない
/// （各部品の [TransferSource.importMerged] は冪等にする）。
library;

import '../coin/coin_ledger.dart';
import '../coin/coin_service.dart';
import '../outfit/outfit_service.dart';

/// 引き継ぎの部品1つ（学習履歴・コイン・衣装など）。
abstract class TransferSource {
  /// 保存先の名前（英数字とアンダースコア）。1つの [LearningTransfer] の中で一意にする。
  String get partId;

  /// サーバーに保存する内容（JSON にできる値）。
  Future<Object?> export();

  /// サーバーの内容を端末内へ統合する。端末内の既存データは消さず、冪等にする。
  Future<void> importMerged(Object? remote);
}

/// 関数で部品を作る（アプリ側の学習履歴など、キットが中身を知らないデータ用）。
class FunctionTransferSource implements TransferSource {
  FunctionTransferSource({
    required this.partId,
    required Future<Object?> Function() onExport,
    required Future<void> Function(Object? remote) onImport,
  })  : _onExport = onExport,
        _onImport = onImport;

  @override
  final String partId;
  final Future<Object?> Function() _onExport;
  final Future<void> Function(Object? remote) _onImport;

  @override
  Future<Object?> export() => _onExport();

  @override
  Future<void> importMerged(Object? remote) => _onImport(remote);
}

/// コイン台帳の部品。サーバーの台帳を統合する（id が同じ行は一度だけ数える）。
class CoinTransferSource implements TransferSource {
  CoinTransferSource(this.service);

  final CoinService service;

  @override
  String get partId => 'coin';

  @override
  Future<Object?> export() async => service.ledger.toJson();

  @override
  Future<void> importMerged(Object? remote) async {
    if (remote is List) await service.mergeLedger(CoinLedger.fromJson(remote));
  }
}

/// 衣装の解放状態の部品（合格報告・準備完了・着ている衣装）。解放済みは足し合わせる。
class OutfitTransferSource implements TransferSource {
  OutfitTransferSource(this.service);

  final OutfitService service;

  @override
  String get partId => 'outfit';

  @override
  Future<Object?> export() async => service.toStateJson();

  @override
  Future<void> importMerged(Object? remote) async {
    if (remote is Map) await service.mergeState(Map<String, dynamic>.from(remote));
  }
}

/// サーバー側の保存先（部品ごとに1か所）。
abstract class TransferRemote {
  /// 保存済みの内容。まだ無ければ null。
  Future<Object?> readPart(String partId);

  Future<void> writePart(String partId, Object? json);
}

class InMemoryTransferRemote implements TransferRemote {
  final Map<String, Object?> parts = {};

  @override
  Future<Object?> readPart(String partId) async => parts[partId];

  @override
  Future<void> writePart(String partId, Object? json) async => parts[partId] = json;
}

enum TransferStatus {
  /// すべての部品が成功した（部品が無い場合も含む）。
  success,

  /// 一部の部品だけ失敗した。成功した部品は反映済みで、失敗した部品はやり直せる。
  partial,

  /// すべての部品が失敗した。
  failed,
}

class TransferResult {
  const TransferResult({
    required this.status,
    this.succeeded = const [],
    this.failed = const [],
    this.missing = const [],
  });

  final TransferStatus status;

  /// 成功した部品の partId。
  final List<String> succeeded;

  /// 失敗した部品の partId。
  final List<String> failed;

  /// 復元のとき、サーバーにまだ保存が無かった部品（[succeeded] にも含む）。
  final List<String> missing;

  /// 復元で、どの部品もサーバーに保存が無かった（バックアップが一度も無い）。
  bool get nothingToRestore =>
      status == TransferStatus.success && succeeded.isNotEmpty && missing.length == succeeded.length;

  static TransferResult _of(List<String> ok, List<String> ng, List<String> missing) {
    final status = ng.isEmpty
        ? TransferStatus.success
        : (ok.isEmpty ? TransferStatus.failed : TransferStatus.partial);
    return TransferResult(status: status, succeeded: ok, failed: ng, missing: missing);
  }
}

/// 学習の引き継ぎ。部品ごとに保存・復元し、1つの部品の失敗で他の部品を止めない。
/// 失敗しても例外は出さず、端末内のデータは（その部品の統合が終わるまで）変えない。
class LearningTransfer {
  LearningTransfer({required this.sources, required this.remote})
      : assert(
          sources.map((s) => s.partId).toSet().length == sources.length,
          'partId が重複しています',
        );

  final List<TransferSource> sources;
  final TransferRemote remote;

  /// 端末内のデータをサーバーへ保存する。
  Future<TransferResult> backup() async {
    final ok = <String>[];
    final ng = <String>[];
    for (final s in sources) {
      try {
        await remote.writePart(s.partId, await s.export());
        ok.add(s.partId);
      } catch (_) {
        ng.add(s.partId);
      }
    }
    return TransferResult._of(ok, ng, const []);
  }

  /// サーバーの内容を端末内へ統合する（機種変更後に実行する）。
  Future<TransferResult> restore() async {
    final ok = <String>[];
    final ng = <String>[];
    final missing = <String>[];
    for (final s in sources) {
      try {
        final raw = await remote.readPart(s.partId);
        if (raw == null) {
          missing.add(s.partId);
        } else {
          await s.importMerged(raw);
        }
        ok.add(s.partId);
      } catch (_) {
        ng.add(s.partId);
      }
    }
    return TransferResult._of(ok, ng, missing);
  }
}
