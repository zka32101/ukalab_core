import 'package:app_common_kit/app_common_kit.dart';
import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester t, KitStrings strings) async {
  SharedPreferences.setMockInitialValues({});
  await t.pumpWidget(ProviderScope(
    child: MaterialApp(
      home: KitStringsScope(
        strings: strings,
        child: const CharacterSelectScreen(),
      ),
    ),
  ));
  await t.pump();
}

void main() {
  testWidgets('英語では名前・役割・タイトルが英語になる', (t) async {
    await _pump(t, KitStrings.en);
    expect(find.text('Choose companion'), findsOneWidget);
    expect(find.text('Kai'), findsOneWidget);
    expect(find.text('Reliable senior'), findsOneWidget);
    expect(find.text('カイ'), findsNothing);
  });

  testWidgets('日本語では従来どおり', (t) async {
    await _pump(t, KitStrings.ja);
    expect(find.text('推しを選ぶ'), findsOneWidget);
    expect(find.text('カイ'), findsOneWidget);
    expect(find.text('頼れる先輩'), findsOneWidget);
  });
}
