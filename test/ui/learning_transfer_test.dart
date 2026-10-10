import 'package:ukalab_core/ui.dart';
import 'package:flutter_test/flutter_test.dart';

class _HalfFailingRemote extends InMemoryTransferRemote {
  _HalfFailingRemote(this.badPart);

  final String badPart;

  @override
  Future<void> writePart(String partId, Object? json) async {
    if (partId == badPart) throw Exception('offline');
    await super.writePart(partId, json);
  }

  @override
  Future<Object?> readPart(String partId) async {
    if (partId == badPart) throw Exception('offline');
    return super.readPart(partId);
  }
}

/// 学習履歴の代わりに使う、文字列のリストを持つ部品。
class _Log {
  final List<String> items = [];

  TransferSource source() => FunctionTransferSource(
        partId: 'progress',
        onExport: () async => List<String>.from(items),
        onImport: (remote) async {
          for (final e in remote as List) {
            if (!items.contains(e)) items.add(e as String);
          }
        },
      );
}

CoinService _coin(DateTime t) => CoinService(store: InMemoryCoinStore(), clock: () => t);

OutfitService _outfit() => OutfitService(store: InMemoryOutfitStore());

void main() {
  group('LearningTransfer', () {
    test('旧端末で保存し、新端末で復元すると、学習履歴・コイン・衣装が引き継がれる', () async {
      final remote = InMemoryTransferRemote();

      // 旧端末
      final oldLog = _Log()..items.addAll(['a', 'b']);
      final oldCoin = _coin(DateTime(2026, 10, 1));
      await oldCoin.grant(CoinEvent.newQuestion('q1'));
      final oldOutfit = _outfit();
      await oldOutfit.reportPassed(UkalabCert.gKentei);
      final backup = await LearningTransfer(
        sources: [oldLog.source(), CoinTransferSource(oldCoin), OutfitTransferSource(oldOutfit)],
        remote: remote,
      ).backup();
      expect(backup.status, TransferStatus.success);
      expect(backup.succeeded, ['progress', 'coin', 'outfit']);

      // 新端末（空）
      final newLog = _Log();
      final newCoin = _coin(DateTime(2026, 10, 9));
      final newOutfit = _outfit();
      final restore = await LearningTransfer(
        sources: [newLog.source(), CoinTransferSource(newCoin), OutfitTransferSource(newOutfit)],
        remote: remote,
      ).restore();

      expect(restore.status, TransferStatus.success);
      expect(newLog.items, ['a', 'b']);
      expect(newCoin.balance, oldCoin.balance);
      expect(newOutfit.passedCerts, {UkalabCert.gKentei.id});
    });

    test('何度復元しても二重にならず、端末内のデータは消えない', () async {
      final remote = InMemoryTransferRemote();
      final oldCoin = _coin(DateTime(2026, 10, 1));
      await oldCoin.grant(CoinEvent.newQuestion('q1'));
      await LearningTransfer(sources: [CoinTransferSource(oldCoin)], remote: remote).backup();

      final newCoin = _coin(DateTime(2026, 10, 9));
      await newCoin.grant(CoinEvent.newQuestion('q2'));
      final transfer = LearningTransfer(sources: [CoinTransferSource(newCoin)], remote: remote);
      await transfer.restore();
      await transfer.restore();

      expect(newCoin.ledger.entries.length, 2);
    });

    test('一部の部品が失敗しても、他の部品は反映される（partial）', () async {
      final remote = _HalfFailingRemote('coin');
      final log = _Log()..items.add('a');
      final coin = _coin(DateTime(2026, 10, 1));

      final result = await LearningTransfer(
        sources: [log.source(), CoinTransferSource(coin)],
        remote: remote,
      ).backup();

      expect(result.status, TransferStatus.partial);
      expect(result.succeeded, ['progress']);
      expect(result.failed, ['coin']);
      expect(remote.parts['progress'], ['a']);
    });

    test('すべての部品が失敗すると failed。端末内のデータは変えない', () async {
      final remote = _HalfFailingRemote('progress');
      final log = _Log()..items.add('local');

      final result = await LearningTransfer(sources: [log.source()], remote: remote).restore();

      expect(result.status, TransferStatus.failed);
      expect(log.items, ['local']);
    });

    test('サーバーに保存が無い部品は missing。全部が無ければ nothingToRestore', () async {
      final result = await LearningTransfer(
        sources: [_Log().source()],
        remote: InMemoryTransferRemote(),
      ).restore();

      expect(result.status, TransferStatus.success);
      expect(result.missing, ['progress']);
      expect(result.nothingToRestore, isTrue);
    });

    test('一部だけ保存がある場合は nothingToRestore ではない', () async {
      final remote = InMemoryTransferRemote()..parts['progress'] = ['a'];
      final log = _Log();
      final coin = _coin(DateTime(2026, 10, 1));

      final result = await LearningTransfer(
        sources: [log.source(), CoinTransferSource(coin)],
        remote: remote,
      ).restore();

      expect(result.missing, ['coin']);
      expect(result.nothingToRestore, isFalse);
      expect(log.items, ['a']);
    });

    test('部品が無ければ成功', () async {
      final transfer = LearningTransfer(sources: const [], remote: InMemoryTransferRemote());

      expect((await transfer.backup()).status, TransferStatus.success);
      expect((await transfer.restore()).status, TransferStatus.success);
    });
  });

  group('OutfitService の統合', () {
    test('合格・準備完了は足し合わせ、着ている衣装は端末内を優先する', () async {
      final a = _outfit();
      await a.reportPassed(UkalabCert.gKentei);
      final b = _outfit();
      await b.markReady(UkalabCert.boki3);

      await a.mergeState(b.toStateJson());

      expect(a.passedCerts, {UkalabCert.gKentei.id});
      expect(a.readyCerts, {UkalabCert.boki3.id});
    });

    test('着ている衣装: 端末内が未設定ならサーバーの値、設定済みなら端末内を優先', () async {
      final empty = _outfit();
      await empty.mergeState({'equipped': 'regular.g_kentei'});
      expect(empty.equippedId, 'regular.g_kentei');

      await empty.mergeState({'equipped': 'other'});
      expect(empty.equippedId, 'regular.g_kentei');
    });

    test('何度統合しても同じ', () async {
      final a = _outfit();
      final remote = {
        'passed': ['g_kentei'],
        'ready': <String>[],
      };

      await a.mergeState(remote);
      await a.mergeState(remote);

      expect(a.passedCerts, {'g_kentei'});
    });
  });

  test('保存先のパスは共通ルールの users/{uid}/exams/{examId}/… に収まる', () {
    expect(
      FirebaseTransferRemote.docPath('u1', 'g_kentei', 'progress'),
      'users/u1/exams/g_kentei/transfer/progress',
    );
  });
}
