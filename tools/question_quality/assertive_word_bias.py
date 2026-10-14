#!/usr/bin/env python3
"""選択肢の「断定語・否定の言い切り」が正解と誤答で偏っていないかを集計する参考スクリプト。

標準ライブラリのみ。入力は JSON Lines（1行1問。拡張子 .json の配列も可）。既定の
フィールド名は choice_length_bias.py と同じ（core の Question モデルに合わせてある）:
  choices(選択肢の配列) / answerIndex(正解の0始まり番号) /
  type(省略時 choice) / disabled(true は除外) / subjectId(カテゴリ)

測り方: 断定語（だけ/のみ/全て/すべて/必ず/常に/一切/全く/まったく/絶対/決して + 拡張語）を
含む選択肢の割合を、正解の選択肢と誤答の選択肢で比べる。誤答にだけ「必ず」「のみ」が
付いていると、内容を知らなくても断定語の有無で正誤が当てられてしまう。
  警告: 含有率の差が --margin pt 以上、かつ両側 Fisher 正確確率検定 p < --alpha。
  （選択肢は問題内で独立ではないので p 値は目安。判断は人が問題文を見て行う）

使い方:
  python3 tools/question_quality/assertive_word_bias.py questions.jsonl [more.jsonl ...]
  python3 tools/question_quality/assertive_word_bias.py q.jsonl --choices-key options --answer-key answer
  python3 tools/question_quality/assertive_word_bias.py q.jsonl --words-file my_words.txt   # 語リストを差し替え
  python3 tools/question_quality/assertive_word_bias.py q.jsonl --add-words 唯一,毎回 --exclude-words 全く
  python3 tools/question_quality/assertive_word_bias.py q.jsonl --negation                  # 否定の言い切りも測る

終了コードは既定で常に 0（CI を止めない）。--strict を付けたときだけ、警告があれば 1。
--annotate で GitHub Actions の ::warning:: 注釈も出す。
"""
import argparse
import json
import sys
from collections import defaultdict
from math import comb

# 基本語（乙4 #172〜#178・情セマネ #18/#19・seisei #117 で使った語）
CORE_WORDS = ["だけ", "のみ", "全て", "すべて", "必ず", "常に", "一切",
              "全く", "まったく", "絶対", "決して"]
# 拡張語（--no-extended で外せる）
EXTENDED_WORDS = ["唯一", "完全に", "全部", "例外なく", "いつも", "無条件",
                  "一律", "常時", "一度も", "二度と"]
# 否定の言い切り（--negation で有効化）
NEGATION_WORDS = ["ではない", "できない", "しない", "ならない", "ありえない",
                  "存在しない", "含まれない", "起こらない", "不可能", "認められない"]
# 語を含んでいても断定にならない定番の語句（照合前に取り除く。--exceptions で追加可）
DEFAULT_EXCEPTIONS = ["非常に", "必ずしも", "絶対値", "絶対温度", "絶対零度", "絶対評価",
                      "絶対参照", "絶対パス", "絶対アドレス", "絶対圧"]


def split_list(s):
    return [w.strip() for w in s.split(",") if w.strip()]


def read_words_file(path):
    words = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#"):
                words.append(line)
    return words


def build_words(a):
    if a.words_file:
        words = read_words_file(a.words_file)
    else:
        words = list(CORE_WORDS)
        if not a.no_extended:
            words += EXTENDED_WORDS
        if a.negation:
            words += NEGATION_WORDS
    words += split_list(a.add_words)
    drop = set(split_list(a.exclude_words))
    out = []
    for w in words:
        if w not in drop and w not in out:
            out.append(w)
    return out


def find_words(text, words, exceptions):
    for ex in exceptions:
        text = text.replace(ex, " ")
    return [w for w in words if w in text]


def iter_rows(path):
    with open(path, encoding="utf-8") as f:
        if path.endswith(".json"):
            data = json.load(f)
            yield from (data if isinstance(data, list) else [])
            return
        for line in f:
            line = line.strip()
            if not line or line.startswith("//"):
                yield None
                continue
            try:
                yield json.loads(line)
            except ValueError:
                yield "json不正"


def load(paths, a, words, exceptions):
    qs, skipped = [], defaultdict(int)
    for path in paths:
        for j in iter_rows(path):
            if j is None:
                continue
            if j == "json不正":
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
                "hits": [find_words(c, words, exceptions) for c in ch],
                "ans": ans,
                "cat": str(j.get(a.category_key, "(なし)")),
            })
    return qs, skipped


def fisher_two_sided(a_hit, a_n, b_hit, b_n):
    """2x2 表（a群: a_hit/a_n、b群: b_hit/b_n）の両側 Fisher 正確確率。"""
    n, k = a_n + b_n, a_hit + b_hit

    def pmf(x):
        return comb(k, x) * comb(n - k, a_n - x) / comb(n, a_n)

    lo, hi = max(0, a_n - (n - k)), min(a_n, k)
    obs = pmf(a_hit)
    return min(1.0, sum(p for p in (pmf(x) for x in range(lo, hi + 1))
                        if p <= obs * (1 + 1e-9)))


