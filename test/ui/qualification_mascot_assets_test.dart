import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

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
        for (var lv = 1; lv <= 5; lv++) ...['${id}_lv${lv}_normal', '${id}_lv${lv}_joy'],
        '${id}_special_pass',
        '${id}_special_bow',
      ];

  Future<void> expectLoads(String path, String reason) async {
    final data = await rootBundle.load('packages/ukalab_core/$path');
    expect(data.lengthInBytes, greaterThan(0), reason: reason);
  }

  test('小物の一覧が、資格専用キャラ7体と一致する', () {
    expect(items.keys.toList(), UkalabCharacters.qualificationPacks.map((p) => p.id).toList());
  });

  test('A 画像13枚が、アセットとして読み込める(7体)', () async {
    for (final p in UkalabCharacters.qualificationPacks) {
      final names = aNames(p.id);
      expect(names.length, 13, reason: p.id);
      for (final n in names) {
        await expectLoads('assets/mascot/${p.id}/$n.webp', '${p.id} $n');
      }
    }
  });

  test('C 小物が、アセットとして読み込める(7体)', () async {
    for (final e in items.entries) {
      for (final n in e.value) {
        await expectLoads('assets/mascot/${e.key}/items/${e.key}_$n.webp', '${e.key} $n');
      }
    }
  });

  test('コードが指す画像(icon・Lv・特別ポーズ)が、実在するファイルを指す', () {
    for (final p in UkalabCharacters.qualificationPacks) {
      final icon = UkalabCharacters.icon(p)! as AssetImage;
      expect(File(icon.assetName).existsSync(), true, reason: '${p.id} icon');
      for (final s in MascotStage.values) {
        for (final e in MascotExpression.values) {
          final img = p.imageBuilder!(s, e)! as AssetImage;
          expect(File(img.assetName).existsSync(), true, reason: '${p.id} ${img.assetName}');
        }
      }
      for (final i in [UkalabCharacters.specialPassImage(p.id)!, UkalabCharacters.specialBowImage(p.id)!]) {
        final img = i as AssetImage;
        expect(File(img.assetName).existsSync(), true, reason: '${p.id} ${img.assetName}');
      }
    }
  });

  test('B 画像(scenes/states/guide/poses)と衣装(outfits)のフォルダは作らない', () {
    for (final p in UkalabCharacters.qualificationPacks) {
      for (final d in ['scenes', 'states', 'guide', 'poses', 'outfits']) {
        expect(Directory('assets/mascot/${p.id}/$d').existsSync(), false, reason: '${p.id}/$d');
      }
    }
  });
}
