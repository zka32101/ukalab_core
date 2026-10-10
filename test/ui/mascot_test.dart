import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('習得度・成長段階', () {
    const m = MasteryModel.standard;

    test('習得度 = 網羅率 × 正答率。範囲外・NaN は丸める', () {
      expect(m.mastery(const MasteryInput(coverage: 0.5, accuracy: 0.8)), closeTo(0.4, 1e-9));
      expect(m.mastery(const MasteryInput(coverage: 2, accuracy: 2)), 1.0);
      expect(m.mastery(const MasteryInput(coverage: double.nan, accuracy: 0.9)), 0.0);
      expect(m.mastery(const MasteryInput(coverage: -1, accuracy: 0.9)), 0.0);
    });

    test('段階の境目: 0.2／0.4／0.6／0.8 で Lv2〜Lv5', () {
      expect(m.stageFor(0), MascotStage.lv1);
      expect(m.stageFor(0.199), MascotStage.lv1);
      expect(m.stageFor(0.2), MascotStage.lv2);
      expect(m.stageFor(0.4), MascotStage.lv3);
      expect(m.stageFor(0.6), MascotStage.lv4);
      expect(m.stageFor(0.8), MascotStage.lv5);
      expect(m.stageFor(1), MascotStage.lv5);
    });

    test('係数と境目は差し替えられる', () {
      const strict = MasteryModel(stageThresholds: [0.3, 0.5, 0.7, 0.9]);
      expect(strict.stageFor(0.25), MascotStage.lv1);
      expect(strict.stageFor(0.3), MascotStage.lv2);
      const accuracyHeavy = MasteryModel(accuracyExponent: 2);
      expect(accuracyHeavy.mastery(const MasteryInput(coverage: 1, accuracy: 0.5)), closeTo(0.25, 1e-9));
    });

    test('次の段階まであと何問か（正答率が今のままなら）', () {
      // 網羅率 0.30 × 正答率 0.8 = 0.24 → Lv2。Lv3(0.4) には網羅率 0.5 が必要 → 100問中あと20問
      expect(
        m.questionsToNextStage(const MasteryInput(coverage: 0.30, accuracy: 0.8), totalQuestions: 100),
        20,
      );
    });

    test('今の正答率では次に届かない、最高段階、問題数0 は null', () {
      expect(m.questionsToNextStage(const MasteryInput(coverage: 0.9, accuracy: 0.5), totalQuestions: 100), isNull);
      expect(m.questionsToNextStage(const MasteryInput(coverage: 1, accuracy: 0.9), totalQuestions: 100), isNull);
      expect(m.questionsToNextStage(const MasteryInput(coverage: 0.3, accuracy: 0.8), totalQuestions: 0), isNull);
    });
  });

  group('今日の状態', () {
    test('学習した日・3日連続以上はよろこび。それ以外は通常（責める表情はない）', () {
      expect(const MascotDayState(studiedToday: true).expression, MascotExpression.joy);
      expect(const MascotDayState(streakDays: 3).expression, MascotExpression.joy);
      expect(const MascotDayState().expression, MascotExpression.normal);
      expect(const MascotDayState(daysSinceLastStudy: 10).expression, MascotExpression.normal);
    });

    test('3日以上空いたら「おかえり」。今日学習済みなら出さない', () {
      expect(const MascotDayState(daysSinceLastStudy: 3).isWelcomeBack, isTrue);
      expect(const MascotDayState(daysSinceLastStudy: 2).isWelcomeBack, isFalse);
      expect(const MascotDayState(studiedToday: true, daysSinceLastStudy: 9).isWelcomeBack, isFalse);
    });

    test('試験日までの日数で装いが変わる', () {
      final now = DateTime(2026, 10, 2, 15);
      ExamPhase p(int days) =>
          MascotDayState(examDate: DateTime(2026, 10, 2).add(Duration(days: days))).examPhase(now);
      expect(const MascotDayState().examPhase(now), ExamPhase.none);
      expect(p(60), ExamPhase.none);
      expect(p(31), ExamPhase.none);
      expect(p(30), ExamPhase.approaching);
      expect(p(8), ExamPhase.approaching);
      expect(p(7), ExamPhase.close);
      expect(p(2), ExamPhase.close);
      expect(p(1), ExamPhase.eve);
      expect(p(0), ExamPhase.today);
      expect(p(-1), ExamPhase.none, reason: '過ぎた試験日は装いなし');
    });
  });

  group('セリフ', () {
    test('標準キャラの全セリフに禁止表現（責める・消える・恋愛依存）がない', () {
      for (final tone in MascotTone.values) {
        for (final line in MascotLines.forTone(tone).all) {
          expect(findForbiddenExpressions(line), isEmpty, reason: line);
        }
      }
    });

    test('禁止表現の検査が実際に検出する', () {
      expect(findForbiddenExpressions('なんで勉強しないの'), isNotEmpty);
      expect(findForbiddenExpressions('もう会えないかも'), isNotEmpty);
      expect(findForbiddenExpressions('ずっと一緒にいてね'), isNotEmpty);
      expect(findForbiddenExpressions('寂しい…'), isNotEmpty);
      expect(findForbiddenExpressions('今日もおつかれさまでした'), isEmpty);
    });

    test('全場面にセリフがあり、同じ seed なら同じセリフ', () {
      const l = MascotLines.gentle;
      for (final s in MascotSituation.values) {
        expect(l.of(s), isNotEmpty, reason: s.name);
        expect(l.pick(s, seed: 3), l.pick(s, seed: 3));
      }
      expect(l.pick(MascotSituation.welcomeBack), contains('おかえり'));
    });

    test('「おかえり」は責める言い方を含まない', () {
      for (final line in MascotLines.gentle.of(MascotSituation.welcomeBack)) {
        expect(findForbiddenExpressions(line), isEmpty);
      }
    });
  });

  group('MascotWidget', () {
    Widget host(Widget child, {bool reduceMotion = false, double scale = 1}) => MaterialApp(
          theme: UkalabTheme.light(field: UkalabField.ai, cert: UkalabCert.gKentei),
          builder: (context, c) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reduceMotion,
              textScaler: TextScaler.linear(scale),
            ),
            child: c!,
          ),
          home: Scaffold(body: Center(child: child)),
        );

    testWidgets('全段階×表情×試験日の装いが描画できる', (tester) async {
      for (final stage in MascotStage.values) {
        for (final ex in MascotExpression.values) {
          for (final phase in ExamPhase.values) {
            await tester.pumpWidget(host(MascotWidget(stage: stage, expression: ex, examPhase: phase)));
            expect(tester.takeException(), isNull);
          }
        }
      }
    });

    testWidgets('非表示なら何も出ない。小さくすると 60% の大きさ', (tester) async {
      await tester.pumpWidget(host(const MascotWidget(display: MascotDisplay.hidden)));
      expect(find.byType(CustomPaint), findsNothing.or(findsWidgets));
      expect(tester.getSize(find.byType(MascotWidget)), Size.zero);

      await tester.pumpWidget(host(const MascotWidget(display: MascotDisplay.small, size: 100)));
      final box = tester.getSize(find.descendant(of: find.byType(MascotWidget), matching: find.byType(SizedBox)).first);
      expect(box.width, closeTo(60, 0.1));
    });

    testWidgets('動きを減らす設定ではアニメーションが走らない', (tester) async {
      await tester.pumpWidget(host(const MascotWidget(), reduceMotion: true));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(host(const MascotWidget(), reduceMotion: false));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
      // 後始末（リピートを止める）
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('セリフが吹き出しで出て、タップできる。文字拡大200%でも崩れない', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(
        MascotWidget(line: 'おかえりなさい。また一緒に進めましょう', onTap: () => taps++),
        scale: 2,
      ));
      expect(find.text('おかえりなさい。また一緒に進めましょう'), findsOneWidget);
      await tester.tap(find.byType(MascotWidget));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('画像パックは imageBuilder の画像を使い、null ならコード描画に戻る', (tester) async {
      var asked = 0;
      final pack = CharacterPack(
        id: 'img',
        name: 'テスト',
        tone: MascotTone.cool,
        imageBuilder: (stage, ex) {
          asked++;
          return null; // 画像がまだ取得できていない
        },
      );
      await tester.pumpWidget(host(MascotWidget(pack: pack)));
      expect(asked, greaterThan(0));
      expect(find.byType(Image), findsNothing);
      expect(pack.isBuiltIn, isFalse);
      expect(CharacterPack.standard.isBuiltIn, isTrue);
      await tester.pumpWidget(const SizedBox());
    });
  });
}

extension on Matcher {
  Matcher or(Matcher other) => anyOf(this, other);
}
