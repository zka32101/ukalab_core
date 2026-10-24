import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

List<PremiumGatedStoryItem> _items([int n = 4]) => [
      for (var i = 1; i <= n; i++)
        PremiumGatedStoryItem(
          id: 's$i',
          title: 'シナリオ$i',
          chapterCount: 5,
          footer: Wrap(children: [ActionChip(label: Text('用語$i'), onPressed: () {})]),
        ),
    ];

Widget _app(Widget list, {double scale = 1}) => MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: list),
    );

void main() {
  testWidgets('先頭N本は無料、残りはロックアイコン', (tester) async {
    await tester.pumpWidget(_app(PremiumGatedStoryListView(
      items: _items(),
      hasPremium: false,
      onOpen: (_) {},
      chapterUnit: '場面',
    )));
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
    expect(find.text('全5場面 ・ 無料'), findsNWidgets(2));
    expect(find.text('全5場面 ・ プレミアム'), findsNWidgets(2));
  });

  testWidgets('isFree(id) は freeCount より優先する', (tester) async {
    await tester.pumpWidget(_app(PremiumGatedStoryListView(
      items: _items(),
      hasPremium: false,
      onOpen: (_) {},
      isFree: (id) => id == 's4',
    )));
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(3));
  });

  testWidgets('hasPremium=true なら全開放(ロックなし)でどれも開ける', (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(_app(PremiumGatedStoryListView(
      items: _items(),
      hasPremium: true,
      onOpen: (i) => opened.add(i.id),
    )));
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    await tester.tap(find.text('シナリオ4'));
    expect(opened, ['s4']);
  });

  testWidgets('無料タップは onOpen、ロックタップは既定の SnackBar で onOpen しない', (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(_app(PremiumGatedStoryListView(
      items: _items(),
      hasPremium: false,
      onOpen: (i) => opened.add(i.id),
    )));
    await tester.tap(find.text('シナリオ1'));
    expect(opened, ['s1']);
    await tester.tap(find.text('シナリオ3'));
    await tester.pump();
    expect(opened, ['s1']);
    expect(find.text(PremiumGatedStoryListView.defaultLockedMessage), findsOneWidget);
  });

  testWidgets('ロックタップで onLockedTap が呼ばれ、SnackBar は出ない', (tester) async {
    final locked = <String>[];
    await tester.pumpWidget(_app(PremiumGatedStoryListView(
      items: _items(),
      hasPremium: false,
      onOpen: (_) {},
      onLockedTap: (i) => locked.add(i.id),
    )));
    await tester.tap(find.text('シナリオ3'));
    await tester.pump();
    expect(locked, ['s3']);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('AI下書きの注記・説明・末尾スロットを表示する', (tester) async {
    await tester.pumpWidget(_app(PremiumGatedStoryListView(
      items: _items(2),
      hasPremium: false,
      onOpen: (_) {},
      intro: '説明文です',
      draftNotice: '学習用の架空シナリオ(AI下書き・専門確認前)',
    )));
    expect(find.text('説明文です'), findsOneWidget);
    expect(find.text('学習用の架空シナリオ(AI下書き・専門確認前)'), findsOneWidget);
    expect(find.text('用語1'), findsOneWidget);
    expect(find.text('用語2'), findsOneWidget);
  });

  testWidgets('draftNotice 省略時は注記なし', (tester) async {
    await tester.pumpWidget(_app(PremiumGatedStoryListView(
      items: _items(2),
      hasPremium: false,
      onOpen: (_) {},
    )));
    expect(find.textContaining('AI下書き'), findsNothing);
  });

  testWidgets('広告ウィジェットを含まない', (tester) async {
    await tester.pumpWidget(_app(PremiumGatedStoryListView(
      items: _items(),
      hasPremium: false,
      onOpen: (_) {},
    )));
    final adLike = RegExp(r'(^|[a-z])(Ad|Ads)([A-Z]|$)|BannerAd|NativeAd|Interstitial|Rewarded');
    final names = tester.allWidgets.map((w) => w.runtimeType.toString());
    expect(names.where((n) => adLike.hasMatch(n)), isEmpty);
    expect(File('lib/ui/ui_kit/premium_gated_story_list.dart').readAsStringSync(),
        isNot(contains('google_mobile_ads')));
  });

  testWidgets('文字倍率2.0・狭い幅でも overflow しない', (tester) async {
    tester.view.physicalSize = const Size(320 * 2, 640 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(
      PremiumGatedStoryListView(
        items: [
          for (var i = 1; i <= 4; i++)
            PremiumGatedStoryItem(
              id: 's$i',
              title: '会社のIT担当1年目 とても長いタイトルのシナリオその$i',
              chapterCount: 12,
              footer: Wrap(spacing: 8, children: [
                for (final t in ['ネットワーク', 'セキュリティ', 'クラウド'])
                  ActionChip(label: Text(t), onPressed: () {}),
              ]),
            ),
        ],
        hasPremium: false,
        onOpen: (_) {},
        intro: '架空の会社のIT担当になって、月ごとの出来事にどう判断するかを選びます。',
        draftNotice: '学習用の架空シナリオ(AI下書き・専門確認前)',
        chapterUnit: 'か月',
      ),
      scale: 2.0,
    ));
    expect(tester.takeException(), isNull);
  });
}
