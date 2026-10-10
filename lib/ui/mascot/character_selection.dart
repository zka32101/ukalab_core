import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mascot_models.dart';
import 'ukalab_characters.dart';

/// 選んだ推し（端末内）。キーはうかラボ共通なので、同じ端末の別アプリでも同じ推しになる。
/// （アプリごとにサンドボックスが別なら共有されない。その場合も各アプリ内では保存される）
class CharacterSelectionNotifier extends StateNotifier<CharacterPack> {
  CharacterSelectionNotifier() : super(CharacterPack.standard) {
    _load();
  }

  static const prefsKey = 'ukalab.mascot.selected';

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      state = UkalabCharacters.byId(p.getString(prefsKey));
    } catch (_) {
      // 読めなければ標準キャラのまま。
    }
  }

  Future<void> select(CharacterPack pack) async {
    state = pack;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(prefsKey, pack.id);
    } catch (_) {}
  }
}

/// 現在の推し。標準キャラ（うか）が既定。
final selectedCharacterPackProvider =
    StateNotifierProvider<CharacterSelectionNotifier, CharacterPack>((ref) => CharacterSelectionNotifier());

/// 推しを選ぶ画面。無料で全員選べる。
class CharacterSelectScreen extends ConsumerWidget {
  const CharacterSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCharacterPackProvider);
    final theme = Theme.of(context);
    final strings = KitStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.oshiChoose)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final p in UkalabCharacters.all)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: selected.id == p.id ? theme.colorScheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                leading: _Face(pack: p),
                title: Text(strings.characterNames[p.id] ?? p.name),
                subtitle: Text(strings.characterRoles[p.id] ?? ''),
                trailing: selected.id == p.id ? const Icon(Icons.check_circle) : null,
                onTap: () => ref.read(selectedCharacterPackProvider.notifier).select(p),
              ),
            ),
        ],
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.pack});

  final CharacterPack pack;

  @override
  Widget build(BuildContext context) {
    final icon = UkalabCharacters.icon(pack);
    return CircleAvatar(
      radius: 24,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      // 標準キャラ（画像なし）のアイコンが、アプリのテーマによっては背景と同色で見えなくなるため、
      // 前景色を明示する（バイク免許で一行目のアイコンが空白になっていた）。
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      backgroundImage: icon,
      child: icon == null ? const Icon(Icons.science_outlined) : null,
    );
  }
}
