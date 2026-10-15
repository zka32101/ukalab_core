import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

/// WebP のヘッダを読む（寸法・透過・メタデータの有無を、画像ライブラリなしで確かめる）。
class _WebpInfo {
  _WebpInfo(this.width, this.height, this.hasAlpha, this.chunks);
  final int width;
  final int height;
  final bool hasAlpha;
  final List<String> chunks;
}

_WebpInfo _readWebp(File f) {
  final b = f.readAsBytesSync();
  final d = ByteData.sublistView(b);
  expect(String.fromCharCodes(b.sublist(0, 4)), 'RIFF', reason: f.path);
  expect(String.fromCharCodes(b.sublist(8, 12)), 'WEBP', reason: f.path);
  final chunks = <String>[];
  var i = 12;
  while (i + 8 <= b.length) {
    final tag = String.fromCharCodes(b.sublist(i, i + 4));
    final n = d.getUint32(i + 4, Endian.little);
    chunks.add(tag);
    i += 8 + n + (n & 1);
  }
  expect(chunks.first, 'VP8X', reason: '${f.path}: 透過つきの拡張形式');
  final flags = b[20];
  final w = 1 + (b[24] | b[25] << 8 | b[26] << 16);
  final h = 1 + (b[27] | b[28] << 8 | b[29] << 16);
  return _WebpInfo(w, h, flags & 0x10 != 0, chunks);
}

void main() {
  final files = [
    for (final p in UkalabCertProp.values) File('assets/mascot/props/${UkalabProps.certFile(p)}.webp'),
  ];

  test('資格別の小物: 12種すべての画像が存在し、名前が部屋の小物と重ならない', () {
    expect(UkalabCertProp.values.length, 12);
    for (final f in files) {
      expect(f.existsSync(), true, reason: f.path);
    }
    final generic = {for (final p in UkalabProp.values) UkalabProps.file(p)};
    final cert = {for (final p in UkalabCertProp.values) UkalabProps.certFile(p)};
    expect(cert.length, 12);
    expect(generic.intersection(cert), isEmpty);
  });

  test('資格別の小物: 896×896・背景透過で、メタデータ（EXIF・XMP・ICC）を含まない', () {
    for (final f in files) {
      final info = _readWebp(f);
      expect(info.width, 896, reason: f.path);
      expect(info.height, 896, reason: f.path);
      expect(info.hasAlpha, true, reason: f.path);
      expect(info.chunks.toSet().intersection({'EXIF', 'XMP ', 'ICCP'}), isEmpty, reason: f.path);
    }
  });

  test('資格別の小物: 1枚あたりの容量が大きすぎない（アプリ容量の予算）', () {
    for (final f in files) {
      expect(f.lengthSync(), lessThan(100 * 1024), reason: f.path);
    }
  });

  test('小物の画像は全4体の既存規格と同じ置き場所（assets/mascot/props/）にある', () {
    for (final p in UkalabCertProp.values) {
      expect(UkalabProps.certFile(p), startsWith('prop_'));
      expect(UkalabProps.certImage(p), isA<AssetImage>());
    }
  });
}
