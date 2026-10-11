import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// バックアップ・リセットの対象になる学習データ1つ分（進捗・解答履歴・メモなど）。
///
/// 各アプリは自分の保存先ごとに [DataPart] を作って並べるだけでよい。
/// テーマ・試験日・ブックマークなど「設定・自分の整理物」は対象に含めない。
class DataPart {
  const DataPart({
    required this.id,
    required this.export,
    required this.restore,
    required this.reset,
  });

  /// バックアップ内のキー（英数字とアンダースコア）。保存済みのバックアップと
  /// 互換を保つため、いったん決めたら変えない。
  final String id;

  /// 現在の内容を JSON にできる値で返す。端末内の保存先を非同期で読むなら
  /// [Future] を返してもよい（その場合は [encodeLearningDataBackupAsync] を使う）。
  final FutureOr<Object?> Function(WidgetRef ref) export;

  /// バックアップの内容で上書きする。
  final Future<void> Function(WidgetRef ref, Object? json) restore;

  /// 初期状態に戻す。
  final Future<void> Function(WidgetRef ref) reset;
}

/// バックアップ形式のバージョン。
const learningDataBackupFormatVersion = 1;

/// [parts] の現在の内容を、バックアップのJSON文字列にする。
///
/// すべての部品の [DataPart.export] が同期のときだけ使える。[Future] を返す部品が
/// あれば [StateError]（その場合は [encodeLearningDataBackupAsync]）。
String encodeLearningDataBackup(WidgetRef ref, List<DataPart> parts, {DateTime? now}) {
  final values = <String, Object?>{};
  for (final p in parts) {
    final v = p.export(ref);
    if (v is Future) {
      throw StateError('部品「${p.id}」は非同期です。encodeLearningDataBackupAsync を使ってください');
    }
    values[p.id] = v;
  }
  return _encode(values, now);
}

/// [encodeLearningDataBackup] の非同期版。[Future] を返す部品も扱える。
Future<String> encodeLearningDataBackupAsync(WidgetRef ref, List<DataPart> parts, {DateTime? now}) async {
  final values = <String, Object?>{};
  for (final p in parts) {
    values[p.id] = await p.export(ref);
  }
  return _encode(values, now);
}

String _encode(Map<String, Object?> parts, DateTime? now) {
  final body = <String, Object?>{
    'version': learningDataBackupFormatVersion,
    'exportedAt': (now ?? DateTime.now()).toIso8601String(),
    'parts': parts,
  };
  return const JsonEncoder.withIndent('  ').convert(body);
}

/// バックアップのJSON文字列を [parts] へ書き戻す。形式が不正・未対応なら
/// [FormatException]。`parts` を持たない旧形式（項目がトップレベルに並ぶ形）も読める。バックアップに無い部品は触らない（後から部品を足した
/// アプリでも、古いバックアップを読み込める）。
Future<void> restoreLearningDataBackup(WidgetRef ref, List<DataPart> parts, String text) async {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    throw const FormatException('バックアップの形式が正しくありません');
  }
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('バックアップの形式が正しくありません');
  }
  final version = decoded['version'];
  if (version != learningDataBackupFormatVersion) {
    throw FormatException('未対応のバックアップ形式です（version: $version）');
  }
  // 共通化前のアプリのバックアップは、`parts` を使わず項目がトップレベルに並ぶ。
  // その形式（`parts` が無い）も、項目をそのまま部品のidとして読む。
  final saved = decoded.containsKey('parts')
      ? decoded['parts']
      : (Map<String, dynamic>.of(decoded)
        ..remove('version')
        ..remove('exportedAt'));
  if (saved is! Map<String, dynamic>) {
    throw const FormatException('バックアップの形式が正しくありません');
  }
  for (final p in parts) {
    if (saved.containsKey(p.id)) {
      await p.restore(ref, saved[p.id]);
    }
  }
}

/// [parts] をすべて初期状態に戻す。
Future<void> resetLearningData(WidgetRef ref, List<DataPart> parts) async {
  for (final p in parts) {
    await p.reset(ref);
  }
}

/// 設定画面の「データの管理」（書き出す・読み込む・リセット）。
class DataManagementSection extends ConsumerWidget {
  const DataManagementSection({
    super.key,
    required this.parts,
    this.description = '学習記録は、書き出し・読み込み・リセットができます。'
        'テーマや試験日などの設定は対象外です。',
  });

  final List<DataPart> parts;
  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('データの管理', style: theme.textTheme.titleSmall),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
          child: Text(description, style: const TextStyle(fontSize: 12, height: 1.6)),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.ios_share_outlined),
                label: const Text('書き出す'),
                onPressed: () => _export(context, ref),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.download_outlined),
                label: const Text('読み込む'),
                onPressed: () => _import(context, ref),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
          icon: const Icon(Icons.delete_outline),
          label: const Text('学習記録をリセット'),
          onPressed: () => _reset(context, ref),
        ),
      ],
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    await Clipboard.setData(ClipboardData(text: await encodeLearningDataBackupAsync(ref, parts)));
    if (!context.mounted) return;
    _snack(context, '学習記録をクリップボードにコピーしました');
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _ImportDialog(),
    );
    if (text == null || text.trim().isEmpty) return;
    try {
      await restoreLearningDataBackup(ref, parts, text);
      if (!context.mounted) return;
      _snack(context, '学習記録を読み込みました');
    } catch (_) {
      if (!context.mounted) return;
      _snack(context, '読み込みに失敗しました。正しいバックアップのテキストか確認してください');
    }
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('学習記録をリセットしますか？'),
        content: const Text('解答数・正答率・メモ等の学習記録が削除され、元に戻せません。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('リセットする', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await resetLearningData(ref, parts);
    if (!context.mounted) return;
    _snack(context, '学習記録をリセットしました');
  }
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog();

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('学習記録を読み込む'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '書き出した学習記録のテキストを貼り付けてください。現在の学習記録は上書きされます。',
            style: TextStyle(fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 6,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '{ "version": 1, ... }'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('キャンセル')),
        FilledButton(onPressed: () => Navigator.of(context).pop(_controller.text), child: const Text('読み込む')),
      ],
    );
  }
}
