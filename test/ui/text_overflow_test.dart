// 狭い幅（320 / 280dp）× 大きい文字倍率（1 / 2 / 3）で、共通UI部品が
// RenderFlex overflow などを起こさないことを確かめる（文字切れ・はみ出しの回帰防止）。
//
// 長い文言（アプリが渡す題名・分野名・ラベル）を入れて確かめる。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/achievements.dart';
import 'package:ukalab_core/answer_feedback.dart';
import 'package:ukalab_core/daily_goal.dart';
import 'package:ukalab_core/glossary.dart';
import 'package:ukalab_core/reminder.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

const _long = 'とても長い文言のサンプルです。文字が大きくなっても、はみ出したり切れたりしないことを確認します。';
const _longWord = 'ながいながいながいながいながいながいながいながいながいながい';

const _sizes = [Size(320, 568), Size(280, 480)];
const _scales = [1.0, 2.0, 3.0];

Future<List<String>> _errorsFor(
  WidgetTester tester,
  Widget Function() build, {
  Future<void> Function(WidgetTester)? act,
  bool scroll = true,
  List<Override> overrides = const [],
}) async {
  final errors = <String>[];
  final prev = FlutterError.onError;
  FlutterError.onError = (d) {
    final lines = d.toString().split('\n');
    final i = lines.indexWhere((l) => l.contains('error-causing widget'));
    final where = i >= 0 && i + 1 < lines.length ? lines[i + 1].trim() : '';
    errors.add('${d.exceptionAsString().split('\n').first} $where');
  };
  try {
    for (final size in _sizes) {
      for (final scale in _scales) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        final before = errors.length;
        await tester.pumpWidget(ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: SafeArea(child: scroll ? SingleChildScrollView(child: build()) : build()),
            ),
          ),
        ));
        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (act != null) await act(tester);
        for (var i = before; i < errors.length; i++) {
          errors[i] = '${size.width.toInt()}dp x$scale: ${errors[i]}';
        }
        await tester.pumpWidget(const SizedBox());
      }
    }
  } finally {
    FlutterError.onError = prev;
    addTearDown(tester.view.reset);
  }
  return errors;
}

