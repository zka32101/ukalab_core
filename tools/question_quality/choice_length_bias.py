#!/usr/bin/env python3
"""選択式問題で「最も長い選択肢が正解になりがち」かを集計する参考スクリプト。

標準ライブラリのみ。入力は JSON Lines（1行1問）。既定のフィールド名は
core の Question モデル（lib/question/question.dart）に合わせてある:
  choices(選択肢の配列) / answerIndex(正解の0始まり番号) /
  type(省略時 choice) / disabled(true は除外) / subjectId(カテゴリ)

使い方:
  python3 tools/question_quality/choice_length_bias.py questions.jsonl [more.jsonl ...]
  python3 tools/question_quality/choice_length_bias.py q.jsonl --category-key topicId
  python3 tools/question_quality/choice_length_bias.py q.jsonl --choices-key options --answer-key answer

判定の目安（しきい値は暫定。docs/question_quality_viewpoints.md 参照）:
  期待値より --margin ポイント超、または片側 p < --alpha なら「要確認」。
終了コードは常に 0（CI を止めない。人間が読んで判断する用途）。
"""
import argparse
import json
import statistics
import sys
from collections import defaultdict
from math import fsum


def load(paths, a):
    qs, skipped = [], defaultdict(int)
    for path in paths:
        with open(path, encoding="utf-8") as f:
            for ln, line in enumerate(f, 1):
                line = line.strip()
                if not line or line.startswith("//"):
                    continue
                try:
                    j = json.loads(line)
                except ValueError:
                    skipped["json不正"] += 1
                    continue
                if not isinstance(j, dict):
                    skipped["オブジェクトでない"] += 1
                    continue
                if j.get(a.type_key, "choice") != "choice":
                    skipped["選択式以外"] += 1
                    continue
                if j.get("disabled") is True:
                    skipped["disabled"] += 1
                    continue
                ch, ans = j.get(a.choices_key), j.get(a.answer_key)
                if (not isinstance(ch, list) or len(ch) < 2 or
                        not all(isinstance(c, str) for c in ch) or
                        not isinstance(ans, int) or isinstance(ans, bool) or
                        not 0 <= ans < len(ch)):
                    skipped["選択肢/正解番号が不正"] += 1
                    continue
                qs.append({
                    "n": len(ch), "ans": ans,
                    "len": [len(c.strip()) for c in ch],
                    "cat": str(j.get(a.category_key, "(なし)")),
                })
    return qs, skipped


def poisson_binomial_sf(ps, k):
    """独立だが確率が異なるベルヌーイ試行で、成功が k 回以上になる確率（厳密DP）。"""
    dp = [1.0]
    for p in ps:
        nxt = [0.0] * (len(dp) + 1)
        for i, v in enumerate(dp):
            nxt[i] += v * (1 - p)
            nxt[i + 1] += v * p
        dp = nxt
    return min(1.0, fsum(dp[k:]))


def extreme_stats(qs, pick):
    """pick は max か min。戻り値は集計 dict。"""
    uniq_n = uniq_hit = ties = 0
    share_hit = 0.0  # 同率は正解が含まれていれば 1/同率数 を加算（按分）
    expected = 0.0   # 期待値は 1/n の合計（按分・除外のどちらでも同じ）
    ps = []
    for q in qs:
        ext = pick(q["len"])
        who = [i for i, l in enumerate(q["len"]) if l == ext]
        expected += 1 / q["n"]
        if len(who) == 1:
            uniq_n += 1
            ps.append(1 / q["n"])
            if who[0] == q["ans"]:
                uniq_hit += 1
                share_hit += 1
        else:
            ties += 1
            if q["ans"] in who:
                share_hit += 1 / len(who)
    n = len(qs)
    # 除外方式の期待値: 同率でない問題だけで 1/n を合計
    exp_uniq = fsum(ps)
    return {
        "uniq_n": uniq_n, "uniq_hit": uniq_hit, "ties": ties,
        "excl_rate": uniq_hit / uniq_n if uniq_n else float("nan"),
        "excl_exp": exp_uniq / uniq_n if uniq_n else float("nan"),
        "share_rate": share_hit / n if n else float("nan"),
        "share_exp": expected / n if n else float("nan"),
        "p": poisson_binomial_sf(ps, uniq_hit) if uniq_n else float("nan"),
    }


