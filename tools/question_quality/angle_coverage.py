#!/usr/bin/env python3
"""観点（conceptId / angle）のカバレッジを集計する参考スクリプト（docs/multi_angle_questions_design.md フェーズ1）。

標準ライブラリのみ。入力は JSON Lines（1行1問。拡張子 .json の配列も可）。既定のフィールド名は
core の Question モデルに合わせてある:
  conceptId(用語・概念の安定ID) / angle(definition|scenario|comparison|reverse|cloze|trueFalse) /
  disabled(true は除外)

測り方: conceptId を持つ有効な問題について、概念ごとの異なる angle の数を数える。
  警告: 異なる angle が 2 未満の概念 / angle が未知の値 / conceptId があるのに angle が無い問題。
  conceptId を持つ問題が 1 件も無いデータ（既存データ）では何も警告しない。

使い方:
  python3 tools/question_quality/angle_coverage.py questions.jsonl [more.jsonl ...]
  python3 tools/question_quality/angle_coverage.py q.jsonl --format json > angle_report.json
  python3 tools/question_quality/angle_coverage.py q.jsonl --concept-key cid --angle-key viewpoint

出力は決定的（ソート済み）。Dart 側 `validate_content --angle-report` と同じ集計。
終了コードは既定で常に 0（CI を止めない）。--strict を付けたときだけ、警告があれば 1。
--annotate で GitHub Actions の ::warning:: 注釈も出す。
"""
import argparse
import json
import sys

ANGLES = ["definition", "scenario", "comparison", "reverse", "cloze", "trueFalse"]


def load_rows(path):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    if path.endswith(".json"):
        data = json.loads(text)
        return data if isinstance(data, list) else []
    rows = []
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("//"):
            continue
        try:
            obj = json.loads(line)
        except ValueError:
            continue
        if isinstance(obj, dict):
            rows.append(obj)
    return rows


def analyze(rows, concept_key="conceptId", angle_key="angle"):
    """集計と警告を返す。rows は dict の配列。"""
    active = [r for r in rows if r.get("disabled") is not True]
    by_angle = {a: 0 for a in ANGLES}
    per_concept = {}
    warnings = []
    with_concept = with_angle = 0
    for r in active:
        qid = r.get("qid", "?")
        angle = r.get(angle_key)
        known = isinstance(angle, str) and angle in ANGLES
        if angle is not None and not known:
            warnings.append(("angle-unknown", qid, f"未知の angle: {angle}"))
        if known:
            with_angle += 1
            by_angle[angle] += 1
        cid = r.get(concept_key)
        if not isinstance(cid, str) or not cid.strip():
            continue
        with_concept += 1
        c = per_concept.setdefault(cid, {"angles": {}, "unspecified": 0})
        if known:
            c["angles"][angle] = c["angles"].get(angle, 0) + 1
        else:
            c["unspecified"] += 1
            if angle is None:
                warnings.append(("concept-without-angle", qid, f"conceptId({cid}) があるのに angle がありません"))
    concepts = []
    for cid in sorted(per_concept):
        c = per_concept[cid]
        concepts.append({
            "conceptId": cid,
            "angleCount": len(c["angles"]),
            "angles": {a: c["angles"][a] for a in ANGLES if a in c["angles"]},
            "unspecified": c["unspecified"],
        })
        if len(c["angles"]) < 2:
            warnings.append(("concept-single-angle", cid, f"異なる angle が {len(c['angles'])} 種類（2 以上が望ましい）"))
    multi = sum(1 for c in concepts if c["angleCount"] >= 2)
    report = {
        "totalQuestions": len(active),
        "questionsWithConcept": with_concept,
        "questionsWithAngle": with_angle,
        "conceptIdRate": (with_concept / len(active)) if active else None,
        "conceptCount": len(concepts),
        "conceptsWithMultipleAngles": multi,
        "multiAngleRate": (multi / len(concepts)) if concepts else None,
        "questionsByAngle": by_angle,
        "concepts": concepts,
        "conceptsBelowTwoAngles": [c["conceptId"] for c in concepts if c["angleCount"] < 2],
    }
    return report, warnings


def pct(r):
    return "-" if r is None else f"{r * 100:.1f}%"


def to_markdown(rep):
    out = ["# 観点カバレッジ", "", "| 項目 | 値 |", "|---|---|",
           f"| 有効な問題数 | {rep['totalQuestions']} |",
           f"| conceptId 付与 | {rep['questionsWithConcept']} ({pct(rep['conceptIdRate'])}) |",
           f"| angle 付与 | {rep['questionsWithAngle']} |",
           f"| 概念数 | {rep['conceptCount']} |",
           f"| 2 観点以上の概念 | {rep['conceptsWithMultipleAngles']} ({pct(rep['multiAngleRate'])}) |",
           "", "## 観点別の問題数", "", "| 観点 | 問題数 |", "|---|---|"]
    out += [f"| {a} | {rep['questionsByAngle'][a]} |" for a in ANGLES]
    out += ["", "## 概念別", ""]
    if not rep["concepts"]:
        out.append("conceptId を持つ問題がありません。")
    else:
        out += ["| conceptId | 観点数 | " + " | ".join(ANGLES) + " | angle なし |",
                "|---|---|" + "---|" * (len(ANGLES) + 1)]
        for c in rep["concepts"]:
            out.append(f"| {c['conceptId']} | {c['angleCount']} | "
                       + " | ".join(str(c["angles"].get(a, 0)) for a in ANGLES)
                       + f" | {c['unspecified']} |")
    out += ["", "## 観点が 2 未満の概念", ""]
    below = rep["conceptsBelowTwoAngles"]
    out += [f"- {cid}" for cid in below] if below else ["なし"]
    return "\n".join(out) + "\n"


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("files", nargs="+", help="問題の JSON Lines（または .json の配列）")
    ap.add_argument("--concept-key", default="conceptId")
    ap.add_argument("--angle-key", default="angle")
    ap.add_argument("--format", choices=["md", "json"], default="md")
    ap.add_argument("--annotate", action="store_true", help="GitHub Actions の ::warning:: を出す")
    ap.add_argument("--strict", action="store_true", help="警告があれば終了コード 1")
    # run_checks.py が共通で渡すオプション（このツールでは使わない）
    for opt in ("--choices-key", "--answer-key", "--type-key", "--category-key", "--min-n"):
        ap.add_argument(opt, help=argparse.SUPPRESS)
    a = ap.parse_args(argv)

    rows = []
    for path in a.files:
        rows += load_rows(path)
    report, warnings = analyze(rows, a.concept_key, a.angle_key)
    if report["conceptCount"] == 0 and not warnings:
        print("conceptId を持つ問題がありません（観点の集計対象なし）", file=sys.stderr)
        return 0
    if a.format == "json":
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(to_markdown(report), end="")
    for code, ident, msg in warnings:
        print(f"[warning:{code}] {ident}: {msg}", file=sys.stderr if a.format == "json" else sys.stdout)
        if a.annotate:
            print(f"::warning title=観点 {code}::{ident}: {msg}")
    return 1 if (a.strict and warnings) else 0


if __name__ == "__main__":
    sys.exit(main())
