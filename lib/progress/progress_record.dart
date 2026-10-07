/// 1問分の解答記録（演習・模擬試験どちらの解答でも共通で使う）。
class ProgressRecord {
  const ProgressRecord({
    required this.qid,
    required this.subjectId,
    required this.correct,
    required this.at,
  });

  final String qid;
  final String subjectId;
  final bool correct;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'qid': qid,
        'subjectId': subjectId,
        'correct': correct,
        'at': at.toIso8601String(),
      };

  /// 壊れた・不正な入力は null を返す（[fail] で例外にはしない。端末内の
  /// 保存データが将来のアプリ更新などで一部壊れていても、読めた分だけ
  /// 復元できるようにするため）。
  static ProgressRecord? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final qid = json['qid'];
    final subjectId = json['subjectId'];
    final correct = json['correct'];
    final at = DateTime.tryParse('${json['at']}');
    if (qid is! String || subjectId is! String || correct is! bool || at == null) {
      return null;
    }
    return ProgressRecord(qid: qid, subjectId: subjectId, correct: correct, at: at);
  }

  @override
  bool operator ==(Object other) =>
      other is ProgressRecord &&
      other.qid == qid &&
      other.subjectId == subjectId &&
      other.correct == correct &&
      other.at == at;

  @override
  int get hashCode => Object.hash(qid, subjectId, correct, at);

  @override
  String toString() => 'ProgressRecord($qid, $subjectId, correct: $correct, $at)';
}

/// 解答記録の保存先。永続化の実装（端末内ストレージ等）はアプリ側が持つ
/// （このコアは純Dartで、Flutterプラグインに依存しないため）。
abstract class ProgressStore {
  Future<List<ProgressRecord>> loadRecords();
  Future<void> addRecord(ProgressRecord record);

  /// 保存済みの解答記録をすべて消す（設定画面のリセット機能用）。
  Future<void> clearRecords();
}

/// テスト・プレビュー用のインメモリ実装。
class InMemoryProgressStore implements ProgressStore {
  final List<ProgressRecord> _records = [];

  @override
  Future<List<ProgressRecord>> loadRecords() async => List.unmodifiable(_records);

  @override
  Future<void> addRecord(ProgressRecord record) async => _records.add(record);

  @override
  Future<void> clearRecords() async => _records.clear();
}
