import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/glossary.dart';
import 'package:ukalab_core/ukalab_core.dart' show QuestionSource, Term;

Term _t(String id, String name, {String? subject}) => Term(
      termId: id,
      examId: 'x',
      term: name,
      headline: '$nameの説明',
      definition: '定義',
      source: QuestionSource.original,
      sourceRef: '',
      contentVer: '1',
      subjectId: subject,
    );

void main() {
  test('覚えたはアプリIDごとに別で、保存して読み直せる', () async {
    SharedPreferences.setMockInitialValues({});
    final a = LearnedTermsStore('a');
    await a.setLearned('t1', true);
    await a.setLearned('t2', true);
    await a.setLearned('t1', false);
    expect(await a.load(), {'t2'});
    expect(await LearnedTermsStore('b').load(), isEmpty);
    await a.replace({'t9'});
    expect(await a.load(), {'t9'});
  });

  testWidgets('検索・分野・覚えたで絞り込める', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final terms = [_t('1', 'りんご', subject: 's1'), _t('2', 'みかん', subject: 's2'), _t('3', 'ぶどう', subject: 's1')];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GlossaryListView(
          terms: terms,
          store: LearnedTermsStore('t'),
          subjects: const {'s1': '果物A', 's2': '果物B'},
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('りんご'), findsOneWidget);
    expect(find.text('みかん'), findsOneWidget);

    await tester.tap(find.text('果物B'));
    await tester.pump();
    expect(find.text('みかん'), findsOneWidget);
    expect(find.text('りんご'), findsNothing);

    await tester.tap(find.text('すべての分野'));
    await tester.enterText(find.byType(TextField), 'ぶど');
    await tester.pump();
    expect(find.text('ぶどう'), findsOneWidget);
    expect(find.text('りんご'), findsNothing);
  });

  testWidgets('覚えたにチェックすると「覚えた」フィルタに出る', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = LearnedTermsStore('t2');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: GlossaryListView(terms: [_t('1', 'りんご'), _t('2', 'みかん')], store: store)),
    ));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.byType(Checkbox).first);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.tap(find.text('覚えた'));
    await tester.pump();
    // 一覧は用語名の順なので、先頭の「みかん」にチェックが付いている。
    expect(find.text('りんご'), findsNothing);
    expect(find.text('みかん'), findsOneWidget);
  });

  testWidgets('分野を指定して開くと未習得に絞られ、チップで全件に戻せる', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GlossaryListView(
          terms: [_t('1', 'りんご', subject: 's1'), _t('2', 'みかん', subject: 's2')],
          store: LearnedTermsStore('t3'),
          initialSubjectId: 's1',
          initialSubjectLabel: '果物A',
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('りんご'), findsOneWidget);
    expect(find.text('みかん'), findsNothing);
    await tester.tap(find.textContaining('で絞り込み中'));
    await tester.pump();
    expect(find.text('みかん'), findsOneWidget);
  });
}
