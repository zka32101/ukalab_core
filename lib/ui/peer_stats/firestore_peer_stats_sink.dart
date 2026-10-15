import 'package:cloud_firestore/cloud_firestore.dart';

import '../../peer/peer_stats_sender.dart';
import '../../peer/peer_stats_source.dart';

/// Firestore への書き込みを差し替え可能にする抽象（テストではフェイク）。
abstract interface class PeerDeviceWriter {
  Future<void> set(String path, Map<String, Object?> data);
}

class FirestorePeerDeviceWriter implements PeerDeviceWriter {
  FirestorePeerDeviceWriter({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> set(String path, Map<String, Object?> data) => _firestore.doc(path).set(data);
}

/// `PeerStatsSink` の Firestore 実装。`peer_devices/{examId}/devices/{installId}` に匿名の値を 1 ドキュメント上書きする。
///
/// 書くのは `day / streakDays / totalQuestions / examDate? / updatedAt` だけ（ユーザー ID・氏名・端末情報は無し）。
/// 失敗は例外のまま投げる（呼び出し側の `PeerStatsSender` が握りつぶして次回に回す）。
class FirestorePeerStatsSink implements PeerStatsSink {
  FirestorePeerStatsSink({
    required InstallIdStore installIdStore,
    PeerDeviceWriter? writer,
    Object Function()? timestamp,
  })  : _ids = installIdStore,
        _writer = writer ?? FirestorePeerDeviceWriter(),
        _timestamp = timestamp ?? FieldValue.serverTimestamp;

  final InstallIdStore _ids;
  final PeerDeviceWriter _writer;
  final Object Function() _timestamp;

  @override
  Future<void> submit(PeerContribution contribution) async {
    final id = await _ids.getOrCreate();
    await _writer.set(
      PeerDevicePayload.path(contribution.examId, id),
      PeerDevicePayload.build(contribution, updatedAt: _timestamp()),
    );
  }
}