Future<List<String>> _dialogErrors(WidgetTester tester, Future<void> Function(BuildContext) open) => _errorsFor(
      tester,
      () => Builder(
        builder: (c) => TextButton(key: const Key('open'), onPressed: () => open(c), child: const Text('open')),
      ),
      act: (t) async {
        await t.tap(find.byKey(const Key('open')));
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
      },
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> check(WidgetTester t, Map<String, Future<List<String>> Function()> cases) async {
    final all = <String>[];
    for (final e in cases.entries) {
      all.addAll((await e.value()).map((m) => '${e.key}: $m'));
    }
    if (all.isNotEmpty) fail(all.join('\n'));
  }

  testWidgets('ホームの部品（HomeSectionHeader / HomeMenuTile / HomeMenuGrid / HomeSection）', (t) async {
    List<HomeMenuItem> items() => [
          for (var i = 0; i < 4; i++)
            HomeMenuItem(
              icon: Icons.star,
              title: _long,
              subtitle: _long,
              badge: i.isEven ? const HomeMenuBadge.label(_longWord) : HomeMenuBadge.count(120),
              onTap: () {},
            ),
        ];
    await check(t, {
      'header': () => _errorsFor(
            t,
            () => HomeSectionHeader(
              title: _long,
              subtitle: _long,
              leading: const Text('🎯'),
              trailing: TextButton(onPressed: () {}, child: const Text('すべて見る')),
            ),
          ),
      'tile': () => _errorsFor(
            t,
            () => Column(children: [
              HomeMenuTile(
                icon: Icons.home,
                title: _long,
                subtitle: _long,
                badge: const HomeMenuBadge.label('NEW'),
                onTap: () {},
              ),
              HomeMenuTile(
                icon: Icons.home,
                title: 'a',
                badge: const HomeMenuBadge.label(_longWord),
                onTap: () {},
              ),
            ]),
          ),
      'grid1': () => _errorsFor(t, () => HomeMenuGrid(items: items())),
      'section': () => _errorsFor(
            t,
            () => HomeSection(
              title: _long,
              subtitle: _long,
              collapsible: true,
              trailing: TextButton(onPressed: () {}, child: const Text('すべて見る')),
              child: const Text(_long),
            ),
          ),
    });
  });

  testWidgets('学習カード（今日の復習・模擬試験分析・週間まとめ・試験日カウントダウン）', (t) async {
    final answers = [
      for (var i = 0; i < 4; i++) MockExamAnswer(topicId: 't1', correct: i < 1),
      for (var i = 0; i < 4; i++) MockExamAnswer(topicId: 't2', correct: i < 2),
      for (var i = 0; i < 4; i++) MockExamAnswer(topicId: 't4', correct: i < 3),
    ];
    final recap = WeeklyRecap(
      weekStart: DateTime(2026, 10, 12),
      answered: 42,
      correct: 30,
      studyDays: 5,
      streakDays: 3,
      topTopics: const [WeeklyRecapTopic(topicId: 't1', answered: 20, correct: 15)],
      improvedTopics: const ['t2'],
      medalsEarned: 2,
    );
    await check(t, {
      'todayReview': () => _errorsFor(t, () => TodayReviewCard(dueCount: 12, onStart: () {})),
      'todayReviewEmpty': () => _errorsFor(t, () => TodayReviewCard(dueCount: 0, onStart: () {})),
      'mockExam': () => _errorsFor(
            t,
            () => MockExamAnalysisCard(
              analysis: const MockExamAnalysisEngine().analyze(answers),
              topicLabel: (id) => '$_long $id',
            ),
          ),
      'weeklyRecap': () => _errorsFor(t, () => WeeklyRecapCard(recap: recap, topicLabel: (id) => '$_long $id')),
      'examCountdown': () => _errorsFor(
            t,
            () => Column(children: [
              ExamCountdownChip(examDate: DateTime(2026, 12, 1), clock: () => DateTime(2026, 10, 14)),
              ExamCountdownCard(examDate: DateTime(2026, 10, 20), clock: () => DateTime(2026, 10, 14)),
              ExamCountdownCard(examDate: DateTime(2026, 12, 1), clock: () => DateTime(2026, 10, 14)),
            ]),
          ),
      'peerStats': () => _errorsFor(
            t,
            () => PeerStatsCard(
              snapshot: PeerStatsSnapshot(
                asOf: '2026-10-14',
                activeToday: 123456,
                participants: 123456,
                totalQuestions: 987654321,
                medianQuestions: 12345,
                streakCounts: const {1: 100000, 365: 23456},
                examDateCounts: const {'2026-12-01': 123456},
              ),
              streakDays: 365,
              examDate: DateTime(2026, 12, 1),
              clock: () => DateTime(2026, 10, 14),
            ),
          ),
    });
  });

  testWidgets('推しの成長（吹き出し・お祝いカード・ダイアログ）', (t) async {
    await check(t, {
      'bubble': () => _errorsFor(
            t,
            () => const Column(children: [
              OshiGrowthBubble(progress: OshiGrowthProgress(totalAnswered: 120, studyDays: 12), seed: 1),
              OshiGrowthBubble(progress: OshiGrowthProgress(totalAnswered: 2500, studyDays: 90), seed: 2),
            ]),
          ),
      'card': () => _errorsFor(
            t,
            () => OshiGrowthCelebrationCard(
              celebration: const OshiGrowthEngine().celebrate(const OshiGrowthMilestone.answered(100)),
              avatar: const SizedBox(width: 96, height: 96),
            ),
          ),
      'dialog': () => _dialogErrors(
            t,
            (c) => showOshiGrowthDialog(c, milestone: const OshiGrowthMilestone.days(7)),
          ),
    });
  });

  testWidgets('カード・タイル類（結果・準備度・コイン・用語・ニュース・タブ）', (t) async {
    const rule = ReadinessRule.standard;
    await check(t, {
      'readiness': () => _errorsFor(
            t,
            () => ReadinessProgressCard(
              progress: rule.progress(mastery: const MasteryInput(coverage: 0.7, accuracy: 0.7), mockPassed: false),
            ),
          ),
      'coinBreakdown': () => _errorsFor(
            t,
            () => CoinBreakdownCard(grants: [
              for (final e in [CoinEvent.newQuestion('q1'), CoinEvent.mockPass('m1'), CoinEvent.mockBest('m2')])
                CoinGrant(e, 5),
            ]),
          ),
      'wrongCause': () => _errorsFor(t, () => WrongCauseSelector(onSelected: (_) {})),
      'aiNews': () => _errorsFor(
            t,
            () => AiNewsCard(items: [
              AiNewsItemSpec(
                summary: _long,
                sourceUrl: 'https://example.com/news/1/${'a' * 60}',
                sourceDate: DateTime(2026, 9, 1),
                syllabusTag: _long,
                asOfDate: DateTime(2026, 10, 1),
              ),
            ]),
          ),
      'termCard': () => _errorsFor(
            t,
            () => TermCard(
              term: _long,
              headline: _long,
              definition: _long,
              analogy: _long,
              commonMistake: _long,
              relatedTerms: const [RelatedTermRef(termId: 't2', label: _long)],
              relatedQuestions: const [RelatedQuestionRef(questionId: 'q1', label: _long)],
              onRelatedTermTap: (_) {},
              onRelatedQuestionTap: (_) {},
            ),
          ),
      'oshiMessage': () => _errorsFor(
            t,
            () => const OshiMessageBubble(situation: OshiMessageContext(streakDays: 5), seed: 100),
          ),
      'oshiCard': () => _errorsFor(
            t,
            () => const UkalabOshiCard(cert: UkalabCert.bikeLicense, stage: MascotStage.lv1, appId: 'x'),
          ),
      'shell': () => _errorsFor(
            t,
            () => UkalabShell(pages: [for (var i = 0; i < 5; i++) Center(child: Text('page $i'))]),
            scroll: false,
          ),
    });
  });

  testWidgets('振り返り（弱点・解答後・間違いノート）', (t) async {
    final now = DateTime(2026, 10, 13, 12);
    ProgressRecord rec(String chapter, DateTime at, WrongCause? cause) => ProgressRecord(
          qid: 'q-$chapter-${at.microsecondsSinceEpoch}',
          subjectId: 'math',
          correct: false,
          at: at,
          topicId: chapter,
          cause: cause,
        );
    final records = [
      rec('ch1', now.subtract(const Duration(days: 10)), null),
      rec('ch1', now.subtract(const Duration(days: 1)), WrongCause.trap),
      rec('ch1', now.subtract(const Duration(days: 1, hours: 1)), WrongCause.trap),
      rec('ch2', now.subtract(const Duration(days: 2)), WrongCause.calculation),
    ];
    Question q(String id, {List<String>? compareWith}) => Question.fromJson({
          'qid': id,
          'examId': 'sample',
          'subjectId': 'math',
          'topicId': 'ch1',
          'prompt': _long,
          'choices': [_long, _long, _long],
          'answerIndex': 1,
          'explanation': _long,
          'source': 'original',
          'sourceRef': '自作',
          'contentVer': '1',
          if (compareWith != null) 'compareWith': compareWith,
        });
    Term term(String id, String name) => Term.fromJson({
          'termId': id,
          'examId': 'sample',
          'term': name,
          'headline': _long,
          'definition': _long,
          'commonMistake': _long,
          'relatedQuestionIds': const ['q1'],
          'source': 'original',
          'sourceRef': '自作',
          'contentVer': '1',
        });
    MistakeNoteEntry e(String qid, int day, {bool overcome = false}) => MistakeNoteEntry(
          qid: qid,
          firstMissedAt: DateTime(2026, 10, day),
          lastMissedAt: DateTime(2026, 10, day),
          missCount: 12,
          overcome: overcome,
          lastCause: WrongCause.trap,
          topicId: 'x',
          lastAnsweredAt: DateTime(2026, 10, day),
        );
    await check(t, {
      'weakSummary': () => _errorsFor(
            t,
            () => WeakSummaryCard(records: records, now: now, chapterLabel: (id) => '$_long $id'),
          ),
      'answerFeedback': () => _errorsFor(
            t,
            () => AnswerFeedbackPanel(
              question: q('q1', compareWith: const ['t2']),
              selectedIndex: 0,
              terms: [term('t1', _long), term('t2', _long)],
              onCause: (_) {},
            ),
          ),
      'mistakeNote': () => _errorsFor(
            t,
            () => SizedBox(
              height: 480,
              child: MistakeNoteView(
                entries: [e('a', 1), e('b', 2), e('c', 3, overcome: true)],
                questionBuilder: (c, x) => Text('${x.qid} $_long'),
                onRetry: (_) {},
                celebrateQids: const {'c'},
                topicLabel: (id) => '$_long $id',
              ),
            ),
          ),
    });
  });

  testWidgets('共有カードとダイアログ（メダル・ギフト・合格カード）', (t) async {
    const medal = OshiMedal(id: 'm1', label: _long, tier: 2, kind: OshiMedalKind.streak);
    final data = ShareCardData(
      certLabel: _long,
      date: DateTime(2026, 10, 9),
      packName: 'p',
      stage: MascotStage.lv1,
      scoreText: _long,
      message: _long,
    );
    const gift = OshiGift(
      id: 'bg_streak7',
      kind: OshiGiftKind.background,
      condition: OshiGiftCondition.streakDays(7),
      name: _long,
    );
    await check(t, {
      'medalDialog': () => _dialogErrors(
            t,
            (c) => showOshiMedalDialog(c, medal: medal, now: DateTime(2026, 10, 13), onShare: (_) async {}, onSave: (_) async {}),
          ),
      'giftDialog': () => _dialogErrors(t, (c) => showOshiGiftDialog(c, gift: gift)),
      'passCard': () => _errorsFor(t, () => PassShareCard(data: data)),
      'medalCard': () => _errorsFor(t, () => OshiMedalShareCard(medal: medal, date: DateTime(2026, 10, 13))),
    });
  });

  testWidgets('ラボ系（混同行列・予測・機械学習・NN・用語マップ）', (t) async {
    const points = [
      MlLabPointSpec(x: 1, y: 1, label: 0),
      MlLabPointSpec(x: 2, y: 1.5, label: 0),
      MlLabPointSpec(x: 8, y: 8, label: 1),
      MlLabPointSpec(x: 9, y: 8, label: 1),
    ];
    await check(t, {
      'confusionMatrix': () => _errorsFor(
            t,
            () => ConfusionMatrixLabWidget(
              scenario: ConfusionMatrixScenarioSpec(
                title: _long,
                description: _long,
                initialTp: 40,
                initialFp: 10,
                initialFn: 10,
                initialTn: 40,
                options: const [
                  FailureChoiceSpec(optionId: 'recall', text: _long, isCorrect: true),
                  FailureChoiceSpec(optionId: 'precision', text: _long, isCorrect: false),
                ],
                explanation: _long,
              ),
            ),
          ),
      'predictRun': () => _errorsFor(
            t,
            () => const PredictRunWidget(title: _long, question: _long, correctAnswer: 0.15, explanation: _long),
          ),
      'mlLab': () => _errorsFor(t, () => const MlLabWidget(title: _long, description: _long, points: points)),
      'nnBuilder': () => _errorsFor(t, () => const NnBuilderWidget(
              title: _long,
              description: _long,
              points: [
                NnBuilderPointSpec(x: 1, y: 1, label: 0),
                NnBuilderPointSpec(x: 2, y: 1.5, label: 0),
                NnBuilderPointSpec(x: 8, y: 8, label: 1),
                NnBuilderPointSpec(x: 9, y: 8, label: 1),
              ],
            )),
      'termMap': () => _errorsFor(
            t,
            () => TermMapWidget(
              nodes: const [
                TermMapNodeSpec(termId: 'a', label: _long, era: 'e1', mastery: TermMastery.mastered),
                TermMapNodeSpec(termId: 'b', label: _long, era: 'e1', mastery: TermMastery.weak),
              ],
              eraOrder: const {'e1': _long},
              onNodeTap: (_) {},
            ),
          ),
    });
  });

  testWidgets('設定・目標・実績・用語集・データ管理', (t) async {
    SharedPreferences.setMockInitialValues({});
    final o = (await t.runAsync(() async => [
          ...await dailyGoalOverrides('t'),
          ...await reminderOverrides('t'),
          ...await achievementUnlockOverrides('t'),
        ]))!;
    const list = [
      Achievement(id: 'a', title: _long, description: _long, icon: Icons.star, unlocked: true, category: 'x'),
      Achievement(id: 'b', title: _long, description: _long, icon: Icons.star, unlocked: false, category: 'y'),
    ];
    Term term(String id, String name, String subject) => Term(
          termId: id,
          examId: 'x',
          term: name,
          headline: _long,
          definition: '定義',
          source: QuestionSource.original,
          sourceRef: '',
          contentVer: '1',
          subjectId: subject,
        );
    await check(t, {
      'dailyGoalAndReminder': () => _errorsFor(
            t,
            () => Column(children: [
              const DailyGoalSetting(),
              const DailyMissionCard(),
              StudyReminderCard(now: DateTime(2026, 10, 10, 20)),
              const ReminderSettingsSection(),
            ]),
            overrides: o,
          ),
      'achievements': () => _errorsFor(
            t,
            () => const AchievementsView(categoryLabels: {'x': _long, 'y': _long}),
            overrides: [...o, achievementsProvider.overrideWithValue(list)],
            scroll: false,
          ),
      'glossary': () => _errorsFor(
            t,
            () => GlossaryListView(
              terms: [term('1', _long, 's1'), term('2', _long, 's2')],
              store: LearnedTermsStore('t'),
              subjects: const {'s1': _long, 's2': _long},
            ),
            scroll: false,
          ),
      'dataManagement': () => _errorsFor(
            t,
            () => DataManagementSection(parts: [
              DataPart(id: 'a', export: (ref) => 1, restore: (ref, json) async {}, reset: (ref) async {}),
            ]),
            overrides: o,
          ),
    });
  });

  testWidgets('試験準備（カード・チェックリスト・更新ログ・書き出し・設定タイル）', (t) async {
    final qs = [
      Question(
        qid: 'q1',
        examId: 'sample',
        subjectId: 'law',
        topicId: 'ch1',
        prompt: _long,
        choices: const ['A', 'B'],
        answerIndex: 0,
        explanation: _long,
        source: QuestionSource.original,
        sourceRef: '自作',
        contentVer: '1',
      ),
    ];
    await check(t, {
      'examPrepCard': () => _errorsFor(
            t,
            () => ExamPrepCard(
              questions: () => qs,
              records: () => const [],
              examDate: DateTime(2026, 10, 20),
              clock: () => DateTime(2026, 10, 14),
              tenMinUnlocked: true,
              examEveUnlocked: true,
              onStartPractice: (c, a, b, d) {},
              onOpenChecklist: (c) {},
              onLockedTap: (c) {},
            ),
          ),
      'checklist': () => _errorsFor(t, () => SizedBox(height: 2400, child: ExamDayChecklistView(examId: 'x', onChanged: (_) {}))),
      'updateLog': () => _errorsFor(
            t,
            () => UpdateLogView(
              entriesFuture: Future.value([
                UpdateLogEntry(
                  entryId: 'a',
                  examId: 'x',
                  date: DateTime(2026, 10, 10),
                  kind: UpdateKind.correction,
                  title: _long,
                  affectedQuestions: 2,
                ),
              ]),
            ),
            scroll: false,
          ),
      'historyExport': () => _errorsFor(
            t,
            () => HistoryExportView(
              records: [
                ProgressRecord(qid: 'q1', subjectId: 'law', topicId: 'ch1', at: DateTime(2026, 10, 12, 9), correct: true),
              ],
              questions: qs,
            ),
            scroll: false,
          ),
      'settingsTiles': () => _errorsFor(
            t,
            () => ExamPrepSettingsTiles(onOpenUpdateLog: (c) {}, onOpenExport: (c) {}, exportUnlocked: false),
          ),
    });
  });
}
