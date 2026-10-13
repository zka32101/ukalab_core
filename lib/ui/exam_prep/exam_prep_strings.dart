import 'package:app_common_kit/app_common_kit.dart' show KitStrings;
import 'package:flutter/widgets.dart';

import '../../experience/exam_day_checklist.dart';
import '../../experience/update_log.dart';

/// 「試験に向けて」系の画面（10分プラン・試験直前・当日チェックリスト・更新ログ・学習データ書き出し）の文言。
///
/// 言語は [KitStrings.languageCode]（`KitStringsScope`）に従う。内蔵は ja・en・zh（簡体）・
/// zh-Hant（繁体）・ko。それ以外は日本語。ja・en 以外は機械翻訳の下書きで、公開前に母語話者の確認が要る。
/// 励ます表現のみで、責める表現・他人との比較は使わない（テストで検査する）。
/// 引数で [ExamPrepStrings] を渡せば、そちらが優先される。
@immutable
class ExamPrepStrings {
  const ExamPrepStrings({
    required this.sectionTitle,
    required this.tenMinTitle,
    required this.tenMinSubtitle,
    required this.examEveSubtitle,
    required this.checklistTitle,
    required this.premiumNote,
    required this.emptyPlan,
    required this.emptyEve,
    required this.updateLogTitle,
    required this.updateLogSubtitle,
    required this.updateLogEmpty,
    required this.exportTitle,
    required this.exportSubtitle,
    required this.exportEmpty,
    required this.exportCopy,
    required this.exportCopied,
    required this.exportNote,
    required this.confirmNeeded,
    required this.checklistDone,
    required this.checklistNote,
    required this.examEveTitle,
    required this.progress,
    required this.eveDays,
    required this.countdown,
    required this.affected,
    required this.categoryBelongings,
    required this.categoryTravel,
    required this.categoryAdmission,
    required this.categoryEnvironment,
    required this.kindLawChange,
    required this.kindSyllabusChange,
    required this.kindCorrection,
    required this.kindNewContent,
    required this.defaultChecklistLabels,
  });

  final String sectionTitle;
  final String tenMinTitle;
  final String tenMinSubtitle;
  final String examEveTitle;
  final String examEveSubtitle;
  final String checklistTitle;

  /// premium 機能が使えないときの案内。
  final String premiumNote;
  final String emptyPlan;
  final String emptyEve;
  final String updateLogTitle;
  final String updateLogSubtitle;
  final String updateLogEmpty;
  final String exportTitle;
  final String exportSubtitle;
  final String exportEmpty;
  final String exportCopy;
  final String exportCopied;
  final String exportNote;

  /// 公式の案内で確認できていない項目に付ける注記。
  final String confirmNeeded;
  final String checklistDone;
  final String checklistNote;

  /// 「N / M 完了」。
  final String Function(int done, int total) progress;

  /// 試験直前モードの見出し（残り日数入り。0 は当日）。
  final String Function(int daysLeft) eveDays;

  /// 本番までの残り日数の文言（0 は当日、負は過ぎた日数）。
  final String Function(int daysLeft) countdown;

  /// 「N問」。
  final String Function(int n) affected;

  final String categoryBelongings;
  final String categoryTravel;
  final String categoryAdmission;
  final String categoryEnvironment;
  final String kindLawChange;
  final String kindSyllabusChange;
  final String kindCorrection;
  final String kindNewContent;

  /// 一般のチェック項目の文言（itemId → label。キーは defaultExamDayChecklist が使う）。
  final Map<String, String> defaultChecklistLabels;

  String category(ChecklistCategory c) => switch (c) {
    ChecklistCategory.belongings => categoryBelongings,
    ChecklistCategory.travel => categoryTravel,
    ChecklistCategory.admission => categoryAdmission,
    ChecklistCategory.environment => categoryEnvironment,
  };

