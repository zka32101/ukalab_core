import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('分野を渡すだけでライト・ダークの ThemeData ができる', () {
    for (final f in UkalabField.values) {
      final l = UkalabTheme.light(field: f);
      final d = UkalabTheme.dark(field: f);
      expect(l.brightness, Brightness.light);
      expect(d.brightness, Brightness.dark);
      expect(l.scaffoldBackgroundColor, const Color(0xFFF6F8FB));
      expect(d.scaffoldBackgroundColor, const Color(0xFF121A24));
    }
  });

  test('資格を渡すと primary がその色になる', () {
    final t = UkalabTheme.light(field: UkalabField.ai, cert: UkalabCert.genAiPassport);
    expect(t.colorScheme.primary, UkalabCert.genAiPassport.light);
    expect(t.colorScheme.onPrimary, Colors.white);
    final dt = UkalabTheme.dark(field: UkalabField.ai, cert: UkalabCert.genAiPassport);
    expect(dt.colorScheme.primary, UkalabCert.genAiPassport.dark);
    expect(dt.colorScheme.onPrimary, UkalabPalette.onFillDark);
  });

  test('文字サイズは仕様どおり（本文16／解説17・行間1.6／注釈13）', () {
    final t = UkalabTheme.light(field: UkalabField.it).textTheme;
    expect(t.bodyMedium!.fontSize, 16);
    expect(t.bodyLarge!.fontSize, 17);
    expect(t.bodyLarge!.height, 1.6);
    expect(t.bodySmall!.fontSize, 13);
    // 13 未満は使わない
    for (final s in [t.bodySmall, t.labelMedium, t.labelSmall, t.bodyMedium, t.titleSmall]) {
      expect(s!.fontSize, greaterThanOrEqualTo(13));
    }
  });

  testWidgets('ボタンのタップ領域は 44pt 以上、文字拡大 200% でも崩れない', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: UkalabTheme.light(field: UkalabField.ai, cert: UkalabCert.gKentei),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: Column(children: [
                FilledButton(onPressed: () {}, child: const Text('答える')),
                const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('解説の文章です。'))),
              ]),
            ),
          ),
        ),
      ),
    );
    final size = tester.getSize(find.byType(FilledButton));
    expect(size.height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });
}
