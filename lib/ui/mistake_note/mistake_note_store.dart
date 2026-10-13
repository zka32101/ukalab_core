import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../progress/mistake_note_engine.dart';
import '../data_management/data_management.dart';

/// 間違いノートの保存先（`BookmarkStore` と同じ流儀）。
/// 保存するのは問題ID・日時・原因コード・分野ID・回数のみ（問題文・個人情報は保存しない）。
abstract class MistakeNoteStore {
  Future<List<MistakeNoteEntry>> read();
  Future<void> write(List<MistakeNoteEntry> entries);
}

/// テスト・プレビュー用のインメモリ実装。
class InMemoryMistakeNoteStore implements MistakeNoteStore {
  List<MistakeNoteEntry> _entries = [];

  @override
  Future<List<MistakeNoteEntry>> read() async => List.unmodifiable(_entries);

  @override
  Future<void> write(List<MistakeNoteEntry> entries) async => _entries = [...entries];
}

/// 保存値を復元する。null・壊れた値・不正な要素は無視する（壊れていれば空）。
List<MistakeNoteEntry> decodeMistakeNotes(String? raw) {
  if (raw == null) return const [];
  try {
    final list = jsonDecode(raw) as List;
    return list.map(MistakeNoteEntry.fromJson).whereType<MistakeNoteEntry>().toList();
  } catch (_) {
    return const [];
  }
}

String encodeMistakeNotes(List<MistakeNoteEntry> entries) =>
    jsonEncode([for (final e in entries) e.toJson()]);

/// 端末内（SharedPreferences）への保存。キーは `ukalab_<アプリID>_mistake_notes`。
class SharedPreferencesMistakeNoteStore implements MistakeNoteStore {
  SharedPreferencesMistakeNoteStore(this.appId);

  final String appId;

  String get _key => 'ukalab_${appId}_mistake_notes';

  @override
  Future<List<MistakeNoteEntry>> read() async {
    final p = await SharedPreferences.getInstance();
    return decodeMistakeNotes(p.getString(_key));
  }

  @override
  Future<void> write(List<MistakeNoteEntry> entries) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, encodeMistakeNotes(entries));
  }
}

/// 間違いノートをバックアップ・リセットの対象にする部品（キーは `mistakeNotes`）。
/// 画面が開いたままでも反映できるよう、[onChanged] で再読み込みなどを呼べる。
DataPart mistakeNoteDataPart(MistakeNoteStore store, {void Function()? onChanged}) => DataPart(
      id: 'mistakeNotes',
      export: (ref) async => [for (final e in await store.read()) e.toJson()],
      restore: (ref, json) async {
        final entries = json is List
            ? json.map(MistakeNoteEntry.fromJson).whereType<MistakeNoteEntry>().toList()
            : <MistakeNoteEntry>[];
        await store.write(entries);
        onChanged?.call();
      },
      reset: (ref) async {
        await store.write(const []);
        onChanged?.call();
      },
    );
