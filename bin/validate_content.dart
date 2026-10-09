import 'dart:convert';
import 'dart:io';

import 'package:ukalab_core/ukalab_core.dart';

/// 問題データ・用語データの配信前チェック。
///
/// 使い方: `dart run ukalab_core:validate_content exam_config.json [--terms terms.jsonl]... [--boundary boundary.jsonl]... [--predict predict.jsonl]... [--misconception misconception.jsonl]... [--failure failure.jsonl]... [--confusion-matrix confusion_matrix.jsonl]... [--method-choice method_choice.jsonl]... [--ml-lab ml_lab.jsonl]... [--ai-news ai_news.jsonl]... [--conv-lab conv_lab.jsonl]... [--attention-viz attention_viz.jsonl]... [--nn-builder nn_builder.jsonl]... [--ethics-case ethics_case.jsonl]... [--story story_mode.jsonl]... [--update-log update_log.jsonl]... [--next-steps next_steps.jsonl]... [--checklist checklist.jsonl]... questions.jsonl...`
/// 問題が1件でもあれば終了コード1（CI で配信を止める）。
Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln(
      '使い方: validate_content <exam_config.json> [--terms terms.jsonl]... '
      '[--boundary boundary.jsonl]... [--predict predict.jsonl]... '
      '[--misconception misconception.jsonl]... [--failure failure.jsonl]... '
      '[--confusion-matrix confusion_matrix.jsonl]... '
      '[--method-choice method_choice.jsonl]... '
      '[--ml-lab ml_lab.jsonl]... '
      '[--ai-news ai_news.jsonl]... '
      '[--conv-lab conv_lab.jsonl]... '
      '[--attention-viz attention_viz.jsonl]... '
      '[--nn-builder nn_builder.jsonl]... '
      '[--ethics-case ethics_case.jsonl]... '
      '[--story story_mode.jsonl]... '
      '[--update-log update_log.jsonl]... '
      '[--next-steps next_steps.jsonl]... '
      '[--checklist checklist.jsonl]... '
      '<questions.jsonl>...',
    );
    exit(64);
  }

  final ExamConfig exam;
  try {
    final json = jsonDecode(await File(args.first).readAsString());
    exam = ExamConfig.fromJson(json as Map<String, dynamic>);
  } on FormatException catch (e) {
    stderr.writeln('試験定義が不正です: ${e.message}');
    exit(1);
  }

  final questionPaths = <String>[];
  final termPaths = <String>[];
  final boundaryPaths = <String>[];
  final predictPaths = <String>[];
  final misconceptionPaths = <String>[];
  final failurePaths = <String>[];
  final confusionMatrixPaths = <String>[];
  final methodChoicePaths = <String>[];
  final mlLabPaths = <String>[];
  final aiNewsPaths = <String>[];
  final convLabPaths = <String>[];
  final attentionVizPaths = <String>[];
  final nnBuilderPaths = <String>[];
  final ethicsCasePaths = <String>[];
  final storyPaths = <String>[];
  final updateLogPaths = <String>[];
  final nextStepPaths = <String>[];
  final checklistPaths = <String>[];
  final rest = args.skip(1).toList();
  for (var i = 0; i < rest.length; i++) {
    if (rest[i] == '--terms') {
      if (i + 1 >= rest.length) {
        stderr.writeln('--terms の後にファイルパスが必要です');
        exit(64);
      }
      termPaths.add(rest[++i]);
    } else if (rest[i] == '--boundary') {
      if (i + 1 >= rest.length) {
        stderr.writeln('--boundary の後にファイルパスが必要です');
        exit(64);
      }
      boundaryPaths.add(rest[++i]);
    } else if (rest[i] == '--predict') {
      if (i + 1 >= rest.length) {
        stderr.writeln('--predict の後にファイルパスが必要です');
        exit(64);
      }
      predictPaths.add(rest[++i]);
    } else if (rest[i] == '--misconception') {
      if (i + 1 >= rest.length) {
        stderr.writeln('--misconception の後にファイルパスが必要です');
        exit(64);
      }
      misconceptionPaths.add(rest[++i]);
    } else if (rest[i] == '--failure') {
      if (i + 1 >= rest.length) {
        stderr.writeln('--failure の後にファイルパスが必要です');
        exit(64);
      }
      failurePaths.add(rest[++i]);
    } else if (rest[i] == '--confusion-matrix') {
      if (i + 1 >= rest.length) {
        stderr.writeln('--confusion-matrix の後にファイルパスが必要です');
        exit(64);
      }
      confusionMatrixPaths.add(rest[++i]);
    } else if (rest[i] == '--method-choice') {
      if (i + 1 >= rest.length) {
        stderr.writeln('--method-choice の後にファイルパスが必要です');
        exit(64);
      }
      methodChoicePaths.add(rest[++i]);
    } else if (rest[i] == '--ml-lab') {
      if (i + 1 >= rest.length) {
        stderr.writeln('--ml-lab の後にファイルパスが必要です');
        exit(64);
      }
      mlLabPaths.add(rest[++i]);
    } else if (rest[i] == '--ai-news') {
      if (i + 1 >= rest.length) {
        stderr.writeln('--ai-news の後にファイルパスが必要です');
        exit(64);
      }
      aiNewsPaths.add(rest[++i]);
    } else if (rest[i] == '--conv-lab') {
      if (i + 1 >= rest.length) {
        stderr.writeln('--conv-lab の後にファイルパスが必要です');
        exit(64);
      }
      convLabPaths.add(rest[++i]);
    } else if (rest[i] == '--attention-viz') {
      if (i + 1 >= rest.length) {
        stderr.writeln('--attention-viz の後にファイルパスが必要です');
        exit(64);
      }
      attentionVizPaths.add(rest[++i]);
    } else if (rest[i] == '--nn-builder') {
      if (i + 1 >= rest.length) {
        stderr.writeln('--nn-builder の後にファイルパスが必要です');
        exit(64);
      }
      nnBuilderPaths.add(rest[++i]);
    } else if (rest[i] == '--ethics-case') {
      if (i + 1 >= rest.length) {
        stderr.writeln('--ethics-case の後にファイルパスが必要です');
        exit(64);
      }
      ethicsCasePaths.add(rest[++i]);
    } else if (rest[i] == '--story') {
      if (i + 1 >= rest.length) {
        stderr.writeln('--story の後にファイルパスが必要です');
        exit(64);
      }
      storyPaths.add(rest[++i]);
    } else if (rest[i] == '--update-log') {
      if (i + 1 >= rest.length) {
        stderr.writeln('--update-log の後にファイルパスが必要です');
        exit(64);
      }
      updateLogPaths.add(rest[++i]);
    } else if (rest[i] == '--next-steps') {
      if (i + 1 >= rest.length) {
        stderr.writeln('--next-steps の後にファイルパスが必要です');
        exit(64);
      }
      nextStepPaths.add(rest[++i]);
    } else if (rest[i] == '--checklist') {
      if (i + 1 >= rest.length) {
        stderr.writeln('--checklist の後にファイルパスが必要です');
        exit(64);
      }
      checklistPaths.add(rest[++i]);
    } else {
      questionPaths.add(rest[i]);
    }
  }

  final questions = <Question>[];
  final issues = <ContentIssue>[];
  for (final path in questionPaths) {
    final parsed = parseQuestionsJsonl(await File(path).readAsString());
    questions.addAll(parsed.questions);
    issues.addAll(parsed.issues.map(
      (i) => ContentIssue('$path ${i.qid}', i.code, i.message),
    ));
  }
  issues.addAll(validateQuestions(questions, exam: exam));

  final terms = <Term>[];
  for (final path in termPaths) {
    final parsed = parseTermsJsonl(await File(path).readAsString());
    terms.addAll(parsed.terms);
    issues.addAll(parsed.issues.map(
      (i) => ContentIssue('$path ${i.qid}', i.code, i.message),
    ));
  }
  issues.addAll(validateCompareTargets(questions, [for (final t in terms) t.termId]));
  if (terms.isNotEmpty) {
    issues.addAll(validateTerms(terms, exam: exam, questions: questions));
  }

  final boundaryScenarios = <BoundaryScenario>[];
  for (final path in boundaryPaths) {
    final parsed = parseBoundaryScenariosJsonl(await File(path).readAsString());
    boundaryScenarios.addAll(parsed.scenarios);
    issues.addAll(parsed.issues.map(
      (i) => ContentIssue('$path ${i.qid}', i.code, i.message),
    ));
  }
  if (boundaryScenarios.isNotEmpty) {
    issues.addAll(validateBoundaryScenarios(boundaryScenarios, exam: exam));
  }

  final predictScenarios = <PredictRunScenario>[];
  for (final path in predictPaths) {
    final parsed = parsePredictRunScenariosJsonl(await File(path).readAsString());
    predictScenarios.addAll(parsed.scenarios);
    issues.addAll(parsed.issues.map(
      (i) => ContentIssue('$path ${i.qid}', i.code, i.message),
    ));
  }
  if (predictScenarios.isNotEmpty) {
    issues.addAll(validatePredictRunScenarios(predictScenarios, exam: exam));
  }

  final misconceptionScenarios = <MisconceptionScenario>[];
  for (final path in misconceptionPaths) {
    final parsed =
        parseMisconceptionScenariosJsonl(await File(path).readAsString());
    misconceptionScenarios.addAll(parsed.scenarios);
    issues.addAll(parsed.issues.map(
      (i) => ContentIssue('$path ${i.qid}', i.code, i.message),
    ));
  }
  if (misconceptionScenarios.isNotEmpty) {
    issues.addAll(validateMisconceptionScenarios(misconceptionScenarios, exam: exam));
  }

  final failureCases = <FailureCase>[];
  for (final path in failurePaths) {
    final parsed = parseFailureCasesJsonl(await File(path).readAsString());
    failureCases.addAll(parsed.cases);
    issues.addAll(parsed.issues.map(
      (i) => ContentIssue('$path ${i.qid}', i.code, i.message),
    ));
  }
  if (failureCases.isNotEmpty) {
    issues.addAll(validateFailureCases(failureCases, exam: exam));
  }

  final confusionMatrixScenarios = <ConfusionMatrixScenario>[];
  for (final path in confusionMatrixPaths) {
    final parsed =
        parseConfusionMatrixScenariosJsonl(await File(path).readAsString());
    confusionMatrixScenarios.addAll(parsed.scenarios);
    issues.addAll(parsed.issues.map(
      (i) => ContentIssue('$path ${i.qid}', i.code, i.message),
    ));
  }
  if (confusionMatrixScenarios.isNotEmpty) {
    issues.addAll(validateConfusionMatrixScenarios(confusionMatrixScenarios, exam: exam));
  }

  final methodChoiceScenarios = <MethodChoiceScenario>[];
  for (final path in methodChoicePaths) {
    final parsed = parseMethodChoiceScenariosJsonl(await File(path).readAsString());
    methodChoiceScenarios.addAll(parsed.scenarios);
    issues.addAll(parsed.issues.map(
      (i) => ContentIssue('$path ${i.qid}', i.code, i.message),
    ));
  }
  if (methodChoiceScenarios.isNotEmpty) {
    issues.addAll(validateMethodChoiceScenarios(methodChoiceScenarios, exam: exam));
  }

  final mlLabDatasets = <MlLabDataset>[];
  for (final path in mlLabPaths) {
    final parsed = parseMlLabDatasetsJsonl(await File(path).readAsString());
    mlLabDatasets.addAll(parsed.datasets);
    issues.addAll(parsed.issues.map(
      (i) => ContentIssue('$path ${i.qid}', i.code, i.message),
    ));
  }
  if (mlLabDatasets.isNotEmpty) {
    issues.addAll(validateMlLabDatasets(mlLabDatasets, exam: exam));
  }

  final aiNewsItems = <AiNewsItem>[];
  for (final path in aiNewsPaths) {
    final parsed = parseAiNewsItemsJsonl(await File(path).readAsString());
    aiNewsItems.addAll(parsed.items);
    issues.addAll(parsed.issues.map(
      (i) => ContentIssue('$path ${i.qid}', i.code, i.message),
    ));
  }
  if (aiNewsItems.isNotEmpty) {
    issues.addAll(validateAiNewsItems(
      aiNewsItems,
      exam: exam,
      questionIds: questions.map((q) => q.qid).toList(),
    ));
  }

  final convLabImages = <ConvLabImage>[];
  for (final path in convLabPaths) {
    final parsed = parseConvLabImagesJsonl(await File(path).readAsString());
    convLabImages.addAll(parsed.images);
    issues.addAll(parsed.issues.map(
      (i) => ContentIssue('$path ${i.qid}', i.code, i.message),
    ));
  }
  if (convLabImages.isNotEmpty) {
    issues.addAll(validateConvLabImages(convLabImages, exam: exam));
  }

  final attentionVizScenarios = <AttentionVizScenario>[];
  for (final path in attentionVizPaths) {
    final parsed = parseAttentionVizScenariosJsonl(await File(path).readAsString());
    attentionVizScenarios.addAll(parsed.scenarios);
    issues.addAll(parsed.issues.map(
      (i) => ContentIssue('$path ${i.qid}', i.code, i.message),
    ));
  }
  if (attentionVizScenarios.isNotEmpty) {
    issues.addAll(validateAttentionVizScenarios(attentionVizScenarios, exam: exam));
  }

  final nnBuilderDatasets = <NnBuilderDataset>[];
  for (final path in nnBuilderPaths) {
    final parsed = parseNnBuilderDatasetsJsonl(await File(path).readAsString());
    nnBuilderDatasets.addAll(parsed.datasets);
    issues.addAll(parsed.issues.map(
      (i) => ContentIssue('$path ${i.qid}', i.code, i.message),
    ));
  }
  if (nnBuilderDatasets.isNotEmpty) {
    issues.addAll(validateNnBuilderDatasets(nnBuilderDatasets, exam: exam));
  }

  final ethicsCaseScenarios = <EthicsCaseScenario>[];
  for (final path in ethicsCasePaths) {
    final parsed = parseEthicsCaseScenariosJsonl(await File(path).readAsString());
    ethicsCaseScenarios.addAll(parsed.scenarios);
    issues.addAll(parsed.issues.map(
      (i) => ContentIssue('$path ${i.qid}', i.code, i.message),
    ));
  }
  if (ethicsCaseScenarios.isNotEmpty) {
    issues.addAll(validateEthicsCaseScenarios(ethicsCaseScenarios, exam: exam));
  }

  final storyScenarios = <StoryScenario>[];
  for (final path in storyPaths) {
    final parsed = parseStoryScenariosJsonl(await File(path).readAsString());
    storyScenarios.addAll(parsed.scenarios);
    issues.addAll(parsed.issues.map(
      (i) => ContentIssue('$path ${i.qid}', i.code, i.message),
    ));
  }
  if (storyScenarios.isNotEmpty) {
    issues.addAll(validateStoryScenarios(storyScenarios, exam: exam));
  }

  for (final issue in issues) {
    stdout.writeln(issue);
  }
  final updateLogEntries = <UpdateLogEntry>[];
  for (final path in updateLogPaths) {
    final parsed = parseUpdateLogJsonl(await File(path).readAsString());
    updateLogEntries.addAll(parsed.entries);
    issues.addAll(parsed.issues.map(
      (i) => ContentIssue('$path ${i.qid}', i.code, i.message),
    ));
  }
  if (updateLogEntries.isNotEmpty) {
    issues.addAll(validateUpdateLog(updateLogEntries, exam: exam));
  }

  final nextStepRules = <NextStepRule>[];
  for (final path in nextStepPaths) {
    final parsed = parseNextStepsJsonl(await File(path).readAsString());
    nextStepRules.addAll(parsed.rules);
    issues.addAll(parsed.issues.map(
      (i) => ContentIssue('$path ${i.qid}', i.code, i.message),
    ));
  }
  if (nextStepRules.isNotEmpty) {
    issues.addAll(validateNextSteps(nextStepRules));
  }

  final checklistItems = <ChecklistItem>[];
  for (final path in checklistPaths) {
    final parsed = parseChecklistItemsJsonl(await File(path).readAsString());
    checklistItems.addAll(parsed.items);
    issues.addAll(parsed.issues.map(
      (i) => ContentIssue('$path ${i.qid}', i.code, i.message),
    ));
  }
  if (checklistItems.isNotEmpty) {
    issues.addAll(validateChecklistItems(checklistItems, exam: exam));
  }

  final termsSummary = terms.isEmpty ? '' : '、${terms.length}語を検査';
  final boundarySummary =
      boundaryScenarios.isEmpty ? '' : '、${boundaryScenarios.length}場面を検査';
  final predictSummary =
      predictScenarios.isEmpty ? '' : '、${predictScenarios.length}場面を検査';
  final misconceptionSummary = misconceptionScenarios.isEmpty
      ? ''
      : '、${misconceptionScenarios.length}場面を検査';
  final failureSummary =
      failureCases.isEmpty ? '' : '、${failureCases.length}症例を検査';
  final confusionMatrixSummary = confusionMatrixScenarios.isEmpty
      ? ''
      : '、${confusionMatrixScenarios.length}場面を検査';
  final methodChoiceSummary = methodChoiceScenarios.isEmpty
      ? ''
      : '、${methodChoiceScenarios.length}場面を検査';
  final mlLabSummary =
      mlLabDatasets.isEmpty ? '' : '、${mlLabDatasets.length}データセットを検査';
  final aiNewsSummary = aiNewsItems.isEmpty ? '' : '、${aiNewsItems.length}件を検査';
  final convLabSummary = convLabImages.isEmpty ? '' : '、${convLabImages.length}画像を検査';
  final attentionVizSummary =
      attentionVizScenarios.isEmpty ? '' : '、${attentionVizScenarios.length}場面を検査';
  final nnBuilderSummary =
      nnBuilderDatasets.isEmpty ? '' : '、${nnBuilderDatasets.length}データセットを検査';
  final ethicsCaseSummary =
      ethicsCaseScenarios.isEmpty ? '' : '、${ethicsCaseScenarios.length}場面を検査';
  final storySummary =
      storyScenarios.isEmpty ? '' : '、${storyScenarios.length}シナリオを検査';
  final updateLogSummary =
      updateLogEntries.isEmpty ? '' : '、更新ログ${updateLogEntries.length}件を検査';
  final nextStepSummary =
      nextStepRules.isEmpty ? '' : '、次の一手${nextStepRules.length}件を検査';
  final checklistSummary =
      checklistItems.isEmpty ? '' : '、チェックリスト${checklistItems.length}項目を検査';
  stdout.writeln(
    '${exam.examId}: ${questions.length}問を検査$termsSummary$boundarySummary$predictSummary$misconceptionSummary$failureSummary$confusionMatrixSummary$methodChoiceSummary$mlLabSummary$aiNewsSummary$convLabSummary$attentionVizSummary$nnBuilderSummary$ethicsCaseSummary$storySummary$updateLogSummary$nextStepSummary$checklistSummary、問題${issues.length}件',
  );
  exit(issues.isEmpty ? 0 : 1);
}