  String updateKind(UpdateKind k) => switch (k) {
    UpdateKind.lawChange => kindLawChange,
    UpdateKind.syllabusChange => kindSyllabusChange,
    UpdateKind.correction => kindCorrection,
    UpdateKind.newContent => kindNewContent,
  };

  /// 画面に出す全文言（検査用。関数は代表値で展開する）。
  List<String> get allTexts => [
    sectionTitle,
    tenMinTitle,
    tenMinSubtitle,
    examEveTitle,
    examEveSubtitle,
    checklistTitle,
    premiumNote,
    emptyPlan,
    emptyEve,
    updateLogTitle,
    updateLogSubtitle,
    updateLogEmpty,
    exportTitle,
    exportSubtitle,
    exportEmpty,
    exportCopy,
    exportCopied,
    exportNote,
    confirmNeeded,
    checklistDone,
    checklistNote,
    progress(1, 5),
    eveDays(0),
    eveDays(3),
    countdown(0),
    countdown(5),
    countdown(-2),
    affected(3),
    categoryBelongings,
    categoryTravel,
    categoryAdmission,
    categoryEnvironment,
    kindLawChange,
    kindSyllabusChange,
    kindCorrection,
    kindNewContent,
    ...defaultChecklistLabels.values,
  ];

  static const ja = ExamPrepStrings(
    sectionTitle: '試験に向けて',
    tenMinTitle: '今日の10分プラン',
    tenMinSubtitle: '弱点や見直したい問題から、10分に収まるだけ選びます',
    examEveTitle: '試験直前モード',
    examEveSubtitle: '最近間違えた問題・頻出・計算式を見直します',
    checklistTitle: '試験当日チェックリスト',
    premiumNote: 'プレミアムで使えます',
    emptyPlan: '今は出題できる問題がありません。',
    emptyEve: '見直す問題はまだありません。「学ぶ」で解くと、ここに集まります。',
    updateLogTitle: '更新ログ',
    updateLogSubtitle: '問題や解説の追加・訂正の記録を見られます',
    updateLogEmpty: '最近の更新はありません。',
    exportTitle: '学習データの書き出し（CSV）',
    exportSubtitle: '日ごとの解答数・正答率・分野ごとの正答率を書き出します',
    exportEmpty: 'まだ書き出せる履歴がありません。解くとここに集まります。',
    exportCopy: 'コピー',
    exportCopied: 'コピーしました',
    exportNote: '氏名・ID・端末情報・問題文は含まれません。',
    confirmNeeded: '公式で要確認',
    checklistDone: '準備ができました。落ち着いて、いつもどおりに。',
    checklistNote: '公式の受験案内で必ずご確認ください。項目は目安です。',
    progress: _jaProgress,
    eveDays: _jaEveDays,
    countdown: _jaCountdown,
    affected: _jaAffected,
    categoryBelongings: '持ち物',
    categoryTravel: '会場までの移動',
    categoryAdmission: '受験票・本人確認',
    categoryEnvironment: '受験環境',
    kindLawChange: '法改正',
    kindSyllabusChange: '出題範囲の改訂',
    kindCorrection: '訂正',
    kindNewContent: '追加',
    defaultChecklistLabels: {
      'default-ticket': '受験票を用意した',
      'default-id': '本人確認の方法を受験案内で確かめた',
      'default-belongings': '筆記用具など、持ち物を用意した',
      'default-allowed': '持ち込める物・持ち込めない物を確かめた',
      'default-route': '会場までの行き方と所要時間を確かめた',
      'default-margin': '時間に余裕をもって着く予定を立てた',
      'default-net': '通信環境と受験する部屋を確かめた',
    },
  );

