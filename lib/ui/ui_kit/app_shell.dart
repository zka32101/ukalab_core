import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';


/// 下部タブの骨格。全アプリ共通で「ホーム／学ぶ／模擬／記録／設定」の5つ。
class UkalabShell extends StatefulWidget {
  const UkalabShell({
    super.key,
    required this.pages,
    this.initialIndex = 0,
    this.labels,
  })  : assert(pages.length == 5, '下部タブは5つに統一'),
        assert(labels == null || labels.length == 5, 'ラベルも5つ');

  /// ホーム・学ぶ・模擬・記録・設定の順。
  final List<Widget> pages;
  final int initialIndex;
  /// null なら [KitStrings] の既定（日本語なら [defaultLabels]）。
  final List<String>? labels;

  static const defaultLabels = ['ホーム', '学ぶ', '模擬', '記録', '設定'];
  static const _icons = [
    Icons.home_outlined,
    Icons.menu_book_outlined,
    Icons.timer_outlined,
    Icons.insights_outlined,
    Icons.settings_outlined,
  ];
  static const _selectedIcons = [
    Icons.home,
    Icons.menu_book,
    Icons.timer,
    Icons.insights,
    Icons.settings,
  ];

  @override
  State<UkalabShell> createState() => _UkalabShellState();
}

class _UkalabShellState extends State<UkalabShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels ?? KitStrings.of(context).tabLabels;
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: widget.pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (var i = 0; i < 5; i++)
            NavigationDestination(
              icon: Icon(UkalabShell._icons[i]),
              selectedIcon: Icon(UkalabShell._selectedIcons[i]),
              label: labels[i],
            ),
        ],
      ),
    );
  }
}
