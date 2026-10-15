// peer_devices / peer_summaries のルールを Firestore エミュレータで検査する（配備はしない）。
// 実行: cd firebase/emulator_test && npm ci && npx firebase emulators:exec --only firestore --project demo-peer "node peer_rules.test.mjs"
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { collection, deleteDoc, doc, getDoc, getDocs, serverTimestamp, setDoc, Timestamp } from 'firebase/firestore';

const rules = readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8');
const env = await initializeTestEnvironment({ projectId: 'demo-peer', firestore: { rules, host: '127.0.0.1', port: 8080 } });

const id = (n) => `${n}23e4567-e89b-42d3-a456-426614174000`;
const base = () => ({ day: '2026-10-15', streakDays: 5, totalQuestions: 300, examDate: '2026-12-06' });
const good = () => ({ ...base(), updatedAt: serverTimestamp() });
const hoursAgo = (h) => Timestamp.fromDate(new Date(Date.now() - h * 3600e3));

// 既存ドキュメント（更新テスト用）はルール無効で先に作る。
await env.withSecurityRulesDisabled(async (c) => {
  const f = c.firestore();
  await setDoc(doc(f, `peer_devices/fe/devices/${id(6)}`), { ...base(), updatedAt: hoursAgo(21) });
  await setDoc(doc(f, `peer_devices/fe/devices/${id(7)}`), { ...base(), updatedAt: hoursAgo(19) });
});

const db = env.authenticatedContext('u1').firestore();
const ref = (i = id(1), exam = 'fe') => doc(db, `peer_devices/${exam}/devices/${i}`);

let ng = 0;
const t = async (name, p) => {
  try { await p; console.log('OK  ', name); } catch (e) { ng++; console.log('NG  ', name, String(e).slice(0, 150)); }
};
const no = (o, k) => Object.fromEntries(Object.entries(o).filter(([x]) => x !== k));

await t('正常な create', assertSucceeds(setDoc(ref(), good())));
await t('直後の update は過剰頻度で拒否', assertFails(setDoc(ref(), good())));
await t('21時間後の update は許可', assertSucceeds(setDoc(ref(id(6)), good())));
await t('19時間後の update は拒否', assertFails(setDoc(ref(id(7)), good())));
await t('examDate なしの create', assertSucceeds(setDoc(ref(id(5)), no(good(), 'examDate'))));
await t('get 拒否', assertFails(getDoc(ref())));
await t('list 拒否', assertFails(getDocs(collection(db, 'peer_devices/fe/devices'))));
await t('delete 拒否', assertFails(deleteDoc(ref())));
await t('余計なキー拒否', assertFails(setDoc(ref(id(2)), { ...good(), userId: 'u1' })));
await t('必須キー欠落拒否', assertFails(setDoc(ref(id(2)), no(good(), 'day'))));
await t('streakDays 範囲外拒否', assertFails(setDoc(ref(id(2)), { ...good(), streakDays: 3651 })));
await t('totalQuestions 範囲外拒否', assertFails(setDoc(ref(id(2)), { ...good(), totalQuestions: 1000001 })));
await t('examDate 形式不正拒否', assertFails(setDoc(ref(id(2)), { ...good(), examDate: 'soon' })));
await t('updatedAt がサーバ時刻でないと拒否', assertFails(setDoc(ref(id(2)), { ...good(), updatedAt: hoursAgo(1) })));
await t('installId が UUID 形式でないと拒否', assertFails(setDoc(ref('u1'), good())));
await t('未登録の examId 拒否', assertFails(setDoc(ref(id(2), 'nope'), good())));
await t('未ログイン拒否', assertFails(setDoc(doc(env.unauthenticatedContext().firestore(), `peer_devices/fe/devices/${id(3)}`), good())));
await t('要約はログインすれば読める', assertSucceeds(getDoc(doc(db, 'peer_summaries/fe'))));
await t('要約は書けない', assertFails(setDoc(doc(db, 'peer_summaries/fe'), { asOf: 'x' })));

await env.cleanup();
console.log(ng === 0 ? '全件期待どおり' : `${ng} 件NG`);
process.exit(ng ? 1 : 0);
