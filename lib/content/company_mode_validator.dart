import 'dart:convert';

import '../company_mode/company_scenario.dart';
import '../config/exam_config.dart';
import 'question_validator.dart' show ContentIssue;

class ParsedCompanyScenarios {
  const ParsedCompanyScenarios(this.scenarios, this.issues);

  final List<CompanyScenario> scenarios;

  /// 読み込み（JSON 構文・必須項目）で見つかった問題。
  final List<ContentIssue> issues;
}

/// JSON Lines（1行1シナリオ）を読む。読めない行は [ParsedCompanyScenarios.issues]
/// に入れて続行する。
ParsedCompanyScenarios parseCompanyScenariosJsonl(String text) {
  final scenarios = <CompanyScenario>[];
  final issues = <ContentIssue>[];
  final lines = const LineSplitter().convert(text);
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('//')) continue;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('1行は JSON オブジェクトが必要です');
      }
      scenarios.add(CompanyScenario.fromJson(decoded));
    } on FormatException catch (e) {
      issues.add(ContentIssue('line:${i + 1}', 'parse', e.message));
    }
  }
  return ParsedCompanyScenarios(scenarios, issues);
}

/// 配信前の品質ゲート。シナリオID・ターンIDの重複、必須項目の空欄、
/// 貸借不一致、ターン数0、examId整合などを検査する。
///
/// [exam] を渡すと examId が試験定義と整合するかも検査する。
List<ContentIssue> validateCompanyScenarios(
  List<CompanyScenario> scenarios, {
  ExamConfig? exam,
}) {
  final issues = <ContentIssue>[];
  void add(CompanyScenario s, String code, String message) =>
      issues.add(ContentIssue(s.scenarioId, code, message));

  final seenIds = <String>{};
  for (final s in scenarios) {
    if (!seenIds.add(s.scenarioId)) {
      add(s, 'duplicate-id', 'scenarioId が重複しています');
    }

    if (s.companyName.trim().isEmpty) add(s, 'empty-company-name', '会社名が空です');
    if (s.introText.trim().isEmpty) add(s, 'empty-intro', '導入文が空です');
    if (s.initialCapital <= 0) {
      add(s, 'invalid-capital', '初期資本金は0より大きい必要があります');
    }
    if (s.turns.isEmpty) {
      add(s, 'no-turns', 'ターンが1件もありません');
    }
    if (exam != null && s.examId != exam.examId) {
      add(s, 'exam-mismatch', 'examId(${s.examId}) が試験(${exam.examId})と一致しません');
    }

    final seenTurnIds = <String>{};
    for (final t in s.turns) {
      if (!seenTurnIds.add(t.turnId)) {
        add(s, 'duplicate-turn-id', 'turnId「${t.turnId}」が重複しています');
      }
      if (t.eventText.trim().isEmpty) {
        add(s, 'empty-event-text', 'ターン「${t.turnId}」の取引イベント文が空です');
      }
      if (t.explanation.trim().isEmpty) {
        add(s, 'empty-turn-explanation', 'ターン「${t.turnId}」の解説が空です');
      }
      if (t.answer.lines.isEmpty) {
        add(s, 'empty-journal', 'ターン「${t.turnId}」の仕訳が空です');
      } else if (t.answer.debitTotal != t.answer.creditTotal) {
        add(
          s,
          'unbalanced-journal',
          'ターン「${t.turnId}」の仕訳が貸借不一致です'
              '（借方${t.answer.debitTotal} / 貸方${t.answer.creditTotal}）',
        );
      }
      for (final line in t.answer.lines) {
        if (line.amount <= 0) {
          add(s, 'invalid-amount', 'ターン「${t.turnId}」に0以下の金額が含まれています');
        }
      }
    }

    if (s.sourceRef.trim().isEmpty) add(s, 'no-source', '出典の説明がありません');
    if (s.contentVer.trim().isEmpty) add(s, 'no-content-ver', 'contentVer がありません');
  }
  return issues;
}
