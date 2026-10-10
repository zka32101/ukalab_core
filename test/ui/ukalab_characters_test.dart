import 'dart:io';

import 'package:ukalab_core/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('画像4体のLv・表情の画像ファイルがすべて存在する', () {
    for (final p in UkalabCharacters.imagePacks) {
      expect(p.isBuiltIn, false);
      expect(File('assets/mascot/${p.id}/${p.id}_icon_256.webp').existsSync(), true);
      for (final s in MascotStage.values) {
        for (final e in MascotExpression.values) {
          final img = p.imageBuilder!(s, e);
          expect(img, isNotNull);
          final name = 'assets/mascot/${p.id}/${p.id}_lv${s.level}_${e == MascotExpression.joy ? 'joy' : 'normal'}.webp';
          expect(File(name).existsSync(), true, reason: name);
        }
      }
    }
  });


  test('場面別ポーズ: 全キャラ×全Lv×前日・おかえり・連続、および案内役の画像がある', () {
    for (final p in UkalabCharacters.imagePacks) {
      for (final sc in MascotScene.values) {
        final dir = sc.isGuide ? 'guide' : 'scenes';
        // 前日・おかえり・連続は Lv1〜5 の全段階に画像がある。案内役は Lv1 の絵を全段階で返す
        for (final s in MascotStage.values) {
          final f = UkalabCharacters.sceneFile(p.id, sc, s);
          expect(File('assets/mascot/${p.id}/$dir/$f.webp').existsSync(), true, reason: f);
          expect(p.sceneImageBuilder!(sc, s), isNotNull, reason: '$f');
        }
      }
    }
    expect(CharacterPack.standard.sceneImageBuilder, isNull);
  });

  test('衣装画像: 3資格×種別の画像が全キャラにあり、ない資格はnull', () {
    for (final p in UkalabCharacters.imagePacks) {
      for (final o in OutfitCatalog.all) {
        final f = UkalabCharacters.outfitFile(o, MascotStage.lv1);
        if (UkalabCharacters.costumedCerts.contains(o.cert.id)) {
          expect(f, isNotNull, reason: o.id);
          expect(File('assets/mascot/${p.id}/outfits/$f.webp').existsSync(), true, reason: '${p.id} $f');
          expect(p.outfitImageBuilder!(o, MascotStage.lv1), isNotNull);
        } else {
          expect(f, isNull, reason: o.id);
          expect(p.outfitImageBuilder!(o, MascotStage.lv1), isNull);
        }
      }
    }
    final bikeRegular = OutfitCatalog.byId(OutfitCatalog.idOf(UkalabCert.bikeLicense, OutfitKind.regular))!;
    expect(UkalabCharacters.outfitFile(bikeRegular, MascotStage.lv5), 'bike_license_lv5');
    expect(File('assets/mascot/kai/outfits/bike_license_lv5.webp').existsSync(), true);
  });

  test('標準キャラは画像なし、byIdは不明IDで標準に戻る', () {
    expect(CharacterPack.standard.isBuiltIn, true);
    expect(UkalabCharacters.byId('mio').id, 'mio');
    expect(UkalabCharacters.byId('zzz').id, 'standard');
    expect(UkalabCharacters.byId(null).id, 'standard');
    expect(UkalabCharacters.all.length, 5);
  });

  test('選んだ推しは共通キーで保存され、次回読み込まれる', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(selectedCharacterPackProvider).id, 'standard');
    await c.read(selectedCharacterPackProvider.notifier).select(UkalabCharacters.moka);
    expect((await SharedPreferences.getInstance()).getString('ukalab.mascot.selected'), 'moka');

    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    c2.read(selectedCharacterPackProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c2.read(selectedCharacterPackProvider).id, 'moka');
  });
}
