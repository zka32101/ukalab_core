import 'package:cloud_firestore/cloud_firestore.dart';

import 'learning_transfer.dart';

/// 学習の引き継ぎの Firestore 実装（共通アカウント）。
///
/// 保存先は `users/{uid}/exams/{examId}/transfer/{partId}`。共通ルール
/// （`firebase/firestore.rules` の `users/{uid}/exams/{examId}/…`）に含まれるので、
/// ルールの変更は要らない（本人だけが読み書きでき、examId は登録済みの資格だけ）。
///
/// - [uid] は Firebase Auth の uid。匿名 → Google/Apple へのリンクでも変わらないので、
///   機種変更後に同じアカウントでログインすれば同じ内容を読める。
/// - 部品は1ドキュメント（`{data: ..., updatedAt: ...}`）。Firestore の1MB上限を超える部品は
///   書き込みに失敗する（[LearningTransfer.backup] が `failed` に入れる）。学習履歴が大きい
///   アプリは、部品を分けるか、日付で切り分けて渡す。
///
/// 失敗（オフライン等）は例外のまま投げる。[LearningTransfer] が受けて結果にまとめる。
class FirebaseTransferRemote implements TransferRemote {
  FirebaseTransferRemote({
    required this.uid,
    required this.examId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final String examId;
  final FirebaseFirestore _firestore;

  /// 保存先のパス。
  static String docPath(String uid, String examId, String partId) =>
      'users/$uid/exams/$examId/transfer/$partId';

  DocumentReference<Map<String, dynamic>> _ref(String partId) =>
      _firestore.doc(docPath(uid, examId, partId));

  @override
  Future<Object?> readPart(String partId) async => (await _ref(partId).get()).data()?['data'];

  @override
  Future<void> writePart(String partId, Object? json) =>
      _ref(partId).set({'data': json, 'updatedAt': FieldValue.serverTimestamp()});
}
