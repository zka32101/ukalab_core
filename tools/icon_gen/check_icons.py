#!/usr/bin/env python3
"""生成したアイコンの検査（CI用）。失敗したら終了コード 1。

検査:
  - 画像サイズ（1024×1024）と形式
  - 白い文字・シンボルと塗り色のコントラスト（4.5:1 以上）
  - 「うかラボ」・シンボル・試験名が重ならない（余白あり）
  - 要素が端に寄りすぎない（左右・上下に余白）
  - Android adaptive 前景の内容が中央66%以内
  - 最小サイズ版に上段「うかラボ」がない
  - 見分け: 全アイコンの塗り色＋試験名が重複しない
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import icon_gen as ig  # noqa: E402


def lum(c):
    def f(v):
        v /= 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4

    r, g, b = c
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def contrast(a, b):
    la, lb = lum(a), lum(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def box(d):
    return ig.Box(d["name"], d["x0"], d["y0"], d["x1"], d["y1"])


def check(spec_path: Path, out: Path) -> list[str]:
    errors: list[str] = []
    certs, _ = ig.load_palette()
    specs = json.loads(spec_path.read_text(encoding="utf-8"))
    layout = json.loads((out / "layout.json").read_text(encoding="utf-8"))
    seen = {}
    margin = int(ig.SIZE * 0.02)
    edge = int(ig.SIZE * 0.03)

    for s in specs:
        cid = s["id"]
        for suffix in ("1024", "small_1024", "fg", "bg"):
            p = out / f"{cid}_{suffix}.png"
            if not p.exists():
                errors.append(f"{cid}: {p.name} がない")
                continue
            im = Image.open(p)
            if im.size != (ig.SIZE, ig.SIZE):
                errors.append(f"{cid}: {p.name} のサイズが {im.size}")
        fill = certs[cid]
        c = contrast((255, 255, 255), fill)
        if c < 4.5:
            errors.append(f"{cid}: 白と塗り色のコントラスト {c:.2f} < 4.5")

        for variant in ("full", "small"):
            boxes = [box(b) for b in layout[cid][variant]]
            for i, a in enumerate(boxes):
                for b in boxes[i + 1 :]:
                    if a.intersects(b, margin):
                        errors.append(f"{cid}/{variant}: {a.name} と {b.name} が重なる／近すぎる")
                if a.x0 < edge or a.y0 < edge or a.x1 > ig.SIZE - edge or a.y1 > ig.SIZE - edge:
                    errors.append(f"{cid}/{variant}: {a.name} が端に近すぎる")
        names = {b["name"] for b in layout[cid]["small"]}
        if "title" in names:
            errors.append(f"{cid}: 最小サイズ版に上段「うかラボ」が残っている")

        lo = (ig.SIZE - ig.SIZE * ig.ADAPTIVE_SAFE) / 2 - 2
        hi = ig.SIZE - lo
        for b in layout[cid]["adaptive"]:
            if b["x0"] < lo or b["y0"] < lo or b["x1"] > hi or b["y1"] > hi:
                errors.append(f"{cid}: adaptive 前景の {b['name']} が中央66%をはみ出す")
        # 前景の実画像でも確認（透明でない画素の範囲）
        fg = Image.open(out / f"{cid}_fg.png").convert("RGBA")
        bb = fg.getchannel("A").getbbox()
        if bb and (bb[0] < lo or bb[1] < lo or bb[2] > hi or bb[3] > hi):
            errors.append(f"{cid}: adaptive 前景の画素が中央66%をはみ出す {bb}")

        key = (fill, s["short"])
        if key in seen:
            errors.append(f"{cid}: {seen[key]} と色・試験名が同じ")
        seen[key] = cid
    return errors


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--spec", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args(argv)
    errs = check(Path(a.spec), Path(a.out))
    for e in errs:
        print("NG:", e)
    print("OK" if not errs else f"{len(errs)} 件の問題")
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
