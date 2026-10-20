import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Blob を作ってアンカーの download 属性で保存する（Web）。
Future<bool> downloadBytesInBrowser({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  try {
    final a = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = fileName
      ..style.display = 'none';
    web.document.body?.append(a);
    a.click();
    a.remove();
  } finally {
    web.URL.revokeObjectURL(url);
  }
  return true;
}
