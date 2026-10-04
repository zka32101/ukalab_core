import '../question/question.dart' show QuestionSource;
import '../src/json_util.dart';

/// 学習曲線の1点（型⑦、決定76）。エポックごとの訓練・検証誤差。
class LearningCurvePoint {
  const LearningCurvePoint({
    required this.epoch,
    required this.trainLoss,
    required this.valLoss,
  });

  final int epoch;
  final double trainLoss;
  final double valLoss;

  factory LearningCurvePoint.fromJson(Map<String, dynamic> j, String where) {
    return LearningCurvePoint(
      epoch: reqInt(j, 'epoch', where),
      trainLoss: reqNum(j, 'trainLoss', where),
      valLoss: reqNum(j, 'valLoss', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'epoch': epoch,
        'trainLoss': trainLoss,
        'valLoss': valLoss,
      };
}

/// 症状・処方の選択肢1つ。
class FailureOption {
  const FailureOption({
    required this.optionId,
    required this.text,
    required this.isCorrect,
  });

  final String optionId;
  final String text;
  final bool isCorrect;

  factory FailureOption.fromJson(Map<String, dynamic> j, String where) {
    return FailureOption(
      optionId: reqString(j, 'optionId', where),
      text: reqString(j, 'text', where),
      isCorrect: j['isCorrect'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'optionId': optionId,
        'text': text,
        'isCorrect': isCorrect,
      };
}

/// 学習の失敗図鑑（型⑦、決定76）の1症例。
///
/// 体験: [curve]（訓練・検証誤差のグラフ）を見て [symptomOptions] から
/// 症状（過学習・未学習など）を当てる→正解すると [treatmentOptions] から
/// 処方（対策）を選ぶ→[explanation] を見る。
class FailureCase {
  const FailureCase({
    required this.caseId,
    required this.examId,
    required this.curve,
    required this.symptomOptions,
    required this.treatmentOptions,
    required this.explanation,
    required this.source,
    required this.sourceRef,
    required this.contentVer,
    this.subjectId,
    this.disabled = false,
  });

  final String caseId;
  final String examId;

  /// null なら分野を問わない。
  final String? subjectId;

  final List<LearningCurvePoint> curve;

  /// 症状の選択肢。ちょうど1つが正解。
  final List<FailureOption> symptomOptions;

  /// 処方（対策）の選択肢。ちょうど1つが正解。
  final List<FailureOption> treatmentOptions;

  /// 症状・処方の両方に正解したあとに見せる解説。
  final String explanation;

  final QuestionSource source;
  final String sourceRef;
  final String contentVer;
  final bool disabled;

  FailureOption get correctSymptom =>
      symptomOptions.firstWhere((o) => o.isCorrect);

  FailureOption get correctTreatment =>
      treatmentOptions.firstWhere((o) => o.isCorrect);

  factory FailureCase.fromJson(Map<String, dynamic> j) {
    final caseId = reqString(j, 'caseId', 'failureCase');
    final where = 'failureCase[$caseId]';

    final sourceName = reqString(j, 'source', where);
    final source = QuestionSource.values.where((s) => s.name == sourceName);
    if (source.isEmpty) {
      fail(where, '"source" は original / statute / licensed のいずれか');
    }

    final curve = reqObjectList(j, 'curve', where)
        .map((p) => LearningCurvePoint.fromJson(p, where))
        .toList();
    final symptomOptions = reqObjectList(j, 'symptomOptions', where)
        .map((o) => FailureOption.fromJson(o, where))
        .toList();
    final treatmentOptions = reqObjectList(j, 'treatmentOptions', where)
        .map((o) => FailureOption.fromJson(o, where))
        .toList();

    return FailureCase(
      caseId: caseId,
      examId: reqString(j, 'examId', where),
      subjectId: optString(j, 'subjectId', where),
      curve: curve,
      symptomOptions: symptomOptions,
      treatmentOptions: treatmentOptions,
      explanation: reqString(j, 'explanation', where),
      source: source.first,
      sourceRef: reqString(j, 'sourceRef', where),
      contentVer: reqString(j, 'contentVer', where),
      disabled: j['disabled'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'caseId': caseId,
        'examId': examId,
        if (subjectId != null) 'subjectId': subjectId,
        'curve': curve.map((p) => p.toJson()).toList(),
        'symptomOptions': symptomOptions.map((o) => o.toJson()).toList(),
        'treatmentOptions': treatmentOptions.map((o) => o.toJson()).toList(),
        'explanation': explanation,
        'source': source.name,
        'sourceRef': sourceRef,
        'contentVer': contentVer,
        if (disabled) 'disabled': true,
      };
}
