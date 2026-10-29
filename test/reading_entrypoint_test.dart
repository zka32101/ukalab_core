// 新入口 reading.dart だけで読み物関連の公開名が使えること、および
// 既存の入口と併用しても曖昧な import にならないことを確認するコンパイルテスト。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/answer_feedback.dart' as af;
import 'package:ukalab_core/reading.dart';
import 'package:ukalab_core/ui.dart' as ui;
import 'package:ukalab_core/ukalab_core.dart' as core;

void main() {
  test('reading.dart の全公開名が解決できる', () {
    const reading = ChapterReading(
      readingId: 'r',
      examId: 'e',
      subjectId: 's',
      title: 't',
      sections: [
        ReadingSection(
          heading: 'h',
          kind: kReadingSectionTable,
          table: ReadingTable(columns: ['a'], rows: [['b']]),
          figure: ReadingFigure(asset: 'assets/a.png', alt: 'a'),
        ),
      ],
      source: core.QuestionSource.original,
      sourceRef: 'x',
      contentVer: '1',
      levelId: 'l',
      relatedLinks: [ContentLink(kind: 'hazard', id: 'h')],
    );
    expect(readingsForQuestion([reading], 'q'), isEmpty);
    expect(readingsForLevel([reading], 'l'), hasLength(1));
    expect(linksOfKind(reading, 'hazard'), hasLength(1));
    expect(validateChapterReadings([reading]), isNotEmpty);
    expect(kExplanationOtherSceneMarker, isNotEmpty);
    expect(ExplanationParts.fromPlain('x').hasBody, isTrue);
  });

  test('ウィジェット型も新入口から参照でき、既存入口と同一', () {
    expect(ExplanationCard, same(ui.ExplanationCard));
    expect(ExplanationCard, same(af.ExplanationCard));
    expect(RelatedReadingsCard, same(ui.RelatedReadingsCard));
    expect(RelatedReadingsCard, same(af.RelatedReadingsCard));
    expect(ReadingSectionContent, same(ui.ReadingSectionContent));
    expect(ReadingQuestionLinks, same(af.ReadingQuestionLinks));
    expect(core.ChapterReading, same(ChapterReading));
    expect(core.readingsForLevel, same(readingsForLevel));
    expect(af.readingsForQuestion, same(readingsForQuestion));
  });

  testWidgets('新入口の型で組み立てられる', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadingSectionContent(
            section: const ReadingSection(heading: 'h', body: 'b'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('b'), findsOneWidget);
  });
}
