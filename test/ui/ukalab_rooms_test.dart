import 'dart:io';

import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('部屋の画像が7種すべて、横長・縦長とも存在する', () {
    for (final r in UkalabRoom.values) {
      expect(
        File('assets/mascot/rooms/${UkalabRooms.file(r)}.webp').existsSync(),
        true,
        reason: r.name,
      );
      expect(
        File(
          'assets/mascot/rooms/${UkalabRooms.file(r, portrait: true)}.webp',
        ).existsSync(),
        true,
        reason: 'v ${r.name}',
      );
    }
    expect(UkalabRoom.values.length, 7);
  });

  test('小物の画像が12種すべて存在する', () {
    expect(UkalabProp.values.length, 12);
    for (final p in UkalabProp.values) {
      expect(
        File('assets/mascot/props/${UkalabProps.file(p)}.webp').existsSync(),
        true,
        reason: p.name,
      );
    }
  });

  test('資格から部屋が決まる（全資格で割り当てがある）', () {
    expect(UkalabRooms.forCert(UkalabCert.gKentei), UkalabRoom.ai);
    expect(UkalabRooms.forCert(UkalabCert.genAiPassport), UkalabRoom.ai);
    expect(UkalabRooms.forCert(UkalabCert.boki3), UkalabRoom.accounting);
    expect(UkalabRooms.forCert(UkalabCert.hazmat4), UkalabRoom.safety);
    expect(UkalabRooms.forCert(UkalabCert.kanjiKentei), UkalabRoom.language);
    expect(UkalabRooms.forCert(UkalabCert.bikeLicense), UkalabRoom.transport);
    expect(UkalabRooms.forCert(UkalabCert.itPassport), UkalabRoom.it);
    for (final c in UkalabCert.values) {
      expect(
        UkalabRoom.values.contains(UkalabRooms.forCert(c)),
        true,
        reason: c.id,
      );
    }
  });

  testWidgets('UkalabOshiRoom は部屋の背景と推しを重ねて出す（標準キャラ・縦長でも崩れない）', (tester) async {
    for (final portrait in [false, true]) {
      for (final pack in [CharacterPack.standard, UkalabCharacters.mio]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 336,
                child: UkalabOshiRoom.forCert(
                  cert: UkalabCert.boki3,
                  pack: pack,
                  scene: MascotScene.guidePoint,
                  portrait: portrait,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(MascotWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
