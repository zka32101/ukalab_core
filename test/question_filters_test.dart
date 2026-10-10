import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

Question _q({
  required String qid,
  String prompt = '問題文',
  String explanation = '解説文',
  List<String> choices = const [],
}) =>
    Question(
      qid: qid,
      examId: 'sample',
      subjectId: 'law',
      topicId: 'topic',
      prompt: prompt,
      explanation: explanation,
      choices: choices,
      source: QuestionSource.original,
      sourceRef: 'test',
      contentVer: '2026.10.0',
    );

void main() {
  group('filterByBookmark', () {
    final pool = [_q(qid: 'q1'), _q(qid: 'q2'), _q(qid: 'q3')];

    test('onlyBookmarkedがfalseならそのまま返す', () {
      expect(filterByBookmark(pool, {'q1'}, onlyBookmarked: false), pool);
    });

    test('onlyBookmarkedがtrueならブックマーク済みだけに絞り込む', () {
      final filtered = filterByBookmark(pool, {'q1', 'q3'}, onlyBookmarked: true);
      expect(filtered.map((q) => q.qid), ['q1', 'q3']);
    });

    test('ブックマークが空ならonlyBookmarked指定時に空を返す', () {
      expect(filterByBookmark(pool, {}, onlyBookmarked: true), isEmpty);
    });
  });

  group('searchQuestions', () {
    final pool = [
      _q(qid: 'q1', prompt: '引火点とは何か', explanation: '可燃性蒸気を発生する最低温度'),
      _q(qid: 'q2', prompt: '指定数量の倍数', explanation: '商の和が1以上'),
      _q(qid: 'q3', prompt: '選択肢に用語', choices: const ['引火点が低い', 'その他']),
    ];

    test('問題文に一致する問題を返す', () {
      expect(searchQuestions(pool, '引火点').map((q) => q.qid), containsAll(['q1', 'q3']));
    });

    test('解説文に一致する問題を返す', () {
      expect(searchQuestions(pool, '商の和').map((q) => q.qid), ['q2']);
    });

    test('大文字小文字は区別しない', () {
      final mixed = [_q(qid: 'q4', prompt: 'CS2の引火点')];
      expect(searchQuestions(mixed, 'cs2').map((q) => q.qid), ['q4']);
    });

    test('空のキーワードでは何も返さない', () {
      expect(searchQuestions(pool, ''), isEmpty);
      expect(searchQuestions(pool, '   '), isEmpty);
    });

    test('一致しないキーワードでは空を返す', () {
      expect(searchQuestions(pool, '存在しない語句'), isEmpty);
    });
  });

  group('filterMemoedQuestions', () {
    final pool = [
      _q(qid: 'q1', prompt: '引火点とは何か'),
      _q(qid: 'q2', prompt: '指定数量の倍数'),
      _q(qid: 'q3', prompt: 'メモの無い問題'),
    ];

    test('メモが書かれている問題だけを返す（空キーワード）', () {
      final memos = {'q1': '覚え方メモ', 'q2': '商の和メモ'};
      final result = filterMemoedQuestions(pool, memos, '');
      expect(result.map((q) => q.qid), ['q1', 'q2']);
    });

    test('キーワードが問題文に含まれるものだけに絞り込む', () {
      final memos = {'q1': '覚え方メモ', 'q2': '商の和メモ'};
      final result = filterMemoedQuestions(pool, memos, '引火点');
      expect(result.map((q) => q.qid), ['q1']);
    });

    test('キーワードがメモ本文に含まれるものだけに絞り込む', () {
      final memos = {'q1': '覚え方メモ', 'q2': '商の和メモ'};
      final result = filterMemoedQuestions(pool, memos, '商の和');
      expect(result.map((q) => q.qid), ['q2']);
    });

    test('メモが無い問題は含まれない', () {
      final memos = {'q1': '覚え方メモ'};
      final result = filterMemoedQuestions(pool, memos, '');
      expect(result.map((q) => q.qid), ['q1']);
    });

    test('メモが1件も無ければ空を返す', () {
      expect(filterMemoedQuestions(pool, {}, ''), isEmpty);
    });
  });

  group('allBookmarkTags', () {
    test('指定したqid集合の中で使われているタグを名前順で返す', () {
      final tags = {
        'q1': {'暗記'},
        'q2': {'要復習', '計算問題'},
        'q3': {'無関係'},
      };
      expect(allBookmarkTags(tags, ['q1', 'q2']), ['暗記', '要復習', '計算問題']..sort());
    });

    test('対象qidに無いタグは含めない', () {
      final tags = {'q1': {'暗記'}};
      expect(allBookmarkTags(tags, ['q2']), isEmpty);
    });
  });
}
