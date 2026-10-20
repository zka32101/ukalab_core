import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';

import '../../policy/premium_features.dart';

/// プレミアム機能ひとつぶんの、ユーザー向けの名前と一言説明。
class PremiumBenefit {
  const PremiumBenefit(this.name, this.description);
  final String name;
  final String description;
}

/// [PremiumBenefitsCard] の文言。価格は含めない（購入ボタン側が表示する）。
class PremiumBenefitsStrings {
  const PremiumBenefitsStrings({
    required this.title,
    required this.freeNote,
    required this.benefits,
  });

  final String title;

  /// 無料のまま使える範囲の一文。
  final String freeNote;
  final Map<PremiumFeature, PremiumBenefit> benefits;

  /// 画面に出すすべての文言（テスト用）。
  List<String> get allTexts => [
    title,
    freeNote,
    for (final b in benefits.values) ...[b.name, b.description],
  ];

  static const ja = PremiumBenefitsStrings(
    title: 'プレミアムでできること',
    freeNote: '問題・解説・模擬試験・基本の苦手特訓は、無料のまま使えます。',
    benefits: {
      PremiumFeature.weakDrill: PremiumBenefit(
        '弱点集中ドリル',
        '間違えた原因ごとの集計と推移を見ながら、弱点を集中して練習できます。',
      ),
      PremiumFeature.examEveMode: PremiumBenefit(
        '試験直前モード',
        '試験日の3日前から、最近間違えた問題などを見直せます。',
      ),
      PremiumFeature.tenMinutePlan: PremiumBenefit(
        '今日の10分プラン',
        '10分に収まる分だけ、今日解く問題を選びます。',
      ),
      PremiumFeature.historyExport: PremiumBenefit(
        '学習履歴の書き出し',
        '日ごとの解答数や分野ごとの正答率をファイルに保存できます。',
      ),
      PremiumFeature.mockExamHistory: PremiumBenefit(
        '模擬試験の成長グラフ',
        '複数回分の得点率を並べて、伸びを確かめられます。',
      ),
      PremiumFeature.customMockExam: PremiumBenefit(
        'カスタム模擬試験',
        '科目を指定して、模擬試験を出題できます。',
      ),
      PremiumFeature.readingReadAloud: PremiumBenefit(
        '解説読み物の読み上げ',
        '章ごとの解説読み物を、全文読み上げで聞けます。',
      ),
    },
  );

  static const en = PremiumBenefitsStrings(
    title: 'What Premium adds',
    freeNote:
        'Questions, explanations, mock exams and basic weak-point practice stay free.',
    benefits: {
      PremiumFeature.weakDrill: PremiumBenefit(
        'Weak-point drill',
        'Practice your weak spots, with stats and trends by cause of mistakes.',
      ),
      PremiumFeature.examEveMode: PremiumBenefit(
        'Final-days mode',
        'From 3 days before the exam, review questions you missed recently.',
      ),
      PremiumFeature.tenMinutePlan: PremiumBenefit(
        "Today's 10-minute plan",
        'Picks as many questions as fit in 10 minutes.',
      ),
      PremiumFeature.historyExport: PremiumBenefit(
        'Export study history',
        'Save daily answer counts and accuracy by topic as a file.',
      ),
      PremiumFeature.mockExamHistory: PremiumBenefit(
        'Mock exam growth chart',
        'Compare your scores across several mock exams.',
      ),
      PremiumFeature.customMockExam: PremiumBenefit(
        'Custom mock exam',
        'Choose subjects and take a mock exam on them.',
      ),
      PremiumFeature.readingReadAloud: PremiumBenefit(
        'Read-aloud for readings',
        'Listen to the full text of each chapter reading.',
      ),
    },
  );

  static const zhHans = PremiumBenefitsStrings(
    title: '高级版可使用的功能',
    freeNote: '题目、解析、模拟考试和基础的薄弱点练习仍可免费使用。',
    benefits: {
      PremiumFeature.weakDrill: PremiumBenefit('薄弱点强化练习', '按错误原因查看统计和变化，集中练习薄弱点。'),
      PremiumFeature.examEveMode: PremiumBenefit('考前模式', '考试前3天起，可复习最近做错的题目。'),
      PremiumFeature.tenMinutePlan: PremiumBenefit('今日10分钟计划', '挑选10分钟内能完成的题目。'),
      PremiumFeature.historyExport: PremiumBenefit('导出学习记录', '将每日作答数和各领域正确率保存为文件。'),
      PremiumFeature.mockExamHistory: PremiumBenefit('模拟考试成长图', '并排比较多次模拟考试的得分率。'),
      PremiumFeature.customMockExam: PremiumBenefit('自定义模拟考试', '指定科目进行模拟考试。'),
      PremiumFeature.readingReadAloud: PremiumBenefit('解说读物朗读', '全文朗读各章的解说读物。'),
    },
  );

