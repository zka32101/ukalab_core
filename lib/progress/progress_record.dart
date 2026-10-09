/// 間違えた理由（原因ラベル）。解答後に利用者が自分で選ぶ。
/// 計算のない資格では [calculation] を選択肢に出さない。
enum WrongCause {
  /// 知識不足。
  knowledge,

  /// ひっかけ。
  trap,

  /// 計算ミス。
  calculation,

  /// 読み違い。
  misread,
}

/// 1問分の解答記録（演習・模擬試験どちらの解答でも共通で使う）。
class ProgressRecord {
  const ProgressRecord({
    required this.qid,
    required this.subjectId,
    required this.correct,
    required this.at,
    this.topicId,
    this.subtopicId,
    this.ms,
    this.cause,
  });

  final String qid;
  final String subjectId;
  final bool correct;
  final DateTime at;

  /// 論点タグの章・細目（[Question.topicId]・[Question.subtopicId]）。弱点の集計用。
  /// 旧データには無いため省略可能。
  final String? topicId;
  final String? subtopicId;

  /// 回答にかかった時間（ミリ秒）。遅い正解も弱点の候補にするために使う。
  final int? ms;

  /// 間違えた理由。正解の記録や、選ばなかった場合は null。
  final WrongCause? cause;

  Map<String, dynamic> toJson() => {
        'qid': qid,
        'subjectId': subjectId,
        'correct': correct,
        'at': at.toIso8601String(),
        if (topicId != null) 'topicId': topicId,
        if (subtopicId != null) 'subtopicId': subtopicId,
        if (ms != null) 'ms': ms,
        if (cause != null) 'cause': cause!.name,
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
    final topicId = json['topicId'];
    final subtopicId = json['subtopicId'];
    final ms = json['ms'];
    final causeName = json['cause'];
    WrongCause? cause;
    for (final c in WrongCause.values) {
      if (c.name == causeName) cause = c;
    }
    return ProgressRecord(
      qid: qid,
      subjectId: subjectId,
      correct: correct,
      at: at,
      // 追加項目は型が合わないときだけ捨てる（旧データ・一部破損でも読めた分は復元する）。
      topicId: topicId is String ? topicId : null,
      subtopicId: subtopicId is String ? subtopicId : null,
      ms: ms is int ? ms : null,
      cause: cause,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProgressRecord &&
      other.qid == qid &&
      other.subjectId == subjectId &&
      other.correct == correct &&
      other.at == at &&
      other.topicId == topicId &&
      other.subtopicId == subtopicId &&
      other.ms == ms &&
      other.cause == cause;

  @override
  int get hashCode =>
      Object.hash(qid, subjectId, correct, at, topicId, subtopicId, ms, cause);

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
