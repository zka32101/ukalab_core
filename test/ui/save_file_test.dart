import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

void main() {
  test('historyCsvFileName: ukalab_history_YYYYMMDD.csv（0埋め）', () {
    expect(historyCsvFileName(DateTime(2026, 1, 5)), 'ukalab_history_20260105.csv');
    expect(historyCsvFileName(DateTime(2026, 10, 20, 23, 59)), 'ukalab_history_20261020.csv');
  });

  test('encodeTextFile: BOM は withBom のときだけ付く', () {
    expect(encodeTextFile('a'), [0x61]);
    expect(encodeTextFile('a', withBom: true), [0xEF, 0xBB, 0xBF, 0x61]);
    expect(utf8.decode(encodeTextFile('日付', withBom: true).sublist(3)), '日付');
  });

  test('shareCsv: text/csv・BOM付きUTF-8で saver に渡す', () async {
    Uint8List? gotBytes;
    String? gotName;
    String? gotMime;
    final ok = await shareCsv(
      csv: '日付,解答数\n',
      fileName: 'ukalab_history_20261020.csv',
      saver:
          ({
            required Uint8List bytes,
            required String fileName,
            required String mimeType,
            Rect? sharePositionOrigin,
          }) async {
            gotBytes = bytes;
            gotName = fileName;
            gotMime = mimeType;
            return true;
          },
    );
    expect(ok, isTrue);
    expect(gotName, 'ukalab_history_20261020.csv');
    expect(gotMime, 'text/csv');
    expect(gotBytes!.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    expect(utf8.decode(gotBytes!.sublist(3)), '日付,解答数\n');
  });

  test('saveTextFile: saver が false（共有シートを閉じた）ならそのまま返す', () async {
    final ok = await saveTextFile(
      text: 'x',
      fileName: 'a.txt',
      saver:
          ({
            required Uint8List bytes,
            required String fileName,
            required String mimeType,
            Rect? sharePositionOrigin,
          }) async => false,
    );
    expect(ok, isFalse);
  });
}
