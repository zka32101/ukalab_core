import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

void main() {
  final builtIn = {
    'ja': UkalabStrings.ja,
    'en': UkalabStrings.en,
    'zh': UkalabStrings.zhHans,
    'zh-Hant': UkalabStrings.zhHant,
    'ko': UkalabStrings.ko,
  };

  group('forLanguageCode', () {
    test('内蔵の言語を選ぶ。無い言語は日本語', () {
      for (final e in builtIn.entries) {
        expect(UkalabStrings.forLanguageCode(e.key), same(e.value));
      }
      expect(UkalabStrings.forLanguageCode('fr'), same(UkalabStrings.ja));
    });

    testWidgets('of は KitStringsScope の言語に従う', (tester) async {
      Widget probe(KitStrings k) => MaterialApp(
            home: KitStringsScope(
              strings: k,
              child: Builder(builder: (c) => Text(UkalabStrings.of(c).oshiChoose)),
            ),
          );
      await tester.pumpWidget(probe(KitStrings.ko));
      expect(find.text(UkalabStrings.ko.oshiChoose), findsOneWidget);
      await tester.pumpWidget(probe(KitStrings.zhHant));
      expect(find.text(UkalabStrings.zhHant.oshiChoose), findsOneWidget);
      await tester.pumpWidget(probe(KitStrings.ja));
      expect(find.text(UkalabStrings.ja.oshiChoose), findsOneWidget);
    });
  });

  test('copyWith は指定した項目だけ変える', () {
    final k = UkalabStrings.en.copyWith(coinTotal: '合计');
    expect(k.coinTotal, '合计');
    expect(k.coinBreakdownTitle, UkalabStrings.en.coinBreakdownTitle);
    expect(k.coinBalance(3), UkalabStrings.en.coinBalance(3));
    expect(UkalabStrings.en.coinTotal, isNot('合计'));
  });

  group('内蔵の言語はそろっている', () {
    for (final e in builtIn.entries) {
      final s = e.value;

      test('${e.key}: 文言が空でない', () {
        final texts = <String>[
          s.coinTotal, s.coinBreakdownTitle, s.passAskBody, s.passNotYet, s.passNotPassed, s.passPassed,
          s.passEncourageTitle, s.passEncourageBody, s.passCongrats, s.passPrivacy, s.passShare,
          s.wardrobeTitle, s.wardrobeNote, s.wardrobeInsufficient, s.wardrobeAlreadyOwned, s.wardrobeUnknown,
          s.wardrobeCannotWear, s.wardrobeWear, s.wardrobeWearing, s.wardrobeCanWear,
          s.lockedNotPassed, s.lockedNoExamDate, s.lockedNotReady,
          s.oshiMenuTooltip, s.oshiChoose, s.oshiPassReport, s.oshiDisplayNormal, s.oshiDisplaySmall,
          s.oshiDisplayHidden, s.oshiName, s.oshiHiddenNote, s.oshiYours, s.oshiTapHint,
          s.mockRecordTitle, s.mockRecordNote, s.mockRecordMessage, s.shareCardBrand, s.shareCardPassed,
          ...s.tabLabels,
        ];
        for (final t in texts) {
          expect(t.trim(), isNotEmpty);
        }
      });

      test('${e.key}: コインの種類と推しの役割が、日本語と同じキーを全部持つ', () {
        expect(s.coinEventLabels.keys.toSet(), UkalabStrings.ja.coinEventLabels.keys.toSet());
        expect(s.characterRoles.keys.toSet(), UkalabStrings.ja.characterRoles.keys.toSet());
        expect(s.tabLabels.length, 5);
        for (final v in [...s.coinEventLabels.values, ...s.characterRoles.values]) {
          expect(v.trim(), isNotEmpty);
        }
      });

      test('${e.key}: 値を埋め込む文言に、値が入る', () {
        expect(s.coinBalance(120), contains('120'));
        expect(s.wardrobePurchased('帽子'), contains('帽子'));
        expect(s.wardrobePrice(300), contains('300'));
        expect(s.lockedNotPurchased(300), contains('300'));
        expect(s.passAskTitle('G検定'), contains('G検定'));
        expect(s.passCoin(50), contains('50'));
        expect(s.passOutfit('帽子'), contains('帽子'));
        expect(s.mockRecordCert('G検定'), contains('G検定'));
        final d = s.shareDate(DateTime(2026, 10, 9));
        expect(d, allOf(contains('2026'), contains('9')));
      });
    }

    test('日本語の文字が、他の言語の文言に混ざっていない（かな）', () {
      // 中黒(U+30FB)と長音(U+30FC)は中国語・韓国語でも使うので除く。
      final kana = RegExp(r'[぀-ゟ゠-ヺヽ-ヿ]');
      for (final e in builtIn.entries.where((e) => e.key != 'ja')) {
        final s = e.value;
        final all = <String>[
          s.passEncourageBody, s.wardrobeNote, s.oshiTapHint, s.mockRecordNote,
          ...s.coinEventLabels.values, ...s.characterRoles.values, ...s.tabLabels,
          s.shareDate(DateTime(2026, 10, 9)),
        ];
        for (final t in all) {
          expect(kana.hasMatch(t), isFalse, reason: '${e.key}: 「$t」にかなが混ざっている');
        }
      }
    });
  });
}