def median_ratio(qs):
    r = []
    for q in qs:
        others = [l for i, l in enumerate(q["len"]) if i != q["ans"]]
        m = statistics.mean(others)
        if m > 0:
            r.append(q["len"][q["ans"]] / m)
    return statistics.median(r) if r else float("nan")


def position_counts(qs, labels):
    cnt = defaultdict(int)
    exp = defaultdict(float)
    for q in qs:
        cnt[q["ans"]] += 1
        for i in range(q["n"]):
            exp[i] += 1 / q["n"]
    return [(labels[i] if i < len(labels) else str(i + 1), cnt[i], exp[i])
            for i in range(max(exp) + 1)] if exp else []


def pct(x):
    return "  n/a" if x != x else f"{x * 100:5.1f}%"


def report(title, qs, a):
    longest, shortest = extreme_stats(qs, max), extreme_stats(qs, min)
    print(f"\n## {title}（選択式 {len(qs)} 問）")
    for name, s in (("最長が正解", longest), ("最短が正解", shortest)):
        print(f"- {name}: 同率除外 {s['uniq_hit']}/{s['uniq_n']} = {pct(s['excl_rate'])}"
              f"（期待 {pct(s['excl_exp'])}、差 {(s['excl_rate'] - s['excl_exp']) * 100:+.1f}pt）"
              f" / 按分 {pct(s['share_rate'])}（期待 {pct(s['share_exp'])}）"
              f" / 同率 {s['ties']} 問 / 片側 p = {s['p']:.4f}")
    print(f"- 正解長 / 他選択肢平均長 の中央値: {median_ratio(qs):.2f}（1.00 付近なら手がかりなし）")
    pos = position_counts(qs, a.labels)
    print("- 正解位置: " + " ".join(f"{l}:{c}(期待{e:.1f})" for l, c, e in pos))
    flag = (longest["uniq_n"] > 0 and
            (longest["excl_rate"] - longest["excl_exp"] > a.margin / 100 or longest["p"] < a.alpha))
    small = len(qs) < a.min_n
    if flag:
        print("- 判定: 要確認" + ("（問題数が少なく参考値）" if small else "（是正対象の候補）"))
    else:
        print("- 判定: 目安の範囲内")
    return flag and not small


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("files", nargs="+", help="問題の JSON Lines")
    ap.add_argument("--choices-key", default="choices")
    ap.add_argument("--answer-key", default="answerIndex")
    ap.add_argument("--type-key", default="type")
    ap.add_argument("--category-key", default="subjectId")
    ap.add_argument("--labels", default="アイウエオカキク", help="正解位置の表示ラベル（1文字ずつ）")
    ap.add_argument("--margin", type=float, default=10.0, help="期待値からの乖離のしきい値(pt)。暫定")
    ap.add_argument("--alpha", type=float, default=0.01, help="片側二項検定のしきい値。暫定")
    ap.add_argument("--min-n", type=int, default=20, help="これ未満の群は参考値扱い")
    a = ap.parse_args(argv)

    qs, skipped = load(a.files, a)
    if not qs:
        print("対象の選択式問題がありません", file=sys.stderr)
        return 0
    if skipped:
        print("除外: " + ", ".join(f"{k} {v}" for k, v in skipped.items()))
    report("全体", qs, a)
    by = defaultdict(list)
    for q in qs:
        by[q["cat"]].append(q)
    if len(by) > 1:
        for cat in sorted(by):
            report(f"{a.category_key}={cat}", by[cat], a)
    return 0


if __name__ == "__main__":
    sys.exit(main())
