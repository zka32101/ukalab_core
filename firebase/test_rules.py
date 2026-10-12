"""firestore.rules を Firebase Rules の検証 API（projects:test）で検査する。配備はしない。

使い方:
  python firebase/test_rules.py ukalab-dev
要件: gcloud にログイン済み（`gcloud auth print-access-token` が使える）こと。Java やエミュレータは不要。
"""
import json
import pathlib
import subprocess
import sys
import urllib.error
import urllib.request

project = sys.argv[1] if len(sys.argv) > 1 else 'ukalab-dev'
rules = (pathlib.Path(__file__).parent / 'firestore.rules').read_text(encoding='utf-8')
token = subprocess.run('gcloud auth print-access-token', shell=True, capture_output=True, text=True).stdout.strip()

DOC = '/databases/(default)/documents'


def case(name, method, path, uid, expect, data=None):
    req = {'method': method, 'path': f'{DOC}/{path}'}
    if uid:
        req['auth'] = {'uid': uid, 'token': {}}
    if data is not None:
        req['resource'] = {'data': data}
    return {'name': name, 'expectation': expect, 'request': req}


good_fb = {'userId': 'u1', 'title': 'タイトル', 'description': '本文', 'status': 'open'}
cases = [
    case('本人は自分の学習データを読める', 'get', 'users/u1/exams/g_kentei/progress/p1', 'u1', 'ALLOW'),
    case('本人は自分の学習データを書ける', 'create', 'users/u1/exams/bike_license/progress/p1', 'u1', 'ALLOW', {'x': 1}),
    case('漢字検定の学習データも本人は書ける', 'create', 'users/u1/exams/kanji_kentei/progress/p1', 'u1', 'ALLOW', {'x': 1}),
    case('他人の学習データは読めない', 'get', 'users/u1/exams/g_kentei/progress/p1', 'u2', 'DENY'),
    case('他人の学習データは書けない', 'create', 'users/u1/exams/g_kentei/progress/p1', 'u2', 'DENY', {'x': 1}),
    case('未ログインは読めない', 'get', 'users/u1/exams/g_kentei/progress/p1', None, 'DENY'),
    case('未登録の資格IDは使えない', 'create', 'users/u1/exams/unknown_exam/progress/p1', 'u1', 'DENY', {'x': 1}),
    case('フィードバックを自分のUIDで作成できる', 'create', 'feedback/f1', 'u1', 'ALLOW', good_fb),
    case('他人のUIDでフィードバックは作成できない', 'create', 'feedback/f1', 'u2', 'DENY', good_fb),
    case('タイトルが空のフィードバックは作れない', 'create', 'feedback/f1', 'u1', 'DENY', {**good_fb, 'title': ''}),
    case('ステータスを open 以外にできない', 'create', 'feedback/f1', 'u1', 'DENY', {**good_fb, 'status': 'closed'}),
    case('フィードバックは更新できない', 'update', 'feedback/f1', 'u1', 'DENY', good_fb),
    # 漢字マスター検定（exams/kanji_kentei/ 配下に旧 kanken のルールを入れ子にしたもの）
    case('漢検: 本人は自分のプロフィールを書ける', 'create', 'exams/kanji_kentei/users/u1/profiles/p1', 'u1', 'ALLOW', {'x': 1}),
    case('漢検: 他人のプロフィールは書けない', 'create', 'exams/kanji_kentei/users/u1/profiles/p1', 'u2', 'DENY', {'x': 1}),
    case('漢検: ランキングは本人の複合IDだけ書ける', 'create', 'exams/kanji_kentei/rankings/u1_p1', 'u1', 'ALLOW', {'x': 1}),
    case('漢検: 他人の複合IDのランキングは書けない', 'create', 'exams/kanji_kentei/rankings/u1_p1', 'u2', 'DENY', {'x': 1}),
    case('漢検: ランキングはログインすれば読める', 'get', 'exams/kanji_kentei/rankings/u1_p1', 'u2', 'ALLOW'),
    case('漢検: 未ログインはランキングを読めない', 'get', 'exams/kanji_kentei/rankings/u1_p1', None, 'DENY'),
    case('漢検: 問題マスターは書けない', 'create', 'exams/kanji_kentei/questions/q1', 'u1', 'DENY', {'x': 1}),
    case('漢検: 問題マスターは読める', 'get', 'exams/kanji_kentei/questions/q1', 'u1', 'ALLOW'),
    case('漢検: 対戦ルームは自分が作成者なら作れる', 'create', 'exams/kanji_kentei/battleRooms/r1', 'u1', 'ALLOW', {'creatorId': 'u1', 'participants': []}),
    case('漢検: 他人を作成者にした対戦ルームは作れない', 'create', 'exams/kanji_kentei/battleRooms/r1', 'u2', 'DENY', {'creatorId': 'u1', 'participants': []}),
    case('漢検: 旧パス(トップレベルusers)は使えない', 'create', 'users/u1', 'u1', 'DENY', {'x': 1}),
    case('上記以外のパスは読めない', 'get', 'secrets/s1', 'u1', 'DENY'),
    case('上記以外のパスは書けない', 'create', 'secrets/s1', 'u1', 'DENY', {'x': 1}),
]
# フィードバックの更新・読み取りは「既存ドキュメント」が要るため、別枠で resource を付ける。
cases[next(i for i, c in enumerate(cases) if c['name'] == 'フィードバックは更新できない')]['resource'] = {'data': good_fb}
cases.append({
    'name': '自分のフィードバックは読める', 'expectation': 'ALLOW',
    'request': {'method': 'get', 'path': f'{DOC}/feedback/f1', 'auth': {'uid': 'u1', 'token': {}}},
    'resource': {'data': good_fb},
})
cases.append({
    'name': '他人のフィードバックは読めない', 'expectation': 'DENY',
    'request': {'method': 'get', 'path': f'{DOC}/feedback/f1', 'auth': {'uid': 'u2', 'token': {}}},
    'resource': {'data': good_fb},
})

names = [c.pop('name') for c in cases]
body = {'source': {'files': [{'name': 'firestore.rules', 'content': rules}]},
        'testSuite': {'testCases': cases}}
req = urllib.request.Request(
    f'https://firebaserules.googleapis.com/v1/projects/{project}:test',
    data=json.dumps(body).encode('utf-8'),
    headers={'Authorization': f'Bearer {token}', 'Content-Type': 'application/json',
             'x-goog-user-project': project},
    method='POST')
try:
    res = json.load(urllib.request.urlopen(req))
except urllib.error.HTTPError as e:
    print('HTTP', e.code, e.read().decode('utf-8')[:1500])
    sys.exit(2)

issues = res.get('issues', [])
for i in issues:
    print('ルールの問題:', i)
results = res.get('testResults', [])
fail = 0
for n, r in zip(names, results):
    ok = r.get('state') == 'SUCCESS'
    fail += 0 if ok else 1
    print(('OK  ' if ok else 'NG  ') + n, '' if ok else json.dumps(r, ensure_ascii=False)[:300])
print(f'{len(results) - fail}/{len(results)} 件が期待どおり')
sys.exit(1 if fail or issues else 0)