  static const en = ExamPrepStrings(
    sectionTitle: 'Getting ready for the exam',
    tenMinTitle: 'Today\'s 10-minute plan',
    tenMinSubtitle:
        'Picks weak spots and questions worth another look, to fit in 10 minutes',
    examEveTitle: 'Final-days mode',
    examEveSubtitle:
        'Review recently missed questions, frequent topics and formulas',
    checklistTitle: 'Exam-day checklist',
    premiumNote: 'Available with Premium',
    emptyPlan: 'No questions to show right now.',
    emptyEve:
        'Nothing to review yet. Questions you answer in Study will gather here.',
    updateLogTitle: 'Update log',
    updateLogSubtitle:
        'See what was added or corrected in questions and explanations',
    updateLogEmpty: 'No recent updates.',
    exportTitle: 'Export study data (CSV)',
    exportSubtitle: 'Daily answers and accuracy, and accuracy by topic',
    exportEmpty: 'Nothing to export yet. Your answers will gather here.',
    exportCopy: 'Copy',
    exportCopied: 'Copied',
    exportNote: 'Names, IDs, device info and question text are not included.',
    confirmNeeded: 'Check the official guide',
    checklistDone: 'You\'re all set. Stay calm and do what you always do.',
    checklistNote:
        'Always check the official exam guide. These items are a guide only.',
    progress: _enProgress,
    eveDays: _enEveDays,
    countdown: _enCountdown,
    affected: _enAffected,
    categoryBelongings: 'Belongings',
    categoryTravel: 'Getting to the venue',
    categoryAdmission: 'Admission ticket and ID',
    categoryEnvironment: 'Exam environment',
    kindLawChange: 'Law change',
    kindSyllabusChange: 'Syllabus revision',
    kindCorrection: 'Correction',
    kindNewContent: 'Added',
    defaultChecklistLabels: {
      'default-ticket': 'Admission ticket is ready',
      'default-id': 'Checked how identity is verified in the exam guide',
      'default-belongings': 'Pens and other belongings are ready',
      'default-allowed': 'Checked what may and may not be brought in',
      'default-route': 'Checked the route and travel time to the venue',
      'default-margin': 'Planned to arrive with time to spare',
      'default-net': 'Checked the connection and the room for the exam',
    },
  );

  // 簡体字・繁体字・韓国語は機械翻訳の下書き。公開前に母語話者の確認が要る。
  static const zhHans = ExamPrepStrings(
    sectionTitle: '备考',
    tenMinTitle: '今日10分钟计划',
    tenMinSubtitle: '从薄弱点和想复习的题目中，挑出10分钟内能做完的量',
    examEveTitle: '考前模式',
    examEveSubtitle: '复习最近做错的题、高频题和公式',
    checklistTitle: '考试当天清单',
    premiumNote: '高级版可用',
    emptyPlan: '目前没有可出的题目。',
    emptyEve: '还没有需要复习的题目。在“学习”中作答后会汇集到这里。',
    updateLogTitle: '更新日志',
    updateLogSubtitle: '查看题目和解析的新增与订正记录',
    updateLogEmpty: '最近没有更新。',
    exportTitle: '导出学习数据（CSV）',
    exportSubtitle: '导出每天的答题数、正确率和各领域的正确率',
    exportEmpty: '还没有可导出的记录。作答后会汇集到这里。',
    exportCopy: '复制',
    exportCopied: '已复制',
    exportNote: '不含姓名、ID、设备信息和题目文字。',
    confirmNeeded: '请以官方为准',
    checklistDone: '准备好了。保持冷静，像平时一样。',
    checklistNote: '请务必查看官方考试指南。各项仅供参考。',
    progress: _zhProgress,
    eveDays: _zhEveDays,
    countdown: _zhCountdown,
    affected: _zhAffected,
    categoryBelongings: '携带物品',
    categoryTravel: '前往考场',
    categoryAdmission: '准考证与身份确认',
    categoryEnvironment: '考试环境',
    kindLawChange: '法律修订',
    kindSyllabusChange: '考试范围修订',
    kindCorrection: '订正',
    kindNewContent: '新增',
    defaultChecklistLabels: {
      'default-ticket': '已准备好准考证',
      'default-id': '已在考试指南中确认身份确认方式',
      'default-belongings': '已准备好文具等物品',
      'default-allowed': '已确认可带入和不可带入的物品',
      'default-route': '已确认前往考场的路线和所需时间',
      'default-margin': '已计划提前出发，时间充裕',
      'default-net': '已确认网络环境和考试用的房间',
    },
  );

