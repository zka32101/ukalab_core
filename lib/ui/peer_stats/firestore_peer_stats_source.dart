import 'package:cloud_firestore/cloud_firestore.dart';

import '../../peer/peer_stats.dart';
import '../../peer/peer_stats_source.dart';

/// 匿名集計の Firestore 実装（読むだけ）。`peer_summaries/{examId}` を1回読む。
///
/// 要約はサーバ側（Cloud Function）が書く。端末からは書かない。
/// ルール案・構造は `docs/peer_stats.md`。失敗・未集計は null。
class FirestorePeerStatsSource implements PeerStatsSource {
  FirestorePeerStatsSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static String docPath(String examId) => 'peer_summaries/$examId';

  @override
  Future<PeerStatsSnapshot?> fetch({required String examId}) async {
    try {
      final data = (await _firestore.doc(docPath(examId)).get()).data();
      return data == null ? null : PeerStatsSnapshot.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
