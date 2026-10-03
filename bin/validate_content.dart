import 'dart:convert';
import 'dart:io';

import 'package:yourwish_kentei/yourwish_kentei.dart';

/// 問題データ・用語データの配信前チェック。
///
/// 使い方: `dart run yourwish_kentei:validate_content exam_config.json [--terms terms.jsonl]... questions.jsonl...`
/// 問題が1件でもあれば終了コード1（CI で配信を止める）。
Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln(
      '使い方: validate_content <exam_config.json> [--terms terms.jsonl]... <questions.jsonl>...',
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
  final rest = args.skip(1).toList();
  for (var i = 0; i < rest.length; i++) {
    if (rest[i] == '--terms') {
      if (i + 1 >= rest.length) {
        stderr.writeln('--terms の後にファイルパスが必要です');
        exit(64);
      }
      termPaths.add(rest[++i]);
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

  for (final issue in issues) {
    stdout.writeln(issue);
  }
  final termsSummary = terms.isEmpty ? '' : '、${terms.length}語を検査';
  stdout.writeln(
    '${exam.examId}: ${questions.length}問を検査$termsSummary、問題${issues.length}件',
  );
  exit(issues.isEmpty ? 0 : 1);
}
