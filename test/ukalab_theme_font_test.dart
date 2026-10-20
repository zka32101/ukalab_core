import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

void main() {
  test('テーマの文字は同梱の日本語フォントを使う', () {
    for (final b in [UkalabTheme.light, UkalabTheme.dark]) {
      final t = b(field: UkalabField.tech);
      expect(t.textTheme.bodyMedium?.fontFamily, UkalabTheme.fontFamily);
      expect(t.textTheme.titleLarge?.fontFamily, UkalabTheme.fontFamily);
    }
  });
}
