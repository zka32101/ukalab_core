import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

Widget _wrap(Widget child, {double width = 800, double scale = 1.0, bool reduce = false}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduce,
        ),
        child: Scaffold(
          body: SingleChildScrollView(child: SizedBox(width: width, child: child)),
        ),
      ),
    );

const _p = OshiGrowthProgress(totalAnswered: 120, studyDays: 12);

void main() {
  testWidgets('bubble: 表情・ラベル・一言を出し、タップで別の一言', (t) async {
    OshiGrowthReaction? last;
    await t.pumpWidget(_wrap(OshiGrowthBubble(
      progress: _p,
      strings: OshiGrowthStrings.ja,
      seed: 0,
      onChanged: (r) => last = r,
    )));
    final stage = OshiGrowthStrings.ja.stageText(OshiGrowthStage.growing);
    expect(find.text('${stage.emoji} ${stage.label}'), findsOneWidget);
    expect(find.text(stage.messages[0]), findsOneWidget);
    await t.tap(find.byType(OshiGrowthBubble));
    await t.pumpAndSettle();
    expect(find.text(stage.messages[1]), findsOneWidget);
    expect(last!.text, stage.messages[1]);
  });

  testWidgets('bubble: セマンティクスにヒントと本文、最小タップ領域 48', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(_wrap(const OshiGrowthBubble(progress: _p, strings: OshiGrowthStrings.ja, seed: 0)));
    final node = t.getSemantics(find.byType(OshiGrowthBubble));
    expect(node.hint, OshiGrowthStrings.ja.tapHint);
    expect(node.label, contains('すくすく'));
    expect(t.getSize(find.byType(OshiGrowthBubble)).height, greaterThanOrEqualTo(48));
    h.dispose();
  });

  testWidgets('bubble: 言語は KitStrings に従う（en）', (t) async {
    await t.pumpWidget(MaterialApp(
      home: KitStringsScope(
        strings: KitStrings.en,
        child: const Scaffold(body: OshiGrowthBubble(progress: OshiGrowthProgress(), seed: 0)),
      ),
    ));
    expect(find.textContaining('First steps'), findsOneWidget);
  });

  testWidgets('bubble: avatar を渡すと絵文字の代わりに出る', (t) async {
    await t.pumpWidget(_wrap(const OshiGrowthBubble(
      progress: _p,
      strings: OshiGrowthStrings.ja,
      avatar: SizedBox(key: ValueKey('av'), width: 40, height: 40),
    )));
    expect(find.byKey(const ValueKey('av')), findsOneWidget);
    expect(find.text('🌟'), findsNothing);
  });

  for (final reduce in [false, true]) {
    testWidgets('celebration card: 本文と絵文字（reduce=$reduce）', (t) async {
      final c = const OshiGrowthEngine().celebrate(const OshiGrowthMilestone.answered(100));
      await t.pumpWidget(_wrap(OshiGrowthCelebrationCard(celebration: c), reduce: reduce));
      await t.pumpAndSettle();
      expect(find.text(c.title), findsOneWidget);
      expect(find.text(c.body), findsOneWidget);
      expect(find.text(c.emoji), findsOneWidget);
    });
  }

  testWidgets('dialog: 閉じるボタンだけで閉じられる', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (ctx) => TextButton(
          onPressed: () => showOshiGrowthDialog(
            ctx,
            milestone: const OshiGrowthMilestone.days(7),
            strings: OshiGrowthStrings.ja,
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('学習した日が7日に'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    await t.tap(find.text('とじる'));
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  group('幅320・文字2倍でオーバーフローしない', () {
    for (final s in [OshiGrowthStrings.ja, OshiGrowthStrings.en]) {
      for (final stage in OshiGrowthStage.values) {
        testWidgets('bubble ${s == OshiGrowthStrings.ja ? 'ja' : 'en'} ${stage.name}', (t) async {
          final progress = switch (stage) {
            OshiGrowthStage.newcomer => const OshiGrowthProgress(),
            OshiGrowthStage.budding => const OshiGrowthProgress(totalAnswered: 10),
            OshiGrowthStage.growing => const OshiGrowthProgress(totalAnswered: 100),
            OshiGrowthStage.blooming => const OshiGrowthProgress(totalAnswered: 300),
            OshiGrowthStage.radiant => const OshiGrowthProgress(totalAnswered: 1000),
          };
          for (var salt = 0; salt < 3; salt++) {
            await t.pumpWidget(_wrap(
              OshiGrowthBubble(key: ValueKey('$salt'), progress: progress, strings: s, seed: salt),
              width: 320,
              scale: 2.0,
            ));
            await t.pumpAndSettle();
            expect(t.takeException(), isNull);
          }
        });
      }
      testWidgets('celebration ${s == OshiGrowthStrings.ja ? 'ja' : 'en'} 全節目', (t) async {
        final e = OshiGrowthEngine(strings: s);
        for (final m in OshiGrowthEngine.defaultMilestones) {
          await t.pumpWidget(_wrap(
            OshiGrowthCelebrationCard(key: ValueKey(m.id), celebration: e.celebrate(m)),
            width: 320,
            scale: 2.0,
          ));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
        }
      });
    }

    testWidgets('dialog 幅320・文字2倍・縦が短くてもスクロールで収まる', (t) async {
      t.view.physicalSize = const Size(320, 480);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        builder: (c, w) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: const TextScaler.linear(2.0)),
          child: w!,
        ),
        home: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => showOshiGrowthDialog(
              ctx,
              milestone: const OshiGrowthMilestone.answered(1000),
              strings: OshiGrowthStrings.ja,
            ),
            child: const Text('open'),
          ),
        ),
      ));
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text('とじる'), findsOneWidget);
    });
  });
}
