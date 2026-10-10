import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';

void main() {
  group('BookmarkService.toggle', () {
    test('ブックマークしていない問題をトグルすると追加される', () async {
      final service = BookmarkService(store: _FakeBookmarkStore());
      await service.toggle('q1');
      expect(service.qids, {'q1'});
    });

    test('ブックマーク済みの問題をトグルすると外れる', () async {
      final service = BookmarkService(store: _FakeBookmarkStore());
      await service.toggle('q1');
      await service.toggle('q1');
      expect(service.qids, isEmpty);
    });

    test('複数の問題を独立にブックマークできる', () async {
      final service = BookmarkService(store: _FakeBookmarkStore());
      await service.toggle('q1');
      await service.toggle('q2');
      expect(service.qids, {'q1', 'q2'});
    });

    test('保存・再読み込みで状態が復元される', () async {
      final store = _FakeBookmarkStore();
      final service = BookmarkService(store: store);
      await service.toggle('q1');

      final reloaded = BookmarkService(store: store);
      await reloaded.load();
      expect(reloaded.qids, {'q1'});
    });
  });

  group('BookmarkTagService', () {
    test('addTagでタグが追加される', () async {
      final service = BookmarkTagService(store: _FakeBookmarkTagStore());
      await service.addTag('q1', '要復習');
      expect(service.tags['q1'], {'要復習'});
    });

    test('同じタグを重複して追加しても1件のまま', () async {
      final service = BookmarkTagService(store: _FakeBookmarkTagStore());
      await service.addTag('q1', '要復習');
      await service.addTag('q1', '要復習');
      expect(service.tags['q1'], {'要復習'});
    });

    test('空文字のタグは追加されない', () async {
      final service = BookmarkTagService(store: _FakeBookmarkTagStore());
      await service.addTag('q1', '   ');
      expect(service.tags.containsKey('q1'), isFalse);
    });

    test('removeTagでタグを外せる。残りが空ならキー自体が消える', () async {
      final service = BookmarkTagService(store: _FakeBookmarkTagStore());
      await service.addTag('q1', '要復習');
      await service.addTag('q1', '暗記');
      await service.removeTag('q1', '要復習');
      expect(service.tags['q1'], {'暗記'});
      await service.removeTag('q1', '暗記');
      expect(service.tags.containsKey('q1'), isFalse);
    });

    test('clearForQidでその問題のタグがすべて消える', () async {
      final service = BookmarkTagService(store: _FakeBookmarkTagStore());
      await service.addTag('q1', '要復習');
      await service.addTag('q2', '暗記');
      await service.clearForQid('q1');
      expect(service.tags.containsKey('q1'), isFalse);
      expect(service.tags['q2'], {'暗記'});
    });

    test('保存・再読み込みでタグが復元される', () async {
      final store = _FakeBookmarkTagStore();
      final service = BookmarkTagService(store: store);
      await service.addTag('q1', '要復習');

      final reloaded = BookmarkTagService(store: store);
      await reloaded.load();
      expect(reloaded.tags['q1'], {'要復習'});
    });
  });

  group('QuestionMemoService.setMemo', () {
    test('メモを保存できる', () async {
      final service = QuestionMemoService(store: _FakeStore());
      await service.setMemo(qid: 'q1', memo: '覚え方：ゴロ合わせ');
      expect(service.memos['q1'], '覚え方：ゴロ合わせ');
    });

    test('前後の空白はトリムされる', () async {
      final service = QuestionMemoService(store: _FakeStore());
      await service.setMemo(qid: 'q1', memo: '  メモ本文  ');
      expect(service.memos['q1'], 'メモ本文');
    });

    test('空文字（トリム後）を保存するとメモが削除される', () async {
      final service = QuestionMemoService(store: _FakeStore());
      await service.setMemo(qid: 'q1', memo: 'メモ本文');
      await service.setMemo(qid: 'q1', memo: '   ');
      expect(service.memos.containsKey('q1'), isFalse);
    });

    test('複数の問題のメモを独立して保存できる', () async {
      final service = QuestionMemoService(store: _FakeStore());
      await service.setMemo(qid: 'q1', memo: 'メモ1');
      await service.setMemo(qid: 'q2', memo: 'メモ2');
      expect(service.memos['q1'], 'メモ1');
      expect(service.memos['q2'], 'メモ2');
    });

    test('保存・再読み込みで状態が復元される', () async {
      final store = _FakeStore();
      final service = QuestionMemoService(store: store);
      await service.setMemo(qid: 'q1', memo: 'メモ本文');

      final reloaded = QuestionMemoService(store: store);
      await reloaded.load();
      expect(reloaded.memos['q1'], 'メモ本文');
    });

    test('resetでメモが空になる', () async {
      final service = QuestionMemoService(store: _FakeStore());
      await service.setMemo(qid: 'q1', memo: 'メモ本文');
      await service.reset();
      expect(service.memos, isEmpty);
    });
  });
  group('端末内の保存', () {
    // 既存のアプリ（otsu4）が保存済みの値をそのまま読めるよう、保存キーは従来と同じにする。
    setUp(() => SharedPreferences.setMockInitialValues({
          'ukalab_otsu4_bookmarks': '["q1","q2"]',
          'ukalab_otsu4_bookmark_tags': '{"q1":["要復習"]}',
          'ukalab_otsu4_question_memos': '{"q1":"メモ"}',
        }));

    test('従来のキーの保存値を読める', () async {
      expect(await SharedPreferencesBookmarkStore('otsu4').read(), {'q1', 'q2'});
      expect(await SharedPreferencesBookmarkTagStore('otsu4').read(), {
        'q1': {'要復習'},
      });
      expect(await SharedPreferencesQuestionMemoStore('otsu4').read(), {'q1': 'メモ'});
    });

    test('アプリIDが違えば別の保存先になる', () async {
      expect(await SharedPreferencesBookmarkStore('boki').read(), isEmpty);
    });

    test('書いた値を読み戻せる。壊れた保存値は空として扱う', () async {
      final store = SharedPreferencesBookmarkStore('g_kentei');
      await store.write({'a', 'b'});
      expect(await store.read(), {'a', 'b'});
      SharedPreferences.setMockInitialValues({'ukalab_g_kentei_bookmarks': '{壊れた'});
      expect(await SharedPreferencesBookmarkStore('g_kentei').read(), isEmpty);
    });
  });
}

/// テスト用。SharedPreferences を使わずメモリ上に保存する。
class _FakeBookmarkStore implements BookmarkStore {
  Set<String> _saved = {};

  @override
  Future<Set<String>> read() async => _saved;

  @override
  Future<void> write(Set<String> qids) async => _saved = qids;
}

class _FakeBookmarkTagStore implements BookmarkTagStore {
  Map<String, Set<String>> _saved = {};

  @override
  Future<Map<String, Set<String>>> read() async => _saved;

  @override
  Future<void> write(Map<String, Set<String>> tags) async => _saved = tags;
}

class _FakeStore implements QuestionMemoStore {
  Map<String, String> _saved = {};

  @override
  Future<Map<String, String>> read() async => _saved;

  @override
  Future<void> write(Map<String, String> memos) async => _saved = memos;
}
