import 'dart:convert';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import 'file_download_stub.dart'
    if (dart.library.js_interop) 'file_download_web.dart';

/// バイト列をファイルとして渡す処理。テストでは差し替える。
/// 渡せたら true、ユーザーが共有シートを閉じたなら false。失敗は例外。
typedef FileSaver =
    Future<bool> Function({
      required Uint8List bytes,
      required String fileName,
      required String mimeType,
      Rect? sharePositionOrigin,
    });

/// Excel が UTF-8 と判定できるようにする BOM。
const String utf8Bom = '﻿';

/// `ukalab_history_YYYYMMDD.csv`（学習履歴の書き出し用）。
String historyCsvFileName(DateTime now) {
  String two(int v) => v.toString().padLeft(2, '0');
  return 'ukalab_history_${now.year.toString().padLeft(4, '0')}'
      '${two(now.month)}${two(now.day)}.csv';
}

/// [text] を UTF-8 のバイト列にする。[withBom] なら先頭に BOM を付ける。
Uint8List encodeTextFile(String text, {bool withBom = false}) =>
    Uint8List.fromList(utf8.encode(withBom ? '$utf8Bom$text' : text));

/// 既定の [FileSaver]。Web はブラウザのダウンロード、それ以外は共有シート（share_plus）。
Future<bool> defaultFileSaver({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  Rect? sharePositionOrigin,
}) async {
  if (kIsWeb) {
    return downloadBytesInBrowser(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }
  final result = await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: mimeType, name: fileName)],
      fileNameOverrides: [fileName],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
  return result.status != ShareResultStatus.dismissed;
}

/// テキストをファイルとして保存（共有）する。[saver] を省くと [defaultFileSaver]。
Future<bool> saveTextFile({
  required String text,
  required String fileName,
  String mimeType = 'text/plain',
  bool withBom = false,
  FileSaver? saver,
  Rect? sharePositionOrigin,
}) => (saver ?? defaultFileSaver)(
  bytes: encodeTextFile(text, withBom: withBom),
  fileName: fileName,
  mimeType: mimeType,
  sharePositionOrigin: sharePositionOrigin,
);

/// CSV を UTF-8 BOM 付き・`text/csv` で保存（共有）する。
Future<bool> shareCsv({
  required String csv,
  required String fileName,
  FileSaver? saver,
  Rect? sharePositionOrigin,
}) => saveTextFile(
  text: csv,
  fileName: fileName,
  mimeType: 'text/csv',
  withBom: true,
  saver: saver,
  sharePositionOrigin: sharePositionOrigin,
);
