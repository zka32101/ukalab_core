import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

Widget _wrap(Widget child,
        {double width = 800,
        double scale = 1.0,
        bool reduce = false,
        ThemeData? theme}) =>
    MaterialApp(
      theme: theme,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduce,
        ),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

List<HomeMenuItem> _items(int n) => [
      for (var i = 0; i < n; i++)
        HomeMenuItem(icon: Icons.star, title: 'item$i', onTap: () {})
    ];

void main() {
  testWidgets('header is a semantics header', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(_wrap(const HomeSectionHeader(title: '記録', subtitle: 'sub')));
    expect(
        t.getSemantics(find.text('記録')),
        matchesSemantics(isHeader: true, label: '記録\nsub'));
    h.dispose();
  });

  testWidgets('tile tap, badges, min height', (t) async {
    var taps = 0;
    await t.pumpWidget(_wrap(Column(children: [
      HomeMenuTile(
          icon: Icons.home,
          title: 'a',
          badge: HomeMenuBadge.count(120),
          onTap: () => taps++),
      HomeMenuTile(icon: Icons.home, title: 'b', badge: const HomeMenuBadge.label('NEW'), onTap: () {}),
      HomeMenuTile(icon: Icons.home, title: 'c', badge: const HomeMenuBadge.premium(), onTap: () {}),
      HomeMenuTile(icon: Icons.home, title: 'd', badge: const HomeMenuBadge.dot(), onTap: () {}),
      HomeMenuTile(icon: Icons.home, title: 'e', badge: HomeMenuBadge.count(0), onTap: () {}),
    ])));
    expect(find.text('99+'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-badge-premium')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-badge-dot')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-badge-count')), findsOneWidget);
    expect(t.getSize(find.byType(HomeMenuTile).first).height, greaterThanOrEqualTo(48));
    await t.tap(find.text('a'));
    expect(taps, 1);
  });

  testWidgets('grid: 2 columns on wide, 1 on narrow / large text', (t) async {
    await t.pumpWidget(_wrap(HomeMenuGrid(items: _items(3))));
    expect(find.byKey(const ValueKey('home-grid-2')), findsOneWidget);
    await t.pumpWidget(_wrap(HomeMenuGrid(items: _items(3)), width: 300));
    expect(find.byKey(const ValueKey('home-grid-1')), findsOneWidget);
    await t.pumpWidget(_wrap(HomeMenuGrid(items: _items(3)), scale: 2.0));
    expect(find.byKey(const ValueKey('home-grid-1')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('section collapse / initial state / notifier', (t) async {
    final n = ValueNotifier<bool>(false);
    bool? last;
    await t.pumpWidget(_wrap(HomeSection(
      title: 'T',
      collapsible: true,
      expandedListenable: n,
      onExpandedChanged: (v) => last = v,
      child: const Text('body'),
    )));
    expect(find.text('body'), findsNothing);
    await t.tap(find.text('T'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('body'), findsOneWidget);
    expect(n.value, isTrue);
    expect(last, isTrue);
    n.value = false;
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('body'), findsNothing);
  });

  testWidgets('section default expanded; non-collapsible always shows', (t) async {
    await t.pumpWidget(_wrap(const HomeSection(
        title: 'T', collapsible: true, child: Text('body'))));
    expect(find.text('body'), findsOneWidget);
    await t.pumpWidget(_wrap(const HomeSection(
        title: 'T', initiallyExpanded: false, child: Text('body2'))));
    expect(find.text('body2'), findsOneWidget);
  });

  testWidgets('reduce motion: collapses immediately', (t) async {
    await t.pumpWidget(_wrap(
        const HomeSection(title: 'T', collapsible: true, child: Text('body')),
        reduce: true));
    await t.tap(find.text('T'));
    await t.pump();
    expect(find.text('body'), findsNothing);
  });

  testWidgets('renders in dark theme', (t) async {
    await t.pumpWidget(_wrap(
        Column(children: [
          const HomeSectionHeader(title: 'h', leading: Text('🎯')),
          HomeMenuTile(icon: Icons.home, title: 'x', subtitle: 's', onTap: () {}),
          HomeMenuGrid(items: _items(2)),
        ]),
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark))));
    expect(find.text('x'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
