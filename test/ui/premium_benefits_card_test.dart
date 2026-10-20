import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('PremiumBenefitsStrings', () {
    final all = {
      'ja': PremiumBenefitsStrings.ja,
      'en': PremiumBenefitsStrings.en,
      'zhHans': PremiumBenefitsStrings.zhHans,
      'zhHant': PremiumBenefitsStrings.zhHant,
      'ko': PremiumBenefitsStrings.ko,
    };

    for (final e in all.entries) {
      test('${e.key}: PremiumFeature をすべて持ち、空文字がない', () {
        expect(e.value.benefits.keys.toSet(), PremiumFeature.values.toSet());
        for (final t in e.value.allTexts) {
          expect(t.trim(), isNotEmpty);
        }
      });
    }

    test('価格・通貨を含まない', () {
      for (final s in all.values) {
        final text = s.allTexts.join('\n');
        expect(text, isNot(contains('円')));
        expect(text, isNot(contains('¥')));
        expect(text, isNot(contains(r'$')));
      }
    });

    test('forLanguageCode: 未知の言語は日本語', () {
      expect(PremiumBenefitsStrings.forLanguageCode('xx'), PremiumBenefitsStrings.ja);
      expect(PremiumBenefitsStrings.forLanguageCode('en'), PremiumBenefitsStrings.en);
    });
  });

  group('PremiumBenefitsCard', () {
    testWidgets('全機能の名前と説明を並べ、無料の範囲も添える', (tester) async {
      await tester.pumpWidget(_app(const PremiumBenefitsCard()));
      final ja = PremiumBenefitsStrings.ja;
      expect(find.text(ja.title), findsOneWidget);
      for (final f in PremiumFeature.values) {
        expect(find.byKey(ValueKey('premiumBenefit_${f.name}')), findsOneWidget);
        expect(find.text(ja.benefits[f]!.name), findsOneWidget);
        expect(find.text(ja.benefits[f]!.description), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('premiumFreeNote')), findsOneWidget);
    });

    testWidgets('features で絞り込み、showFreeNote=false で一文を出さない', (tester) async {
      await tester.pumpWidget(
        _app(
          const PremiumBenefitsCard(
            features: [PremiumFeature.historyExport],
            showFreeNote: false,
            strings: PremiumBenefitsStrings.en,
          ),
        ),
      );
      expect(find.text('Export study history'), findsOneWidget);
      expect(find.byKey(const ValueKey('premiumBenefit_weakDrill')), findsNothing);
      expect(find.byKey(const ValueKey('premiumFreeNote')), findsNothing);
    });
  });
}
