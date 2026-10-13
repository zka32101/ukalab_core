import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

const _medal = OshiMedal(id: 'm1', label: '7日連続', tier: 2, kind: OshiMedalKind.streak);

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

Positioned _pos(WidgetTester t) => t.widget<Positioned>(find.byKey(const ValueKey('oshiMedalPositioned')));

void main() {
  group('OshiMedalShareCard', () {
    testWidgets('既定は右下。マスコットと同じ Stack にメダルが重なる', (tester) async {
      await tester.pumpWidget(_host(OshiMedalShareCard(medal: _medal, date: DateTime(2026, 10, 13))));
      final stack = find.byKey(const ValueKey('oshiMedalStack'));
      expect(find.descendant(of: stack, matching: find.byType(MascotWidget)), findsOneWidget);
      expect(find.descendant(of: stack, matching: find.byType(OshiMedalView)), findsOneWidget);
      final p = _pos(tester);
      expect(p.right, 0);
      expect(p.bottom, 0);
      expect(p.left, isNull);
      expect(p.top, isNull);
      expect(tester.widget<MascotWidget>(find.byType(MascotWidget)).animate, isFalse);
    });

    testWidgets('位置の enum で隅が変わる', (tester) async {
      final expected = {
        OshiMedalCorner.topLeft: (true, true),
        OshiMedalCorner.topRight: (false, true),
        OshiMedalCorner.bottomLeft: (true, false),
        OshiMedalCorner.bottomRight: (false, false),
      };
      for (final e in expected.entries) {
        await tester.pumpWidget(_host(OshiMedalShareCard(medal: _medal, date: DateTime(2026, 10, 13), corner: e.key)));
        final p = _pos(tester);
        final (left, top) = e.value;
        expect(p.left != null, left, reason: e.key.name);
        expect(p.right != null, !left, reason: e.key.name);
        expect(p.top != null, top, reason: e.key.name);
        expect(p.bottom != null, !top, reason: e.key.name);
      }
    });

    testWidgets('画像が無ければコード描画、あれば Image', (tester) async {
      await tester.pumpWidget(_host(OshiMedalShareCard(medal: _medal, date: DateTime(2026, 10, 13))));
      expect(find.descendant(of: find.byType(OshiMedalView), matching: find.byType(CustomPaint)), findsWidgets);
      expect(find.descendant(of: find.byType(OshiMedalView), matching: find.byType(Image)), findsNothing);

      final bytes = Uint8List.fromList(const [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82,
      ]);
      final withImage = OshiMedal(id: 'm2', label: '画像', image: MemoryImage(bytes));
      await tester.pumpWidget(_host(OshiMedalShareCard(medal: withImage, date: DateTime(2026, 10, 13))));
      expect(find.descendant(of: find.byType(OshiMedalView), matching: find.byType(Image)), findsOneWidget);
    });

    testWidgets('日付・うかラボ・自己記録の注記だけで、個人情報の欄が無い', (tester) async {
      await tester.pumpWidget(_host(OshiMedalShareCard(medal: _medal, date: DateTime(2026, 10, 13))));
      expect(find.text('うかラボ'), findsOneWidget);
      expect(find.text('自己記録・非公式'), findsOneWidget);
      expect(find.text('2026年10月13日'), findsOneWidget);
      expect(find.text('7日連続'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('showOshiMedalDialog', () {
    Future<void> open(WidgetTester tester,
        {Future<void> Function(Uint8List)? onShare, Future<void> Function(Uint8List)? onSave}) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showOshiMedalDialog(
                context,
                medal: _medal,
                now: DateTime(2026, 10, 13),
                onShare: onShare,
                onSave: onSave,
              ),
              child: const Text('開く'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('開く'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('個人情報が入らない旨の文言が出る。コールバックが null のボタンは出ない', (tester) async {
      await open(tester);
      expect(find.textContaining('個人情報は入りません'), findsOneWidget);
      expect(find.text('共有する'), findsNothing);
      expect(find.text('画像を保存'), findsNothing);
      expect(find.text('閉じる'), findsOneWidget);
    });

    testWidgets('共有・保存ボタンは PNG を渡す', (tester) async {
      Uint8List? shared;
      Uint8List? saved;
      await open(tester, onShare: (p) async => shared = p, onSave: (p) async => saved = p);
      expect(find.text('共有する'), findsOneWidget);
      expect(find.text('画像を保存'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('共有する'));
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();
        await tester.tap(find.text('画像を保存'));
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();
      });
      expect(shared, isNotNull);
      expect(shared!.sublist(1, 4), [0x50, 0x4E, 0x47]);
      expect(saved, isNotNull);
    });

    testWidgets('保存だけ渡したときは保存ボタンだけ出る', (tester) async {
      await open(tester, onSave: (_) async {});
      expect(find.text('画像を保存'), findsOneWidget);
      expect(find.text('共有する'), findsNothing);
    });
  });

  test('メダルの文言は全言語にあり、禁止表現を含まない', () {
    for (final s in [UkalabStrings.ja, UkalabStrings.en, UkalabStrings.zhHans, UkalabStrings.zhHant, UkalabStrings.ko]) {
      for (final t in [s.medalTitle, s.medalNote, s.medalDisclaimer, s.medalSave]) {
        expect(t.trim(), isNotEmpty);
        expect(findForbiddenExpressions(t), isEmpty, reason: t);
      }
    }
  });
}
