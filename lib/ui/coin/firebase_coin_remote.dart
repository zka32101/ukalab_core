import 'package:cloud_firestore/cloud_firestore.dart';

import 'coin_sync.dart';

/// コイン台帳の Firestore 実装（共通アカウントでの同期用）。
///
/// 保存先は `users/{uid}/exams/{examId}/coin/ledger`。共通ルール
/// （`firebase/firestore.rules` の `users/{uid}/exams/{examId}/…`）に含まれるので、
/// ルールの変更は要らない（本人だけが読み書きでき、examId は登録済みの資格だけ）。
///
/// - [uid] は Firebase Auth の uid。匿名 → Google/Apple へのリンクでも変わらない。
/// - [examId] はそのアプリの資格 ID（`UkalabCert.id`）。財布はアプリごと。
/// - 台帳は1ドキュメントの配列で持つ（Firestore の1MB上限。1行 約150バイトで 6,000行ほど）。
///   学習コインは1日の上限があるため、通常は十分収まる。
///
/// 失敗（オフライン等）は例外のまま投げる。[CoinSync.sync] が受けて `failed` を返す。
class FirebaseCoinRemote implements CoinRemote {
  FirebaseCoinRemote({
    required this.uid,
    required this.examId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final String examId;
  final FirebaseFirestore _firestore;

  /// 保存先のパス。
  static String docPath(String uid, String examId) => 'users/$uid/exams/$examId/coin/ledger';

  DocumentReference<Map<String, dynamic>> get _ref => _firestore.doc(docPath(uid, examId));

  @override
  Future<List<dynamic>?> readLedger() async {
    final data = (await _ref.get()).data();
    final entries = data?['entries'];
    return entries is List ? entries : null;
  }

  @override
  Future<void> writeLedger(List<Map<String, dynamic>> json) =>
      _ref.set({'entries': json, 'updatedAt': FieldValue.serverTimestamp()});
}