  static const zhHant = ExamPrepStrings(
    sectionTitle: '備考',
    tenMinTitle: '今日10分鐘計畫',
    tenMinSubtitle: '從弱點和想複習的題目中，挑出10分鐘內能做完的量',
    examEveTitle: '考前模式',
    examEveSubtitle: '複習最近答錯的題、高頻題和公式',
    checklistTitle: '考試當天清單',
    premiumNote: '進階版可用',
    emptyPlan: '目前沒有可出的題目。',
    emptyEve: '還沒有需要複習的題目。在「學習」中作答後會匯集到這裡。',
    updateLogTitle: '更新日誌',
    updateLogSubtitle: '查看題目和解析的新增與訂正紀錄',
    updateLogEmpty: '最近沒有更新。',
    exportTitle: '匯出學習資料（CSV）',
    exportSubtitle: '匯出每天的作答數、正確率和各領域的正確率',
    exportEmpty: '還沒有可匯出的紀錄。作答後會匯集到這裡。',
    exportCopy: '複製',
    exportCopied: '已複製',
    exportNote: '不含姓名、ID、裝置資訊和題目文字。',
    confirmNeeded: '請以官方為準',
    checklistDone: '準備好了。保持冷靜，像平常一樣。',
    checklistNote: '請務必查看官方考試簡章。各項僅供參考。',
    progress: _zhHantProgress,
    eveDays: _zhHantEveDays,
    countdown: _zhHantCountdown,
    affected: _zhHantAffected,
    categoryBelongings: '攜帶物品',
    categoryTravel: '前往考場',
    categoryAdmission: '准考證與身分確認',
    categoryEnvironment: '考試環境',
    kindLawChange: '法規修訂',
    kindSyllabusChange: '考試範圍修訂',
    kindCorrection: '訂正',
    kindNewContent: '新增',
    defaultChecklistLabels: {
      'default-ticket': '已準備好准考證',
      'default-id': '已在考試簡章中確認身分確認方式',
      'default-belongings': '已準備好文具等物品',
      'default-allowed': '已確認可帶入和不可帶入的物品',
      'default-route': '已確認前往考場的路線和所需時間',
      'default-margin': '已計畫提早出發，時間充裕',
      'default-net': '已確認網路環境和考試用的房間',
    },
  );

  static const ko = ExamPrepStrings(
    sectionTitle: '시험 준비',
    tenMinTitle: '오늘의 10분 플랜',
    tenMinSubtitle: '약점과 다시 보고 싶은 문제 중에서 10분 안에 풀 만큼 고릅니다',
    examEveTitle: '시험 직전 모드',
    examEveSubtitle: '최근 틀린 문제·빈출 문제·계산식을 복습합니다',
    checklistTitle: '시험 당일 체크리스트',
    premiumNote: '프리미엄에서 사용할 수 있어요',
    emptyPlan: '지금은 출제할 문제가 없습니다.',
    emptyEve: '복습할 문제가 아직 없습니다. 「학습」에서 풀면 여기에 모입니다.',
    updateLogTitle: '업데이트 기록',
    updateLogSubtitle: '문제와 해설의 추가·정정 기록을 볼 수 있어요',
    updateLogEmpty: '최근 업데이트가 없습니다.',
    exportTitle: '학습 데이터 내보내기 (CSV)',
    exportSubtitle: '날짜별 풀이 수·정답률과 분야별 정답률을 내보냅니다',
    exportEmpty: '아직 내보낼 기록이 없습니다. 풀면 여기에 모입니다.',
    exportCopy: '복사',
    exportCopied: '복사했습니다',
    exportNote: '이름·ID·기기 정보·문제 본문은 포함되지 않습니다.',
    confirmNeeded: '공식 안내 확인 필요',
    checklistDone: '준비가 끝났어요. 침착하게, 평소처럼.',
    checklistNote: '반드시 공식 시험 안내를 확인하세요. 항목은 참고용입니다.',
    progress: _koProgress,
    eveDays: _koEveDays,
    countdown: _koCountdown,
    affected: _koAffected,
    categoryBelongings: '준비물',
    categoryTravel: '시험장까지 이동',
    categoryAdmission: '수험표·본인 확인',
    categoryEnvironment: '시험 환경',
    kindLawChange: '법 개정',
    kindSyllabusChange: '출제 범위 개정',
    kindCorrection: '정정',
    kindNewContent: '추가',
    defaultChecklistLabels: {
      'default-ticket': '수험표를 준비했다',
      'default-id': '본인 확인 방법을 시험 안내에서 확인했다',
      'default-belongings': '필기구 등 준비물을 챙겼다',
      'default-allowed': '반입 가능·불가 물품을 확인했다',
      'default-route': '시험장까지의 경로와 소요 시간을 확인했다',
      'default-margin': '여유 있게 도착하도록 계획을 세웠다',
      'default-net': '통신 환경과 시험 볼 방을 확인했다',
    },
  );

