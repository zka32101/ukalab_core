import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/answer_feedback.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ui/reading/reading_number_wrap.dart';
import 'package:ukalab_core/ukalab_core.dart';

Widget _app(Widget child, {double scale = 1}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

Future<void> _settle(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 1));

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// 連結文字を除いた文字列が [raw] と一致する Text。
Finder _textOf(String raw) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? '').replaceAll(kReadingWordJoiner, '') == raw,
);

RenderParagraph _paragraph(WidgetTester tester, Finder text) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: text, matching: find.byType(RichText)).first,
    );

/// 各行の開始位置（文字オフセット）。文字の箱の上端が変わった位置を行頭とする。
List<int> _lineStarts(RenderParagraph p) {
  final length = p.text.toPlainText().length;
  final starts = <int>[];
  double? lastTop;
  for (var i = 0; i < length; i++) {
    final boxes = p.getBoxesForSelection(
      TextSelection(baseOffset: i, extentOffset: i + 1),
    );
    if (boxes.isEmpty) continue;
    final top = boxes.first.top;
    if (lastTop == null || top > lastTop + 1) {
      starts.add(i);
      lastTop = top;
    }
  }
  return starts;
}

int _lineCount(RenderParagraph p) => _lineStarts(p).length;

Finder get _hScroll => find.byWidgetPredicate(
  (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
);

Widget _table(List<String> cols, List<List<String>> rows) =>
    ReadingSectionContent(
      section: ReadingSection(
        heading: '表',
        kind: 'table',
        table: ReadingTable(columns: cols, rows: rows),
      ),
    );

void main() {
  group('keepReadingNumbersTogether', () {
    test('数字・金額の語だけに連結文字を入れ、除くと元に戻る', () {
      for (final s in ['300,000円', '¥1,350,000', '△2,400万円', '増加率12.5%']) {
        final out = keepReadingNumbersTogether(s);
        expect(out, contains(kReadingWordJoiner), reason: s);
        expect(out.replaceAll(kReadingWordJoiner, ''), s);
      }
    });

    test('短い数字や数字を含まない文は変えない', () {
      for (final s in ['', 'A', '説明A', '第2章', '10%', '3個', '借方・貸方']) {
        expect(keepReadingNumbersTogether(s), s);
      }
    });

    testWidgets('読み上げは元の文字列', (tester) async {
      final t = readingNumberSafeText('合計300,000円です');
      expect(t.semanticsLabel, '合計300,000円です');
      expect(readingNumberSafeText('合計').semanticsLabel, isNull);
    });
  });

  group('(A) 数字・金額は途中で折り返さない', () {
    testWidgets('数字列と単位の間では折らず、語の前で折る', (tester) async {
      const style = TextStyle(fontSize: 14);
      const raw = 'ああ300,000円';
      final probe = TextPainter(
        text: const TextSpan(text: 'ああ300,000', style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      // 「ああ300,000」までは1行に入るが「円」は入らない幅
      final width = probe.width + 1;
      probe.dispose();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: readingNumberSafeText(raw, style: style),
            ),
          ),
        ),
      );
      final display = keepReadingNumbersTogether(raw);
      final p = _paragraph(tester, find.byType(Text));
      final start = display.indexOf('3');
      final starts = _lineStarts(p);
      expect(starts.length, 2);
      for (final s in starts) {
        expect(s > start && s < display.length, isFalse, reason: '行頭=$s');
      }
    });

    testWidgets('4列の表(390幅)の金額セルは1行のまま', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _app(
          _table(
            ['勘定科目', '借方', '貸方', '金額の求め方'],
            [
              ['車両運搬具', '300,000円', '240,000円', '取得原価'],
              ['減価償却累計額', '1,350,000円', '2,400,000円', '定額法で計算'],
            ],
          ),
        ),
      );
      await _settle(tester);
      expect(tester.takeException(), isNull);
      for (final n in ['300,000円', '240,000円', '1,350,000円', '2,400,000円']) {
        expect(_lineCount(_paragraph(tester, _textOf(n))), 1);
      }
    });
  });

  group('(B) 表の列幅', () {
    testWidgets('2・3列は従来どおり（均等幅・横スクロールなし）', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _app(
          _table(
            ['用語', '意味', '例'],
            [
              ['A', '説明A', 'x'],
            ],
          ),
        ),
      );
      await _settle(tester);
      expect(tester.widget<Table>(find.byType(Table)).columnWidths, isNull);
      expect(_hScroll, findsNothing);
    });

    testWidgets('4列でも各列が余裕で収まるなら従来どおり', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _app(
          _table(
            ['A', 'B', 'C', 'D'],
            [
              ['1', '2', '3', '4'],
            ],
          ),
        ),
      );
      await _settle(tester);
      expect(tester.widget<Table>(find.byType(Table)).columnWidths, isNull);
      expect(_hScroll, findsNothing);
      expect(tester.getSize(find.byType(Table)).width, 390);
    });

    testWidgets('4列で1列だけ幅が要る: 全幅のまま列幅を配分し、見出しは折れない', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _app(
          _table(
            ['減価償却累計額', 'A', 'B', 'C'],
            [
              ['x', '1', '2', '3'],
            ],
          ),
        ),
      );
      await _settle(tester);
      expect(_hScroll, findsNothing);
      expect(tester.getSize(find.byType(Table)).width, 390);
      expect(
        _lineCount(_paragraph(tester, _textOf('減価償却累計額'))),
        1,
      );
    });

    testWidgets('4列が画面幅に収まらないときは表全体が横スクロール、順序は行→列', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _app(
          _table(
            ['減価償却累計額', '借方・貸方', '金額', '金額の求め方'],
            [
              ['車両運搬具', '300,000円', '240,000円', '取得原価'],
            ],
          ),
        ),
      );
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(_hScroll, findsOneWidget);
      expect(tester.getSize(find.byType(Table)).width, greaterThan(390));
      // 見出しは語の途中で折れない
      for (final h in ['減価償却累計額', '借方・貸方', '金額の求め方']) {
        expect(_lineCount(_paragraph(tester, _textOf(h))), 1);
      }
      final table = tester.widget<Table>(find.byType(Table));
      expect(table.children.length, 2);
      final texts = [
        for (final row in table.children)
          for (final c in row.children)
            ((c as Container).child! as Text).semanticsLabel ??
                (c.child! as Text).data,
      ];
      expect(texts, [
        '減価償却累計額',
        '借方・貸方',
        '金額',
        '金額の求め方',
        '車両運搬具',
        '300,000円',
        '240,000円',
        '取得原価',
      ]);
      // 横にスクロールできる
      await tester.drag(_hScroll, const Offset(-200, 0));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('文字3倍・6列でも例外なし', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _app(
          _table(
            ['一', '二', '三', '四', '五', '六'],
            [
              ['300,000円', 'b', 'c', 'd', 'e', 'f'],
            ],
          ),
          scale: 3,
        ),
      );
      await _settle(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('(C) ReadingQuestionLinks のラベル', () {
    Future<void> pumpLink(WidgetTester tester, String label) async {
      _phone(tester);
      await tester.pumpWidget(
        _app(
          ReadingQuestionLinks(
            questionIds: const ['q1'],
            onOpenQuestion: (_) {},
            labels: {'q1': label},
            strings: AnswerFeedbackStrings.ja,
          ),
        ),
      );
      await _settle(tester);
    }

    testWidgets('長いラベルは最大3行で折り返し、末尾だけ省略', (tester) async {
      final label = '営業用の車両運搬具(取得原価1,350,000円)の減価償却${'あ' * 150}';
      await pumpLink(tester, label);
      final p = _paragraph(tester, _textOf(label));
      expect(_lineCount(p), 3);
      expect(p.didExceedMaxLines, isTrue);
      final display = keepReadingNumbersTogether(label);
      final start = display.indexOf('1$kReadingWordJoiner,');
      final end = display.indexOf('円') + 1;
      for (final s in _lineStarts(p)) {
        expect(s > start && s < end, isFalse, reason: '行頭=$s');
      }
    });

    testWidgets('ラベル文字列は事前に切り詰めない（省略は Text の ellipsis に任せる）', (tester) async {
      final label = '営業用の車両運搬具(取得原価1,350,000円)の減価償却${'あ' * 150}';
      await pumpLink(tester, label);
      final text = tester.widget<Text>(_textOf(label));
      expect(text.data!.replaceAll(kReadingWordJoiner, ''), label);
      expect(text.data!, isNot(contains('…')));
      expect(text.maxLines, 3);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.semanticsLabel, label);
    });

    testWidgets('3行に収まるラベルは省略しない', (tester) async {
      final label = 'あ' * 40;
      await pumpLink(tester, label);
      final p = _paragraph(tester, _textOf(label));
      expect(_lineCount(p), lessThanOrEqualTo(3));
      expect(p.didExceedMaxLines, isFalse);
    });

    testWidgets('タップで qid を返す（従来どおり）', (tester) async {
      final opened = <String>[];
      _phone(tester);
      await tester.pumpWidget(
        _app(
          ReadingQuestionLinks(
            questionIds: const ['q1'],
            onOpenQuestion: opened.add,
            labels: const {'q1': '金額300,000円の問題'},
            strings: AnswerFeedbackStrings.ja,
          ),
        ),
      );
      await _settle(tester);
      await tester.tap(find.byType(OutlinedButton));
      expect(opened, ['q1']);
    });
  });

  group('(D) 横スクロールのヒント', () {
    final hint = find.byIcon(Icons.chevron_right);
    final wide = _table(
      ['減価償却累計額', '借方・貸方', '金額', '金額の求め方'],
      [
        ['車両運搬具', '300,000円', '240,000円', '取得原価'],
      ],
    );

    testWidgets('横スクロールのとき表示し、右端に達したら消える', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(wide));
      await _settle(tester);
      expect(_hScroll, findsOneWidget);
      expect(hint, findsOneWidget);
      // 装飾なので読み上げ対象にしない
      expect(
        find.ancestor(of: hint, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
      await tester.drag(_hScroll, const Offset(-2000, 0));
      await _settle(tester);
      expect(hint, findsNothing);
      await tester.drag(_hScroll, const Offset(2000, 0));
      await _settle(tester);
      expect(hint, findsOneWidget);
    });

    testWidgets('スクロール不要の表（均等幅・全幅配分）では出さない', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _app(
          _table(
            ['A', 'B', 'C', 'D'],
            [
              ['1', '2', '3', '4'],
            ],
          ),
        ),
      );
      await _settle(tester);
      expect(_hScroll, findsNothing);
      expect(hint, findsNothing);
    });
  });
}
