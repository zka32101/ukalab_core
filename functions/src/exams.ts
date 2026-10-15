/** firebase/firestore.rules の examIds() と同じ（test/exams.test.ts で一致を検査）。 */
export const EXAM_IDS: readonly string[] = [
  'g_kentei', 'gen_ai_passport', 'gen_ai_practitioner',
  'data_management', 'info_security', 'ds_kentei', 'it_passport', 'fe',
  'boki3', 'sme_consultant', 'sme_ma',
  'hazmat4', 'denken3', 'drone', 'bike_license',
  'japanese_teacher', 'kanji_kentei',
];

export const INSTALL_ID_RE = /^[0-9a-f-]{36}$/;