  /// [KitStrings.languageCode] に対応する文言。無い言語は日本語。
  static ExamPrepStrings forLanguageCode(String code) => switch (code) {
    'en' => en,
    'ko' => ko,
    'zh' => zhHans,
    'zh-Hant' => zhHant,
    _ => ja,
  };

  /// 最も近い `KitStringsScope` の言語に合う文言。無ければ日本語。
  static ExamPrepStrings of(BuildContext context) =>
      forLanguageCode(KitStrings.of(context).languageCode);
}

String _jaProgress(int d, int t) => '$d / $t 完了';
String _enProgress(int d, int t) => '$d of $t done';
String _zhProgress(int d, int t) => '已完成 $d / $t';
String _zhHantProgress(int d, int t) => '已完成 $d / $t';
String _koProgress(int d, int t) => '$d / $t 완료';

String _jaEveDays(int n) => n == 0 ? '試験直前モード（今日が試験日）' : '試験直前モード（あと$n日）';
String _enEveDays(int n) => n == 0
    ? 'Final-days mode (exam day is today)'
    : 'Final-days mode ($n days left)';
String _zhEveDays(int n) => n == 0 ? '考前模式（今天考试）' : '考前模式（还剩$n天）';
String _zhHantEveDays(int n) => n == 0 ? '考前模式（今天考試）' : '考前模式（還剩$n天）';
String _koEveDays(int n) => n == 0 ? '시험 직전 모드 (오늘이 시험일)' : '시험 직전 모드 ($n일 남음)';

String _jaCountdown(int n) =>
    n > 0 ? '本番まであと$n日' : (n == 0 ? '本番は今日です' : '本番から${-n}日経過しました');
String _enCountdown(int n) => n > 0
    ? '$n days to the exam'
    : (n == 0 ? 'The exam is today' : '${-n} days since the exam');
String _zhCountdown(int n) =>
    n > 0 ? '距离考试还有$n天' : (n == 0 ? '今天考试' : '考试已过去${-n}天');
String _zhHantCountdown(int n) =>
    n > 0 ? '距離考試還有$n天' : (n == 0 ? '今天考試' : '考試已過去${-n}天');
String _koCountdown(int n) =>
    n > 0 ? '시험까지 $n일' : (n == 0 ? '오늘이 시험일입니다' : '시험 후 ${-n}일 지났습니다');

String _jaAffected(int n) => '$n問';
String _enAffected(int n) => n == 1 ? '1 question' : '$n questions';
String _zhAffected(int n) => '$n题';
String _zhHantAffected(int n) => '$n題';
String _koAffected(int n) => '$n문제';