  static const zhHant = PremiumBenefitsStrings(
    title: '進階版可使用的功能',
    freeNote: '題目、解析、模擬考試和基礎的弱點練習仍可免費使用。',
    benefits: {
      PremiumFeature.weakDrill: PremiumBenefit('弱點強化練習', '依錯誤原因查看統計和變化，集中練習弱點。'),
      PremiumFeature.examEveMode: PremiumBenefit('考前模式', '考試前3天起，可複習最近答錯的題目。'),
      PremiumFeature.tenMinutePlan: PremiumBenefit('今日10分鐘計畫', '挑選10分鐘內能完成的題目。'),
      PremiumFeature.historyExport: PremiumBenefit('匯出學習紀錄', '將每日作答數和各領域正確率儲存為檔案。'),
      PremiumFeature.mockExamHistory: PremiumBenefit('模擬考試成長圖', '並排比較多次模擬考試的得分率。'),
      PremiumFeature.customMockExam: PremiumBenefit('自訂模擬考試', '指定科目進行模擬考試。'),
      PremiumFeature.readingReadAloud: PremiumBenefit('解說讀物朗讀', '全文朗讀各章的解說讀物。'),
    },
  );

  static const ko = PremiumBenefitsStrings(
    title: '프리미엄으로 할 수 있는 것',
    freeNote: '문제·해설·모의시험·기본 취약점 연습은 무료로 계속 쓸 수 있습니다.',
    benefits: {
      PremiumFeature.weakDrill: PremiumBenefit('취약점 집중 드릴', '틀린 원인별 통계와 추이를 보며 취약점을 집중 연습합니다.'),
      PremiumFeature.examEveMode: PremiumBenefit('시험 직전 모드', '시험 3일 전부터 최근 틀린 문제를 복습합니다.'),
      PremiumFeature.tenMinutePlan: PremiumBenefit('오늘의 10분 플랜', '10분 안에 풀 수 있는 만큼 문제를 골라 줍니다.'),
      PremiumFeature.historyExport: PremiumBenefit('학습 기록 내보내기', '일별 풀이 수와 분야별 정답률을 파일로 저장합니다.'),
      PremiumFeature.mockExamHistory: PremiumBenefit('모의시험 성장 그래프', '여러 번의 득점률을 나란히 비교합니다.'),
      PremiumFeature.customMockExam: PremiumBenefit('맞춤 모의시험', '과목을 지정해 모의시험을 풉니다.'),
      PremiumFeature.readingReadAloud: PremiumBenefit('해설 읽을거리 낭독', '장별 해설 읽을거리를 전문 낭독으로 들을 수 있습니다.'),
    },
  );

  /// [KitStrings.languageCode] に対応する文言。無い言語は日本語。
  static PremiumBenefitsStrings forLanguageCode(String code) => switch (code) {
    'en' => en,
    'ko' => ko,
    'zh' => zhHans,
    'zh-Hant' => zhHant,
    _ => ja,
  };

  /// 最も近い `KitStringsScope` の言語に合う文言。無ければ日本語。
  static PremiumBenefitsStrings of(BuildContext context) =>
      forLanguageCode(KitStrings.of(context).languageCode);
}

/// プレミアムで使える機能の名前と一言説明の一覧。設定画面の購入節に差し込む。
/// 価格は載せない（購入ボタン側が表示する）。[features] で表示する機能と順序を絞れる。
class PremiumBenefitsCard extends StatelessWidget {
  const PremiumBenefitsCard({
    super.key,
    this.features = PremiumFeature.values,
    this.showFreeNote = true,
    this.strings,
  });

  final List<PremiumFeature> features;

  /// 無料のまま使える範囲の一文を末尾に出すか。
  final bool showFreeNote;
  final PremiumBenefitsStrings? strings;

  @override
  Widget build(BuildContext context) {
    final s = strings ?? PremiumBenefitsStrings.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.title, style: theme.textTheme.titleSmall),
            for (final f in features)
              if (s.benefits[f] case final b?)
                Padding(
                  key: ValueKey('premiumBenefit_${f.name}'),
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.name, style: theme.textTheme.bodyMedium),
                            Text(
                              b.description,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            if (showFreeNote) ...[
              const SizedBox(height: 12),
              Text(
                s.freeNote,
                key: const ValueKey('premiumFreeNote'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
