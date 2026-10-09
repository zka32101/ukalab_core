import 'dart:math' as math;

import '../question/question.dart';
import 'progress_record.dart';

/// 弱点スコアの重み。値は暫定で、公開後の実測で調整する（企画: 追加差別化機能 §2）。
class WeakScoreConfig {
  const WeakScoreConfig({
    this.halfLifeDays = 14,
    this.slowCorrectMs = 20000,
    this.slowCorrectPenalty = 0.5,
    this.priorWeight = 1.0,
    this.causeWeights = const {
      WrongCause.knowledge: 1.0,
      WrongCause.trap: 1.0,
      WrongCause.calculation: 1.0,
      WrongCause.misread: 0.8,
    },
  });

  /// 解答の重みが半分になる日数（直近の解答ほど重い）。
  final double halfLifeDays;

  /// これ以上かかった正解は「遅い正解」として弱点の候補に入れる（ミリ秒）。
  final int slowCorrectMs;

  /// 遅い正解を、誤答1回に対してどれだけの弱さとみなすか（0〜1）。
  final double slowCorrectPenalty;

  /// 解答が少ない論点のスコアが極端にならないようにする分母の底上げ。
  final double priorWeight;

  /// 原因ラベルごとの誤答の重み。ラベルなし・未登録は 1.0。
  final Map<WrongCause, double> causeWeights;

  double weightOf(WrongCause? cause) =>
      cause == null ? 1.0 : (causeWeights[cause] ?? 1.0);
}

/// 弱点の処方（原因別に、どの練習へ誘導するか）。
enum WeakPrescription {
  /// 知識不足: 解説と用語カードへ。
  studyExplanation,

  /// ひっかけ: 違いの比較表示を先に見せる。
  compareFirst,

  /// 計算ミス: 計算ステップの練習。
  calculationSteps,

  /// 読み違い: 問題文のポイントに印をつける練習。
  markKeyPoints,
}

WeakPrescription? prescriptionFor(WrongCause? cause) => switch (cause) {
      WrongCause.knowledge => WeakPrescription.studyExplanation,
      WrongCause.trap => WeakPrescription.compareFirst,
      WrongCause.calculation => WeakPrescription.calculationSteps,
      WrongCause.misread => WeakPrescription.markKeyPoints,
      null => null,
    };

/// 弱点の論点1件（章、または章＋細目）。
class WeakTopic {
  const WeakTopic({
    required this.chapterId,
    required this.score,
    required this.attempts,
    required this.misses,
    this.subtopicId,
    this.causeCounts = const {},
  });

  final String chapterId;

  /// 細目。章単位の集計（`byChapter: true`）では null。
  final String? subtopicId;

  /// 0〜1に近いほど弱い。
  final double score;

  /// 解答の回数と、そのうち誤答の回数。
  final int attempts;
  final int misses;

  /// 誤答の原因ラベルの内訳（ラベルを付けた誤答のみ）。
  final Map<WrongCause, int> causeCounts;

  String get key => subtopicId == null ? chapterId : '$chapterId/$subtopicId';

  /// 最も多い誤答の原因。同数なら [WrongCause] の定義順。ラベルがなければ null。
  WrongCause? get dominantCause {
    WrongCause? best;
    var bestCount = 0;
    for (final cause in WrongCause.values) {
      final n = causeCounts[cause] ?? 0;
      if (n > bestCount) {
        best = cause;
        bestCount = n;
      }
    }
    return best;
  }

  /// 原因に応じた処方。原因ラベルがなければ null。
  WeakPrescription? get prescription => prescriptionFor(dominantCause);
}

class _Accumulator {
  _Accumulator(this.chapterId, this.subtopicId);

  final String chapterId;
  final String? subtopicId;
  double weight = 0;
  double weakness = 0;
  int attempts = 0;
  int misses = 0;
  final Map<WrongCause, int> causes = {};
}

/// 解答記録から、弱い論点を弱い順に並べる。
///
/// スコア = Σ(解答の重み × 弱さ) ÷ (Σ解答の重み + [WeakScoreConfig.priorWeight])。
/// 解答の重みは新しいほど大きく（半減期 [WeakScoreConfig.halfLifeDays]）、
/// 弱さは誤答なら原因ラベルの重み、遅い正解なら [WeakScoreConfig.slowCorrectPenalty]、
/// 速い正解なら 0。弱さが 0 の論点は結果に含めない。
///
/// 論点は細目があれば章＋細目、なければ章。[byChapter] が true なら細目を無視して
/// 章単位で集計する（表示用）。旧データなどで記録に論点が無い場合は、[questions] から
/// qid で補う。それでも論点が分からない記録は数えない。
List<WeakTopic> computeWeakTopics(
  List<ProgressRecord> records, {
  required DateTime now,
  WeakScoreConfig config = const WeakScoreConfig(),
  List<Question> questions = const [],
  bool byChapter = false,
}) {
  final byQid = {for (final q in questions) q.qid: q};
  final acc = <String, _Accumulator>{};

  for (final r in records) {
    final q = byQid[r.qid];
    final chapter = r.topicId ?? q?.topicId;
    if (chapter == null) continue;
    final sub = byChapter
        ? null
        : (r.topicId != null ? r.subtopicId : q?.subtopicId);
    final key = sub == null ? chapter : '$chapter/$sub';

    final ageDays = math.max(0, now.difference(r.at).inMinutes) / 1440.0;
    final weight = math.pow(0.5, ageDays / config.halfLifeDays).toDouble();

    final double weakness;
    if (!r.correct) {
      weakness = config.weightOf(r.cause);
    } else if (r.ms != null && r.ms! >= config.slowCorrectMs) {
      weakness = config.slowCorrectPenalty;
    } else {
      weakness = 0;
    }

    final a = acc.putIfAbsent(key, () => _Accumulator(chapter, sub));
    a.weight += weight;
    a.weakness += weight * weakness;
    a.attempts++;
    if (!r.correct) {
      a.misses++;
      final cause = r.cause;
      if (cause != null) a.causes[cause] = (a.causes[cause] ?? 0) + 1;
    }
  }

  final topics = [
    for (final a in acc.values)
      if (a.weakness > 0)
        WeakTopic(
          chapterId: a.chapterId,
          subtopicId: a.subtopicId,
          score: a.weakness / (a.weight + config.priorWeight),
          attempts: a.attempts,
          misses: a.misses,
          causeCounts: Map.unmodifiable(a.causes),
        ),
  ];
  topics.sort((x, y) {
    final byScore = y.score.compareTo(x.score);
    if (byScore != 0) return byScore;
    final byAttempts = y.attempts.compareTo(x.attempts);
    if (byAttempts != 0) return byAttempts;
    return x.key.compareTo(y.key);
  });
  return topics;
}
