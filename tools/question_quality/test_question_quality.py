"""question_quality ツールの単体テスト（標準ライブラリのみ）。

  python3 -m unittest discover -s tools/question_quality -v
"""
import contextlib
import io
import json
import os
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import angle_coverage as ac  # noqa: E402
import assertive_word_bias as aw  # noqa: E402
import choice_length_bias as cl  # noqa: E402
import run_checks as rc  # noqa: E402

BIASED = os.path.join(HERE, "testdata_biased.jsonl")


def run(mod, argv):
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        code = mod.main(argv)
    return code, buf.getvalue()


def write_jsonl(rows):
    f = tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False, encoding="utf-8")
    f.write("\n".join(json.dumps(r, ensure_ascii=False) for r in rows) + "\n")
    f.close()
    return f.name


def balanced(n=40):
    # 断定語は正解にも誤答にも同じ割合で入り、長さも同程度
    rows = []
    for i in range(n):
        ch = [f"選択肢{i}あ", f"選択肢{i}い", f"選択肢{i}う", f"選択肢{i}え"]
        if i % 2 == 0:
            ch = [c + "は必ず起こる" for c in ch]
        rows.append({"qid": str(i), "choices": ch, "answerIndex": i % 4})
    return rows


class AssertiveWordTest(unittest.TestCase):
    def test_exceptions_not_counted(self):
        words = aw.CORE_WORDS
        self.assertEqual(aw.find_words("非常に重要", words, aw.DEFAULT_EXCEPTIONS), [])
        self.assertEqual(aw.find_words("必ずしも正しくない", words, aw.DEFAULT_EXCEPTIONS), [])
        self.assertEqual(aw.find_words("絶対値を求める", words, aw.DEFAULT_EXCEPTIONS), [])
        self.assertEqual(aw.find_words("必ず成り立つ", words, aw.DEFAULT_EXCEPTIONS), ["必ず"])
        self.assertEqual(aw.find_words("AのみBだけ", words, aw.DEFAULT_EXCEPTIONS), ["だけ", "のみ"])

    def test_fisher_known_value(self):
        # 3/3 vs 0/3 の両側 p は 0.1
        self.assertAlmostEqual(aw.fisher_two_sided(3, 3, 0, 3), 0.1, places=9)
        self.assertAlmostEqual(aw.fisher_two_sided(2, 4, 2, 4), 1.0, places=9)

    def test_biased_flagged_but_exit_zero(self):
        code, out = run(aw, [BIASED])
        self.assertEqual(code, 0)
        self.assertIn("判定: 要確認", out)

    def test_strict_exit_one_on_warning(self):
        code, _ = run(aw, [BIASED, "--strict"])
        self.assertEqual(code, 1)

    def test_balanced_not_flagged(self):
        p = write_jsonl(balanced())
        self.addCleanup(os.remove, p)
        code, out = run(aw, [p, "--strict"])
        self.assertEqual(code, 0)
        self.assertNotIn("要確認", out)

    def test_small_sample_is_reference_only(self):
        code, out = run(aw, [BIASED, "--min-n", "1000", "--strict"])
        self.assertEqual(code, 0)
        self.assertIn("参考値", out)

    def test_words_file_and_custom_key(self):
        rows = [{"qid": str(i), "options": ["毎回そうなる", "場合による", "ことがある", "条件次第"],
                 "answer": 1} for i in range(30)]
        p = write_jsonl(rows)
        w = tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False, encoding="utf-8")
        w.write("# 独自語\n毎回\n")
        w.close()
        self.addCleanup(os.remove, p)
        self.addCleanup(os.remove, w.name)
        code, out = run(aw, [p, "--choices-key", "options", "--answer-key", "answer",
                             "--words-file", w.name, "--strict"])
        self.assertEqual(code, 1)  # 誤答にだけ「毎回」
        self.assertIn("語リスト: 毎回", out)

    def test_exclude_and_add_words(self):
        a = aw.argparse.Namespace(words_file=None, no_extended=True, negation=False,
                                  add_words="唯一,毎回", exclude_words="全く")
        words = aw.build_words(a)
        self.assertIn("毎回", words)
        self.assertNotIn("全く", words)
        self.assertNotIn("完全に", words)  # 拡張語は --no-extended で外れる

    def test_negation_option(self):
        rows = [{"qid": str(i), "choices": ["これは正しい", "それはできない", "あれはしない", "どれもならない"],
                 "answerIndex": 0} for i in range(30)]
        p = write_jsonl(rows)
        self.addCleanup(os.remove, p)
        self.assertNotIn("要確認", run(aw, [p])[1])
        self.assertIn("要確認", run(aw, [p, "--negation"])[1])

    def test_json_array_input(self):
        f = tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8")
        json.dump(balanced(24), f)
        f.close()
        self.addCleanup(os.remove, f.name)
        code, out = run(aw, [f.name])
        self.assertEqual(code, 0)
        self.assertIn("選択式 24 問", out)

    def test_annotate(self):
        _, out = run(aw, [BIASED, "--annotate"])
        self.assertIn("::warning title=断定語バランス::", out)


