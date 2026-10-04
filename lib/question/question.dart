import '../src/json_util.dart';

/// 問題タイプ。choice=選択式、journal=仕訳（借方・貸方の勘定科目＋金額を入力）、
/// worksheet=精算表・財務諸表などの表の空欄埋め（セル単位の金額入力）。
/// 他の型（truefalse・numeric 等）は後続。
enum QuestionType { choice, journal, worksheet }

/// 出典の区分。出典なし（区分なし）の問題は配信しない。
enum QuestionSource { original, statute, licensed }

/// 仕訳の貸借側。
enum JournalSide { debit, credit }

/// 仕訳の1行（借方または貸方の1科目・1金額）。
class JournalLine {
  const JournalLine({required this.side, required this.account, required this.amount});

  final JournalSide side;

  /// 勘定科目コード（出題区分表の科目一覧に基づく。表示名はアプリ側で持つ）。
  final String account;

  /// 金額。0以下は不正（[validateQuestions] で検査）。
  final int amount;

  factory JournalLine.fromJson(Map<String, dynamic> j, String where) {
    final sideName = reqString(j, 'side', where);
    final side = JournalSide.values.where((s) => s.name == sideName);
    if (side.isEmpty) fail(where, '"side" は debit か credit');
    return JournalLine(
      side: side.first,
      account: reqString(j, 'account', where),
      amount: reqInt(j, 'amount', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'side': side.name,
        'account': account,
        'amount': amount,
      };

  @override
  bool operator ==(Object other) =>
      other is JournalLine &&
      other.side == side &&
      other.account == account &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(side, account, amount);

  @override
  String toString() => 'JournalLine($side, $account, $amount)';
}

/// 仕訳問題の正解（複合仕訳＝複数行に対応）。
class JournalAnswer {
  const JournalAnswer({required this.lines});

  final List<JournalLine> lines;

  int get debitTotal => _sum(JournalSide.debit);
  int get creditTotal => _sum(JournalSide.credit);

  int _sum(JournalSide side) =>
      lines.where((l) => l.side == side).fold(0, (sum, l) => sum + l.amount);

  factory JournalAnswer.fromJson(List<dynamic> raw, String where) {
    final lines = [
      for (var i = 0; i < raw.length; i++)
        if (raw[i] is Map<String, dynamic>)
          JournalLine.fromJson(raw[i] as Map<String, dynamic>, '$where[$i]')
        else
          fail(where, '仕訳の行はオブジェクトが必要です'),
    ];
    return JournalAnswer(lines: lines);
  }

  List<Map<String, dynamic>> toJson() => [for (final l in lines) l.toJson()];
}

/// 精算表・財務諸表の列（表埋め問題のセルがどの列に属するか）。
enum WorksheetColumn {
  trialBalanceDebit,
  trialBalanceCredit,
  adjustmentDebit,
  adjustmentCredit,
  incomeStatementDebit,
  incomeStatementCredit,
  balanceSheetDebit,
  balanceSheetCredit,
}

/// 表埋め問題の1セル（勘定科目 × 列 の金額）。
class WorksheetCell {
  const WorksheetCell({required this.account, required this.column, required this.amount});

  /// 勘定科目コード（出題区分表の科目一覧に基づく。表示名はアプリ側で持つ）。
  final String account;
  final WorksheetColumn column;

  /// 金額。0以下は不正（[validateQuestions] で検査）。
  final int amount;

  factory WorksheetCell.fromJson(Map<String, dynamic> j, String where) {
    final columnName = reqString(j, 'column', where);
    final column = WorksheetColumn.values.where((c) => c.name == columnName);
    if (column.isEmpty) fail(where, '未対応の column: $columnName');
    return WorksheetCell(
      account: reqString(j, 'account', where),
      column: column.first,
      amount: reqInt(j, 'amount', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'account': account,
        'column': column.name,
        'amount': amount,
      };

  @override
  bool operator ==(Object other) =>
      other is WorksheetCell &&
      other.account == account &&
      other.column == column &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(account, column, amount);

  @override
  String toString() => 'WorksheetCell($account, $column, $amount)';
}

/// 表埋め問題（精算表・財務諸表など）の正解。
class WorksheetAnswer {
  const WorksheetAnswer({this.givenCells = const [], required this.blankCells});

  /// 問題文で最初から与える値（残高試算表など）。採点対象ではない。
  final List<WorksheetCell> givenCells;

  /// ユーザーが埋めるべき正解セル。
  final List<WorksheetCell> blankCells;

  factory WorksheetAnswer.fromJson(Map<String, dynamic> j, String where) {
    final rawGiven = j['givenCells'];
    final rawBlank = j['blankCells'];
    if (rawBlank is! List) fail(where, '"blankCells" は配列が必要です');
    List<WorksheetCell> cells(List<dynamic> raw, String field) => [
          for (var i = 0; i < raw.length; i++)
            if (raw[i] is Map<String, dynamic>)
              WorksheetCell.fromJson(raw[i] as Map<String, dynamic>, '$where.$field[$i]')
            else
              fail(where, '$field の要素はオブジェクトが必要です'),
        ];
    return WorksheetAnswer(
      givenCells: rawGiven is List ? cells(rawGiven, 'givenCells') : const [],
      blankCells: cells(rawBlank, 'blankCells'),
    );
  }

  Map<String, dynamic> toJson() => {
        if (givenCells.isNotEmpty) 'givenCells': [for (final c in givenCells) c.toJson()],
        'blankCells': [for (final c in blankCells) c.toJson()],
      };
}

/// 1問。IDは不変で、削除は [disabled] で表す（解答履歴は残す）。
class Question {
  const Question({
    required this.qid,
    required this.examId,
    required this.subjectId,
    required this.topicId,
    required this.prompt,
    required this.explanation,
    required this.source,
    required this.sourceRef,
    required this.contentVer,
    this.levelId,
    this.type = QuestionType.choice,
    this.choices = const [],
    this.answerIndex = -1,
    this.journalAnswer,
    this.worksheetAnswer,
    this.difficulty = 3,
    this.points = 1,
    this.license,
    this.lawVersion,
    this.disabled = false,
  })  : assert(
          type != QuestionType.journal || journalAnswer != null,
          'type が journal の問題には journalAnswer が必要です',
        ),
        assert(
          type != QuestionType.worksheet || worksheetAnswer != null,
          'type が worksheet の問題には worksheetAnswer が必要です',
        );

  final String qid;
  final String examId;

  /// null なら全ての級で出題対象。
  final String? levelId;
  final String subjectId;
  final String topicId;
  final QuestionType type;
  final String prompt;

  /// type が choice のときのみ使う。
  final List<String> choices;

  /// type が choice のときのみ使う。
  final int answerIndex;

  /// type が journal のときの正解（複合仕訳）。
  final JournalAnswer? journalAnswer;

  /// type が worksheet のときの正解（精算表・財務諸表などの表埋め）。
  final WorksheetAnswer? worksheetAnswer;

  final String explanation;

  /// 1〜5。
  final int difficulty;

  /// 配点。
  final int points;
  final QuestionSource source;

  /// 出典の説明（条文番号・公式資料名・自作の根拠など）。必須。
  final String sourceRef;

  /// source が licensed のときの許諾の記録。
  final String? license;

  /// source が statute のときの法令の版。
  final String? lawVersion;
  final String contentVer;
  final bool disabled;

  factory Question.fromJson(Map<String, dynamic> j) {
    final qid = reqString(j, 'qid', 'question');
    final where = 'question[$qid]';

    final typeName = optString(j, 'type', where) ?? 'choice';
    final typeMatch = QuestionType.values.where((t) => t.name == typeName);
    if (typeMatch.isEmpty) fail(where, '未対応の type: $typeName');
    final type = typeMatch.first;

    final sourceName = reqString(j, 'source', where);
    final source = QuestionSource.values.where((s) => s.name == sourceName);
    if (source.isEmpty) {
      fail(where, '"source" は original / statute / licensed のいずれか');
    }

    var choices = const <String>[];
    var answerIndex = -1;
    JournalAnswer? journalAnswer;
    WorksheetAnswer? worksheetAnswer;

    switch (type) {
      case QuestionType.choice:
        final rawChoices = j['choices'];
        if (rawChoices is! List || rawChoices.any((c) => c is! String)) {
          fail(where, '"choices" は文字列の配列が必要です');
        }
        choices = List<String>.from(rawChoices);
        answerIndex = reqInt(j, 'answerIndex', where);
      case QuestionType.journal:
        final rawAnswer = j['journalAnswer'];
        if (rawAnswer is! List) fail(where, '"journalAnswer" は配列が必要です');
        journalAnswer = JournalAnswer.fromJson(rawAnswer, '$where.journalAnswer');
      case QuestionType.worksheet:
        final rawAnswer = j['worksheetAnswer'];
        if (rawAnswer is! Map<String, dynamic>) {
          fail(where, '"worksheetAnswer" はオブジェクトが必要です');
        }
        worksheetAnswer = WorksheetAnswer.fromJson(rawAnswer, '$where.worksheetAnswer');
    }

    return Question(
      qid: qid,
      examId: reqString(j, 'examId', where),
      levelId: optString(j, 'levelId', where),
      subjectId: reqString(j, 'subjectId', where),
      topicId: reqString(j, 'topicId', where),
      type: type,
      prompt: reqString(j, 'prompt', where),
      choices: choices,
      answerIndex: answerIndex,
      journalAnswer: journalAnswer,
      worksheetAnswer: worksheetAnswer,
      explanation: reqString(j, 'explanation', where),
      difficulty: optInt(j, 'difficulty', where, 3),
      points: optInt(j, 'points', where, 1),
      source: source.first,
      sourceRef: reqString(j, 'sourceRef', where),
      license: optString(j, 'license', where),
      lawVersion: optString(j, 'lawVersion', where),
      contentVer: reqString(j, 'contentVer', where),
      disabled: j['disabled'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'qid': qid,
        'examId': examId,
        if (levelId != null) 'levelId': levelId,
        'subjectId': subjectId,
        'topicId': topicId,
        'type': type.name,
        'prompt': prompt,
        if (type == QuestionType.choice) ...{
          'choices': choices,
          'answerIndex': answerIndex,
        },
        if (journalAnswer != null) 'journalAnswer': journalAnswer!.toJson(),
        if (worksheetAnswer != null) 'worksheetAnswer': worksheetAnswer!.toJson(),
        'explanation': explanation,
        'difficulty': difficulty,
        'points': points,
        'source': source.name,
        'sourceRef': sourceRef,
        if (license != null) 'license': license,
        if (lawVersion != null) 'lawVersion': lawVersion,
        'contentVer': contentVer,
        if (disabled) 'disabled': true,
      };
}
