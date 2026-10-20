import 'package:flutter/material.dart';

import '../../progress/mastery_streak.dart';
import 'mastery_store.dart';

/// 「正解済みの問題を出さない」設定の文言。`UkalabStrings` とは別にして既存アプリを壊さない。
class MasterySettingsStrings {
  const MasterySettingsStrings({
    this.toggleTitle = '正解済みの問題を出さない',
    this.toggleSubtitle = '同じ問題に2回続けて正解したら、「解く」の通常出題とペース走で出さなくなります',
    this.countTemplate = '除外中の問題: {n}問',
    this.restoreButton = '除外した問題を戻す（全件）',
    this.confirmTitle = '除外した問題を戻しますか？',
    this.confirmBody = 'すべての問題がまた出題されるようになります。',
    this.confirmOk = '戻す',
    this.confirmCancel = 'やめる',
    this.restoredMessage = '除外した問題を戻しました',
    this.allMasteredMessage = 'すべて習得済み。設定で戻せます',
  });

  final String toggleTitle;
  final String toggleSubtitle;

  /// `{n}` が件数に置き換わる。
  final String countTemplate;
  final String restoreButton;
  final String confirmTitle;
  final String confirmBody;
  final String confirmOk;
  final String confirmCancel;
  final String restoredMessage;

  /// 出題プールが全件除外のときの案内（アプリが出題画面で使う）。
  final String allMasteredMessage;

  String countText(int n) => countTemplate.replaceAll('{n}', '$n');
}

/// アプリが settings に差し込む「正解済みの問題を出さない」設定。
/// ON/OFF の切替・除外件数の表示・「除外した問題を戻す（全件）」ボタンを持つ。
/// 変更後は [onChanged] に（ON/OFF, 現在の状態）を渡すので、アプリは出題側の状態を更新する。
class MasterySettingsTile extends StatefulWidget {
  const MasterySettingsTile({
    super.key,
    required this.store,
    this.strings = const MasterySettingsStrings(),
    this.onChanged,
  });

  final MasteryStore store;
  final MasterySettingsStrings strings;
  final void Function(bool enabled, MasteryStreak streak)? onChanged;

  @override
  State<MasterySettingsTile> createState() => _MasterySettingsTileState();
}

class _MasterySettingsTileState extends State<MasterySettingsTile> {
  bool _enabled = false;
  MasteryStreak _streak = MasteryStreak.empty;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await widget.store.readEnabled();
    final streak = await widget.store.read();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _streak = streak;
      _loaded = true;
    });
  }

  Future<void> _toggle(bool v) async {
    await widget.store.writeEnabled(v);
    if (!mounted) return;
    setState(() => _enabled = v);
    widget.onChanged?.call(v, _streak);
  }

  Future<void> _restore() async {
    final s = widget.strings;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.confirmTitle),
        content: Text(s.confirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.confirmCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.confirmOk)),
        ],
      ),
    );
    if (ok != true) return;
    final next = _streak.restoreAll();
    await widget.store.write(next);
    if (!mounted) return;
    setState(() => _streak = next);
    widget.onChanged?.call(_enabled, next);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(s.restoredMessage)));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          title: Text(s.toggleTitle),
          subtitle: Text(s.toggleSubtitle),
          value: _enabled,
          onChanged: _loaded ? _toggle : null,
        ),
        ListTile(
          title: Text(s.countText(_streak.excludedCount)),
          trailing: OutlinedButton(
            onPressed: _loaded && _streak.excludedCount > 0 ? _restore : null,
            child: Text(s.restoreButton),
          ),
        ),
      ],
    );
  }
}
