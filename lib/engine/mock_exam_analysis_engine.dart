/// 模擬試験（または任意の回答履歴）の1問ぶんの結果。個人情報・問題文は持たない。
class MockExamAnswer {
  const MockExamAnswer({required this.topicId, required this.correct});

  /// 分野ID（アプリ側の章・科目ID）。
  final String topicId;
  final bool correct;
}

/// 分野ごとの集計。
class MockExamTopicScore {
  const MockExamTopicScore({
    required this.topicId,
    required this.answered,
    required this.correct,
  });

  final String topicId;
  final int answered;
  final int correct;

  /// 正答率 0.0〜1.0（解いていなければ 0）。
  double get accuracy => answered == 0 ? 0 : correct / answered;
}

/// 分析結果。
class MockExamAnalysis {
  const MockExamAnalysis({
    required this.answered,
    required this.correct,
    required this.topics,
    required this.weakTopics,
    required this.nextTopics,
  });

  final int answered;
  final int correct;

  /// 全分野（分野ID順）。
  final List<MockExamTopicScore> topics;

  /// 伸びしろのある分野（正答率の低い順）。
  final List<MockExamTopicScore> weakTopics;

  /// 次にやるとよい分野（最大 [MockExamAnalysisEngine.nextCount] 件。正答率の低い順）。
  final List<MockExamTopicScore> nextTopics;

  bool get isEmpty => answered == 0;
  double get accuracy => answered == 0 ? 0 : correct / answered;
}

/// 回答リストから分野別の正答率・弱点分野・次にやる分野を出す純粋ロジック（時刻・保存・UIに依存しない）。
///
/// 保存が必要なら、アプリ側が結果リストを自分で保存して渡す（このエンジンは何も保存しない）。
class MockExamAnalysisEngine {
  const MockExamAnalysisEngine({
    this.minSamples = 2,
    this.weakThreshold = 0.7,
    this.masteredThreshold = 0.9,
    this.nextCount = 3,
  })  : assert(minSamples >= 1),
        assert(nextCount >= 1 && nextCount <= 3);

  /// 弱点判定に必要な最小の解答数（少なすぎる分野は決めつけない）。
  final int minSamples;

  /// この正答率を下回る分野を弱点とする。
  final double weakThreshold;

  /// この正答率以上の分野は「次にやる分野」に入れない。
  final double masteredThreshold;

  /// 「次にやる分野」の最大件数（1〜3）。
  final int nextCount;

  MockExamAnalysis analyze(Iterable<MockExamAnswer> answers) {
    final answered = <String, int>{};
    final correct = <String, int>{};
    var total = 0;
    var totalCorrect = 0;
    for (final a in answers) {
      if (a.topicId.isEmpty) continue;
      answered[a.topicId] = (answered[a.topicId] ?? 0) + 1;
      total++;
      if (a.correct) {
        correct[a.topicId] = (correct[a.topicId] ?? 0) + 1;
        totalCorrect++;
      }
    }
    final ids = answered.keys.toList()..sort();
    final topics = [
      for (final id in ids)
        MockExamTopicScore(topicId: id, answered: answered[id]!, correct: correct[id] ?? 0),
    ];
    int byLow(MockExamTopicScore a, MockExamTopicScore b) {
      final c = a.accuracy.compareTo(b.accuracy);
      if (c != 0) return c;
      final d = b.answered.compareTo(a.answered); // 解答数が多い方（確からしい方）を先に
      return d != 0 ? d : a.topicId.compareTo(b.topicId);
    }

    final weak = topics
        .where((t) => t.answered >= minSamples && t.accuracy < weakThreshold)
        .toList()
      ..sort(byLow);
    final next = (topics.where((t) => t.accuracy < masteredThreshold).toList()..sort(byLow))
        .take(nextCount)
        .toList();
    return MockExamAnalysis(
      answered: total,
      correct: totalCorrect,
      topics: topics,
      weakTopics: weak,
      nextTopics: next,
    );
  }
}
