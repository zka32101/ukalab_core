import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 資格専用キャラ7体の画像(A 13枚 + C 小物 2〜3枚)が、pubspec.yaml に登録され、アセットとして
/// 読み込めることを確認する。登録漏れ(ファイルはあるのに読めない)・名前の食い違いを検出する。
///
/// 小物(C)は、コードから参照されないため、ここで一覧を固定する。増減したらこの表も直す。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const items = <String, List<String>>{
    'circa': ['chip', 'cable', 'laptop'],
    'noda': ['node', 'book'],
    'sheru': ['key', 'lantern'],
    'hirari': ['brush', 'spark'],
    'soro': ['abacus', 'ledger'],
    'sala': ['flask', 'gloves'],
    'tatsu': ['brush', 'inkstone'],
  };

  List<String> aNames(String id) => [
    '${id}_icon_256',
    for (var lv = 1; lv <= 5; lv++) ...[
      '${id}_lv${lv}_normal',
      '${id}_lv${lv}_joy',
    ],
    '${id}_special_pass',
    '${id}_special_bow',
  ];

  Future<void> expectLoads(String path, String reason) async {
    final data = await rootBundle.load('packages/ukalab_core/$path');
    expect(data.lengthInBytes, greaterThan(0), reason: reason);
  }

  test('A 画像13枚が、アセットとして読み込める(7体)', () async {
    for (final id in items.keys) {
      final names = aNames(id);
      expect(names.length, 13, reason: id);
      for (final n in names) {
        await expectLoads('assets/mascot/$id/$n.webp', '$id $n');
      }
    }
  });

  test('C 小物が、アセットとして読み込める(7体)', () async {
    for (final e in items.entries) {
      for (final n in e.value) {
        await expectLoads(
          'assets/mascot/${e.key}/items/${e.key}_$n.webp',
          '${e.key} $n',
        );
      }
    }
  });

  test('B 画像(scenes/states/guide/poses)と衣装(outfits)のフォルダは作らない', () {
    for (final id in items.keys) {
      for (final d in ['scenes', 'states', 'guide', 'poses', 'outfits']) {
        expect(
          Directory('assets/mascot/$id/$d').existsSync(),
          false,
          reason: '$id/$d',
        );
      }
    }
  });
}
