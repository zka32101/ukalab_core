import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

Widget _host(Widget child, {Brightness b = Brightness.light, double scale = 1}) => MaterialApp(
  theme: ThemeData(brightness: b),
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Scaffold(body: SingleChildScrollView(child: Center(child: SizedBox(width: 320, child: child)))),
  ),
);

const _data = AchievementShareData(
  certLabel: 'ITパスポート',
  headline: '分野を100%制覇',
  metricText: '12/40問',
  dateLabel: '2026年10月24日',
);

Text _t(WidgetTester t, String key) => t.widget<Text>(find.byKey(ValueKey(key)));

void main() {
  testWidgets('表示内容と 4:5 のサイズ', (tester) async {
    await tester.pumpWidget(_host(const AchievementShareCard(data: _data, cert: UkalabCert.itPassport)));
    expect(find.text('ITパスポート'), findsOneWidget);
    expect(find.text('分野を100%制覇'), findsOneWidget);
    expect(find.text('12/40問'), findsOneWidget);
    expect(find.text('2026年10月24日'), findsOneWidget);
    final size = tester.getSize(find.byType(AspectRatio));
    expect(size.width / size.height, closeTo(4 / 5, 0.001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('任意項目なしでも出る・Semantics ラベル', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const AchievementShareCard(
        data: AchievementShareData(certLabel: '簿記3級', headline: '連続学習'),
        cert: UkalabCert.boki3,
      )),
    );
    expect(find.byKey(const ValueKey('achievementMetric')), findsNothing);
    expect(find.byKey(const ValueKey('achievementDate')), findsNothing);
    expect(find.bySemanticsLabel('簿記3級、連続学習'), findsOneWidget);
    handle.dispose();
  });

  for (final scale in [1.0, 2.0]) {
    for (final b in Brightness.values) {
      testWidgets('長文でも例外なし（倍率$scale・${b.name}）', (tester) async {
        final long = 'あ' * 120;
        await tester.pumpWidget(_host(
          AchievementShareCard(
            data: AchievementShareData(certLabel: long, headline: long, metricText: long, dateLabel: long),
            cert: UkalabCert.genAiPractitioner,
          ),
          b: b,
          scale: scale,
        ));
        expect(tester.takeException(), isNull);
        // 文字倍率は固定（画像が崩れない）
        final ctx = tester.element(find.byKey(const ValueKey('achievementHeadline')));
        expect(MediaQuery.textScalerOf(ctx), TextScaler.noScaling);
        expect(_t(tester, 'achievementHeadline').overflow, TextOverflow.ellipsis);
        expect(_t(tester, 'achievementCert').maxLines, 2);
      });
    }
  }

  for (final cert in UkalabCert.values) {
    for (final b in Brightness.values) {
      testWidgets('コントラスト 4.5 以上: ${cert.id} ${b.name}', (tester) async {
        await tester.pumpWidget(_host(AchievementShareCard(data: _data, cert: cert), b: b));
        final box = tester.widget<Container>(find.byKey(const ValueKey('achievementCardSurface')));
        final surface = (box.decoration! as BoxDecoration).color!;
        for (final k in ['achievementHeadline', 'achievementMetric', 'achievementDate', 'achievementBrand']) {
          expect(contrastRatio(_t(tester, k).style!.color!, surface), greaterThanOrEqualTo(4.5), reason: k);
        }
        final chip = tester.widget<Container>(
          find.ancestor(of: find.byKey(const ValueKey('achievementCert')), matching: find.byType(Container)).first,
        );
        final chipBg = (chip.decoration! as BoxDecoration).color!;
        expect(contrastRatio(_t(tester, 'achievementCert').style!.color!, chipBg), greaterThanOrEqualTo(4.5));
      });
    }
  }

  test('AchievementShareData は個人情報の欄を持たない（引数を 4 つに固定）', () {
    // 欄を足すとこのテストが壊れる。足すなら個人情報でないことを確認して更新する。
    const d = AchievementShareData(certLabel: 'a', headline: 'b', metricText: 'c', dateLabel: 'd');
    expect([d.certLabel, d.headline, d.metricText, d.dateLabel], ['a', 'b', 'c', 'd']);
    // userName / userId / email 等の引数は存在しない（const コンストラクタの引数が固定されている）。
  });

  testWidgets('shareAchievementCard は PNG を saver に渡す', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(_host(
      RepaintBoundary(key: key, child: const AchievementShareCard(data: _data, cert: UkalabCert.fe)),
    ));
    Uint8List? got;
    String? name;
    String? mime;
    final ok = await tester.runAsync(
      () => shareAchievementCard(
        key,
        pixelRatio: 1,
        saver: ({required bytes, required fileName, required mimeType, sharePositionOrigin}) async {
          got = bytes;
          name = fileName;
          mime = mimeType;
          return true;
        },
      ),
    );
    expect(ok, isTrue);
    expect(name, 'ukalab_achievement.png');
    expect(mime, 'image/png');
    // PNG シグネチャ
    expect(got!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  });
}
