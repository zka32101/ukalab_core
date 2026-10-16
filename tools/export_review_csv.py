#!/usr/bin/env python3
"""専門家レビュー用に、問題 JSONL から CSV（UTF-8 BOM付き・Excel で開ける）を書き出す。

標準ライブラリのみ。入力は 1 行 1 問の JSON Lines（core の Question 形式: qid / prompt /
choices / answerIndex / explanation / tags / conceptId / angle）。

使い方（データはリポジトリに置いたまま、手元で実行して CSV だけ渡す）:
  python3 tools/export_review_csv.py assets/questions/g_kentei.jsonl --tag ai-draft -o review.csv
  python3 tools/export_review_csv.py assets/questions/info_security.jsonl --id-range 1038 1073 -o review.csv
  python3 tools/export_review_csv.py q.jsonl --ids 0728 0766 0767   # 数字は qid の末尾 4 桁

出力列: id, 観点, 問題文, ア〜エ, 正解, 解説, 判定(空), コメント(空), 根拠(空)
出典欄 sourceRef などの内部情報は意図的に出さない。
"""
import argparse
import csv
import json
import sys

LABELS = "アイウエオカ"


def select(rows, tag=None, id_range=None, ids=None):
    for r in rows:
        qid = str(r.get("qid") or r.get("id") or "")
        num = qid[-4:]
        if tag and tag not in (r.get("tags") or []):
            continue
        if id_range and not (num.isdigit() and id_range[0] <= int(num) <= id_range[1]):
            continue
        if ids and num not in ids:
            continue
        yield r


def to_row(r):
    ch = r.get("choices") or []
    a = r.get("answerIndex")
    cells = [ch[i] if i < len(ch) else "" for i in range(4)]
    ans = LABELS[a] if isinstance(a, int) and 0 <= a < len(LABELS) else ""
    return [str(r.get("qid") or r.get("id") or ""), r.get("angle") or "",
            r.get("prompt") or "", *cells, ans, r.get("explanation") or "", "", "", ""]


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("jsonl")
    ap.add_argument("--tag")
    ap.add_argument("--id-range", nargs=2, type=int, metavar=("FROM", "TO"))
    ap.add_argument("--ids", nargs="+")
    ap.add_argument("-o", "--out", default="-")
    a = ap.parse_args(argv)
    with open(a.jsonl, encoding="utf-8") as f:
        rows = [json.loads(l) for l in f if l.strip().startswith("{")]
    out = sys.stdout if a.out == "-" else open(a.out, "w", encoding="utf-8-sig", newline="")
    w = csv.writer(out)
    w.writerow(["id", "観点", "問題文", "ア", "イ", "ウ", "エ", "正解", "解説", "判定(OK/修正/削除)", "コメント", "根拠"])
    n = 0
    for r in select(rows, a.tag, a.id_range, a.ids):
        w.writerow(to_row(r))
        n += 1
    print(f"{n} 件", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
