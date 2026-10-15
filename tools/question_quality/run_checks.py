#!/usr/bin/env python3
"""問題の質の3ツール（選択肢の長さ・断定語・観点カバレッジ）をまとめて実行する入口。各アプリの CI から1行で呼ぶ用。

  python3 tools/question_quality/run_checks.py 'assets/questions/*.jsonl'
  python3 tools/question_quality/run_checks.py data/q.jsonl --choices-key options --answer-key answer
  python3 tools/question_quality/run_checks.py 'data/**/*.jsonl' --strict     # 警告で失敗させる（既定は警告のみ）

- 引数のファイルは glob（** 可）を展開する。一致なしでも失敗しない（警告のみ）。
- 共通オプション（--choices-key --answer-key --type-key --category-key --min-n）は両ツールに渡す。
- GitHub Actions 上（GITHUB_ACTIONS=true）では ::warning:: 注釈を出し、$GITHUB_STEP_SUMMARY に結果を追記する。
- 終了コードは既定で 0。--strict のときだけ、どちらかに警告があれば 1。
"""
import argparse
import contextlib
import glob
import io
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import angle_coverage  # noqa: E402
import assertive_word_bias  # noqa: E402
import choice_length_bias  # noqa: E402


def expand(patterns):
    out = []
    for p in patterns:
        hits = sorted(glob.glob(p, recursive=True)) or ([p] if os.path.isfile(p) else [])
        for h in hits:
            if os.path.isfile(h) and h not in out:
                out.append(h)
    return out


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("files", nargs="+", help="問題ファイルまたは glob")
    ap.add_argument("--choices-key")
    ap.add_argument("--answer-key")
    ap.add_argument("--type-key")
    ap.add_argument("--category-key")
    ap.add_argument("--min-n")
    ap.add_argument("--strict", action="store_true")
    a, extra = ap.parse_known_args(argv)

    files = expand(a.files)
    if not files:
        print("::warning title=問題の質::対象ファイルが見つかりません: " + " ".join(a.files))
        return 0
    common = []
    for opt in ("choices_key", "answer_key", "type_key", "category_key", "min_n"):
        v = getattr(a, opt)
        if v is not None:
            common += ["--" + opt.replace("_", "-"), v]
    if os.environ.get("GITHUB_ACTIONS") == "true":
        common.append("--annotate")
    if a.strict:
        common.append("--strict")

    rc, md = 0, []
    for name, mod, own in (("選択肢の長さの偏り", choice_length_bias, []),
                           ("断定語バランス", assertive_word_bias, extra),
                           ("観点カバレッジ", angle_coverage, [])):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            r = mod.main(files + common + own)
        text = buf.getvalue()
        print(f"\n# {name}\n{text}")
        md.append(f"### {name}\n```\n{text}\n```")
        rc = max(rc, r)
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as f:
            f.write("## 問題の質チェック（警告のみ）\n\n対象: " + ", ".join(files) + "\n\n" + "\n".join(md) + "\n")
    return rc


if __name__ == "__main__":
    sys.exit(main())
