import '../question/question.dart' show QuestionSource;
import '../src/json_util.dart';

/// Transformerの注意の可視化（画期的な機能5）の1場面。
///
/// 体験: 短い文の単語同士の注意（Attention）の強さを線の太さで見る。
/// [attention]は教育用に用意した固定データで、実モデルの出力ではない
/// （UI層で明記する）。描画自体はUI層（`AttentionVizWidget`）で行い、
/// ここはトークンと注意行列だけを持つ。
class AttentionVizScenario {
  const AttentionVizScenario({
    required this.scenarioId,
    required this.examId,
    required this.title,
    required this.description,
    required this.tokens,
    required this.attention,
    required this.source,
    required this.sourceRef,
    required this.contentVer,
    this.subjectId,
    this.disabled = false,
  });

  final String scenarioId;
  final String examId;

  /// null なら分野を問わない。
  final String? subjectId;

  final String title;
  final String description;

  /// 文を分割した単語（トークン）。
  final List<String> tokens;

  /// 注意行列。`attention[i][j]` は、トークン i（query）がトークン j（key）
  /// に向ける注意の強さ（0.0〜1.0）。各行の合計はおよそ1.0になる
  /// （softmaxの出力を模した固定値のため）。
  final List<List<double>> attention;

  final QuestionSource source;
  final String sourceRef;
  final String contentVer;
  final bool disabled;

  factory AttentionVizScenario.fromJson(Map<String, dynamic> j) {
    final scenarioId = reqString(j, 'scenarioId', 'attentionVizScenario');
    final where = 'attentionVizScenario[$scenarioId]';

    final sourceName = reqString(j, 'source', where);
    final source = QuestionSource.values.where((s) => s.name == sourceName);
    if (source.isEmpty) {
      fail(where, '"source" は original / statute / licensed のいずれか');
    }

    final rawTokens = j['tokens'];
    if (rawTokens is! List || rawTokens.isEmpty) {
      fail(where, '"tokens" は空でない配列が必要です');
    }
    final tokens = <String>[
      for (final t in rawTokens)
        if (t is String && t.trim().isNotEmpty) t else fail(where, '"tokens" の要素は空でない文字列が必要です'),
    ];

    final rawAttention = j['attention'];
    if (rawAttention is! List || rawAttention.isEmpty) {
      fail(where, '"attention" は空でない配列が必要です');
    }
    final attention = <List<double>>[
      for (final row in rawAttention)
        if (row is List && row.isNotEmpty)
          [
            for (final v in row)
              if (v is num) v.toDouble() else fail(where, '"attention" の値は数値が必要です'),
          ]
        else
          fail(where, '"attention" の各行は空でない配列が必要です'),
    ];

    return AttentionVizScenario(
      scenarioId: scenarioId,
      examId: reqString(j, 'examId', where),
      subjectId: optString(j, 'subjectId', where),
      title: reqString(j, 'title', where),
      description: reqString(j, 'description', where),
      tokens: tokens,
      attention: attention,
      source: source.first,
      sourceRef: reqString(j, 'sourceRef', where),
      contentVer: reqString(j, 'contentVer', where),
      disabled: j['disabled'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'scenarioId': scenarioId,
        'examId': examId,
        if (subjectId != null) 'subjectId': subjectId,
        'title': title,
        'description': description,
        'tokens': tokens,
        'attention': attention,
        'source': source.name,
        'sourceRef': sourceRef,
        'contentVer': contentVer,
        if (disabled) 'disabled': true,
      };
}
