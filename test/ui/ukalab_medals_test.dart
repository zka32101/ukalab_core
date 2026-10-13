import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

void main() {
  test('全17資格の合格メダル画像が存在し、AssetImage を返す', () {
    expect(UkalabMedals.certIds.length, UkalabCert.values.length);
    for (final c in UkalabCert.values) {
      final path = UkalabMedals.assetPath(c.id)!;
      expect(File(path).existsSync(), true, reason: path);
      final img = UkalabMedals.image(c.id);
      expect(img, isA<AssetImage>());
      expect((img! as AssetImage).package, 'ukalab_core');
    }
  });

  test('未知の資格は null（コード描画のメダルに戻る）', () {
    expect(UkalabMedals.image('unknown'), isNull);
    expect(UkalabMedals.assetPath('unknown'), isNull);
  });

  test('OshiMedal.image に渡せる', () {
    final m = OshiMedal(id: 'pass_g', label: 'G検定', image: UkalabMedals.image('g_kentei'));
    expect(m.image, isNotNull);
  });

  test('特別ポーズ（合格・おじぎ）の画像が4体ぶん存在する', () {
    for (final p in UkalabCharacters.imagePacks) {
      for (final k in ['pass', 'bow']) {
        expect(File('assets/mascot/${p.id}/${p.id}_special_$k.webp').existsSync(), true);
      }
      expect(UkalabCharacters.specialPassImage(p.id), isNotNull);
      expect(UkalabCharacters.specialBowImage(p.id), isNotNull);
    }
    expect(UkalabCharacters.specialBowImage(CharacterPack.standard.id), isNull);
  });
}