def pct(x):
    return "  n/a" if x != x else f"{x * 100:5.1f}%"


def report(title, qs, a):
    c_n = len(qs)
    c_hit = sum(1 for q in qs if q["hits"][q["ans"]])
    w_n = sum(len(q["hits"]) - 1 for q in qs)
    w_hit = sum(1 for q in qs for i, h in enumerate(q["hits"]) if i != q["ans"] and h)
    c_rate = c_hit / c_n if c_n else float("nan")
    w_rate = w_hit / w_n if w_n else float("nan")
    diff = w_rate - c_rate
    p = fisher_two_sided(c_hit, c_n, w_hit, w_n) if c_n and w_n else float("nan")
    print(f"\n## {title}（選択式 {c_n} 問）")
    print(f"- 断定語を含む選択肢: 正解 {c_hit}/{c_n} = {pct(c_rate)} / 誤答 {w_hit}/{w_n} = {pct(w_rate)}"
          f"（誤答 - 正解 = {diff * 100:+.1f}pt、両側 p = {p:.4f}）")
    # 語ごとの出現（正解 / 誤答）
    cnt = defaultdict(lambda: [0, 0])
    for q in qs:
        for i, h in enumerate(q["hits"]):
            for w in h:
                cnt[w][0 if i == q["ans"] else 1] += 1
    if cnt:
        top = sorted(cnt.items(), key=lambda kv: -(kv[1][0] + kv[1][1]))[:a.top]
        print("- 語別（正解/誤答）: " + " ".join(f"{w}:{c}/{x}" for w, (c, x) in top))
    flag = c_n > 0 and w_n > 0 and abs(diff) * 100 >= a.margin and p < a.alpha
    small = c_n < a.min_n
    if flag:
        side = "誤答に偏り（断定語がない選択肢が正解になりやすい）" if diff > 0 \
            else "正解に偏り（断定語がある選択肢が正解になりやすい）"
        print(f"- 判定: 要確認 {side}" + ("（問題数が少なく参考値）" if small else "（是正対象の候補）"))
    else:
        print("- 判定: 目安の範囲内")
    if flag and not small and a.annotate:
        print(f"::warning title=断定語バランス::{title} 誤答 {pct(w_rate).strip()} / 正解 {pct(c_rate).strip()}"
              f"（差 {diff * 100:+.1f}pt, p={p:.4f}）。docs/question_quality_viewpoints.md を参照")
    return flag and not small


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("files", nargs="+", help="問題の JSON Lines（または .json の配列）")
    ap.add_argument("--choices-key", default="choices")
    ap.add_argument("--answer-key", default="answerIndex")
    ap.add_argument("--type-key", default="type")
    ap.add_argument("--category-key", default="subjectId")
    ap.add_argument("--words-file", help="語リスト（1行1語、# はコメント）。基本語+拡張語の代わりに使う")
    ap.add_argument("--add-words", default="", help="追加する語（カンマ区切り）")
    ap.add_argument("--exclude-words", default="", help="除く語（カンマ区切り）")
    ap.add_argument("--exceptions", default="", help="断定にならない語句の追加（カンマ区切り。例: 絶対値）")
    ap.add_argument("--no-extended", action="store_true", help="拡張語を使わず基本語のみ")
    ap.add_argument("--negation", action="store_true", help="否定の言い切り（ではない/できない 等）も数える")
    ap.add_argument("--margin", type=float, default=10.0, help="含有率の差のしきい値(pt)。暫定")
    ap.add_argument("--alpha", type=float, default=0.05, help="両側 Fisher 検定のしきい値。暫定")
    ap.add_argument("--min-n", type=int, default=20, help="これ未満の群は参考値扱い")
    ap.add_argument("--top", type=int, default=8, help="語別の表示件数")
    ap.add_argument("--annotate", action="store_true", help="GitHub Actions の ::warning:: を出す")
    ap.add_argument("--strict", action="store_true", help="警告があれば終了コード 1")
    a = ap.parse_args(argv)

    words = build_words(a)
    exceptions = DEFAULT_EXCEPTIONS + split_list(a.exceptions)
    qs, skipped = load(a.files, a, words, exceptions)
    if not qs:
        print("対象の選択式問題がありません", file=sys.stderr)
        return 0
    print("語リスト: " + " ".join(words))
    if skipped:
        print("除外: " + ", ".join(f"{k} {v}" for k, v in skipped.items()))
    warned = report("全体", qs, a)
    by = defaultdict(list)
    for q in qs:
        by[q["cat"]].append(q)
    if len(by) > 1:
        for cat in sorted(by):
            warned = report(f"{a.category_key}={cat}", by[cat], a) or warned
    return 1 if (a.strict and warned) else 0


if __name__ == "__main__":
    sys.exit(main())
