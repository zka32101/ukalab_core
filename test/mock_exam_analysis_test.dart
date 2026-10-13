import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

List<MockExamAnswer> a(String t, int right, int wrong) => [
      for (var i = 0; i < right; i++) MockExamAnswer(topicId: t, correct: true),
      for (var i = 0; i < wrong; i++) MockExamAnswer(topicId: t, correct: false),
    ];

const _banJa = [
  'サボ', 'さぼ', '遅れ', 'ダメ', 'だめ', '駄目', 'ないと', 'なければ', 'べき', '怠', '失敗',
  '焦', '急が', '急い', '間に合わ', '足りな', '不足', '弱', '危', '残念', '少な', '減', '以下',
  '不合格',
];
const _banEn = [
  'lazy', 'behind', 'weak', 'poor', 'bad', 'fail', 'must', 'have to', 'should', 'hurry',
  'rush', 'only ', 'worry', 'disappoint', 'less ', 'drop', 'decline', 'missed',
];

void main() {
  const engine = MockExamAnalysisEngine();

  test('分野別の正答率と全体の集計', () {
    final r = engine.analyze([...a('b', 3, 1), ...a('a', 1, 1)]);
    expect(r.answered, 6);
    expect(r.correct, 4);
    expect([for (final t in r.topics) t.topicId], ['a', 'b']);
    expect(r.topics[1].accuracy, 0.75);
  });

  test('空・分野IDが空の回答は無視', () {
    expect(engine.analyze(const []).isEmpty, isTrue);
    final r = engine.analyze([const MockExamAnswer(topicId: '', correct: false)]);
    expect(r.isEmpty, isTrue);
    expect(r.accuracy, 0);
    expect(r.nextTopics, isEmpty);
  });

  test('弱点は minSamples 未満を除き、正答率の低い順', () {
    final r = engine.analyze([
      ...a('x', 0, 1), // 1問だけ: 弱点にしない
      ...a('b', 1, 3),
      ...a('c', 0, 2),
      ...a('d', 4, 0),
    ]);
    expect([for (final t in r.weakTopics) t.topicId], ['c', 'b']);
  });

  test('次にやる分野は最大3件・低い順・同率は解答数の多い順→ID順、得意(0.9以上)は除く', () {
    final r = engine.analyze([
      ...a('a', 1, 1), // .5 n2
      ...a('b', 2, 2), // .5 n4
      ...a('c', 1, 1), // .5 n2
      ...a('d', 0, 1), // 0
      ...a('e', 9, 1), // .9 除外
    ]);
    expect([for (final t in r.nextTopics) t.topicId], ['d', 'b', 'a']);
    final one = const MockExamAnalysisEngine(nextCount: 1).analyze(a('z', 0, 3));
    expect(one.nextTopics.length, 1);
  });

  test('全分野が得意なら次の分野は空', () {
    final r = engine.analyze([...a('a', 10, 0), ...a('b', 5, 0)]);
    expect(r.nextTopics, isEmpty);
    expect(r.weakTopics, isEmpty);
  });

  test('文言に責める表現を含めない（ja/en）', () {
    for (final t in MockExamAnalysisStrings.ja.allTexts) {
      for (final w in _banJa) {
        expect(t.contains(w), isFalse, reason: '"$t" contains "$w"');
      }
    }
    for (final t in MockExamAnalysisStrings.en.allTexts) {
      for (final w in _banEn) {
        expect(t.toLowerCase().contains(w), isFalse, reason: '"$t" contains "$w"');
      }
    }
    expect(MockExamAnalysisStrings.forLanguageCode('en'), same(MockExamAnalysisStrings.en));
    expect(MockExamAnalysisStrings.forLanguageCode('ko'), same(MockExamAnalysisStrings.ja));
  });
}
