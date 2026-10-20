import 'dart:typed_data';

/// Web 以外では使わない（`save_file.dart` が kIsWeb で分岐する）。
Future<bool> downloadBytesInBrowser({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async => false;
