import 'dart:convert';
import 'dart:io';

import 'package:yourwish_kentei/yourwish_kentei.dart';

/// 問題データ・用語データの配信前チェック。
///
/// 使い方: `dart run yourwish_kentei:validate_content exam_config.json [--terms terms.jsonl]... [--boundary boundary.jsonl]... [--predict predict.jsonl]... [--misconception misconception.jsonl]... [--failure failure.jsonl]... [--confusion-matrix confusion_matrix.jsonl]... [--method-choice method_choice.jsonl]... questions.jsonl...`
/// 問題が1件でもあれば終了コード1（CI で配信を止める）。
Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln(
      '使い方: validate_content <exam_config.json> [--terms terms.jsonl]... '
      '[--boundary boundary.jsonl]... [--predict predict.jsonl]... '
      '[--misconception misconception.jsonl]... [--failure failure.jsonl]... '
      '[--confusion-matrix confusion_matrix.jsonl]... '
      '[--method-choice method_choice.jsonl]... '
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

  for (final issue in issues) {
    stdout.writeln(issue);
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
  stdout.writeln(
    '${exam.examId}: ${questions.length}問を検査$termsSummary$boundarySummary$predictSummary$misconceptionSummary$failureSummary$confusionMatrixSummary$methodChoiceSummary、問題${issues.length}件',
  );
  exit(issues.isEmpty ? 0 : 1);
}