class ChoiceLengthTest(unittest.TestCase):
    def test_biased_flagged_and_strict(self):
        self.assertEqual(run(cl, [BIASED])[0], 0)
        code, out = run(cl, [BIASED, "--strict", "--annotate"])
        self.assertEqual(code, 1)
        self.assertIn("::warning title=選択肢の長さ::", out)


class RunChecksTest(unittest.TestCase):
    def test_runs_both_and_exit_zero(self):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            code = rc.main([BIASED])
        self.assertEqual(code, 0)
        self.assertIn("# 選択肢の長さの偏り", buf.getvalue())
        self.assertIn("# 断定語バランス", buf.getvalue())

    def test_strict_and_glob_and_no_match(self):
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(rc.main([os.path.join(HERE, "testdata_*.jsonl"), "--strict"]), 1)
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            self.assertEqual(rc.main(["no/such/*.jsonl", "--strict"]), 0)
        self.assertIn("::warning", buf.getvalue())


class AngleCoverageTest(unittest.TestCase):
    ROWS = [
        {"qid": "a1", "conceptId": "t-1", "angle": "definition"},
        {"qid": "a2", "conceptId": "t-1", "angle": "reverse"},
        {"qid": "a3", "conceptId": "t-1", "angle": "reverse"},
        {"qid": "b1", "conceptId": "t-2", "angle": "cloze"},
        {"qid": "c1", "conceptId": "t-3"},
        {"qid": "d1", "conceptId": "t-4", "angle": "bogus"},
        {"qid": "e1", "conceptId": "t-5", "angle": "scenario", "disabled": True},
        {"qid": "f1"},
    ]

    def test_analyze(self):
        rep, warns = ac.analyze(self.ROWS)
        self.assertEqual(rep["totalQuestions"], 7)  # disabled 除外
        self.assertEqual(rep["questionsWithConcept"], 6)
        self.assertEqual(rep["conceptCount"], 4)
        self.assertEqual(rep["conceptsWithMultipleAngles"], 1)
        self.assertEqual(rep["questionsByAngle"]["reverse"], 2)
        self.assertEqual(rep["conceptsBelowTwoAngles"], ["t-2", "t-3", "t-4"])
        codes = sorted(c for c, _, _ in warns)
        self.assertEqual(codes, ["angle-unknown", "concept-single-angle", "concept-single-angle",
                                 "concept-single-angle", "concept-without-angle"])

    def test_no_concept_data_is_silent(self):
        rep, warns = ac.analyze([{"qid": "x", "choices": ["a", "b"], "answerIndex": 0}])
        self.assertEqual(rep["conceptCount"], 0)
        self.assertEqual(warns, [])
        path = write_jsonl([{"qid": "x"}])
        code, out = run(ac, [path, "--strict"])
        self.assertEqual((code, out), (0, ""))

    def test_exit_codes_and_formats(self):
        path = write_jsonl(self.ROWS)
        code, out = run(ac, [path])
        self.assertEqual(code, 0)
        self.assertIn("# 観点カバレッジ", out)
        self.assertIn("| t-1 | 2 |", out)
        code, _ = run(ac, [path, "--strict"])
        self.assertEqual(code, 1)
        code, out = run(ac, [path, "--format", "json"])
        data = json.loads(out)
        self.assertEqual(data["conceptCount"], 4)
        self.assertEqual(out, run(ac, [path, "--format", "json"])[1])  # 決定的


if __name__ == "__main__":
    unittest.main()
