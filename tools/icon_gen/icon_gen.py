#!/usr/bin/env python3
"""うかラボ アプリアイコン生成（共通デザイン仕様 v0.4 §5 / 決定75）。

入力: 試験名（短縮）、シンボル SVG（白・viewBox -50 -50 100 100）、資格ID（または分野）。
出力（1資格あたり）:
  <id>_1024.png          1024px の角なし正方形（上段「うかラボ」／中央シンボル／下部に試験名）
  <id>_fg.png            Android adaptive 前景（透明。内容は中央66%以内）
  <id>_bg.png            Android adaptive 背景（分野色の単色）
  <id>_small_1024.png    最小サイズ用（上段を省略しシンボルを拡大）

使い方:
  python tools/icon_gen/icon_gen.py --spec tools/icon_gen/specs/sample.json --out build/icons
  python tools/icon_gen/check_icons.py --spec tools/icon_gen/specs/sample.json --out build/icons

AI 画像は使わない。試験団体のロゴ・「公式」「認定」の文字は入れない。
色は lib/ui/theme/ukalab_palette.dart から読む（二重管理しない）。
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

try:
    import pymupdf  # PyMuPDF（SVG の描画に使う）
except ImportError:  # 古い名前
    import fitz as pymupdf  # type: ignore

ROOT = Path(__file__).resolve().parents[2]
PALETTE_DART = ROOT / "lib" / "ui" / "theme" / "ukalab_palette.dart"
SYMBOL_DIR = Path(__file__).resolve().parent / "symbols"

SIZE = 1024
TITLE = "うかラボ"

# レイアウト（アイコン幅=100 に対する割合。共通デザイン仕様 v0.4 §5）
TITLE_H = 0.15  # 「うかラボ」の高さ
MARK_SCALE = 1.25  # 桜の大きさ（文字の高さに対する倍率）
MARK_GAP = 0.025  # 桜とタイトルの間（SIZE比）
SYMBOL_W = 0.40  # シンボルの幅
IMAGE_SYMBOL_W = 0.66  # 中央に差し込む画像（横長の絵）の幅。シンボルより広く取る
NAME_H = 0.19  # 試験名の高さ
SMALL_SYMBOL_W = 0.52  # 最小サイズ版のシンボル幅
ADAPTIVE_SAFE = 0.56  # adaptive 前景を収める中央の割合（円形マスクでも上段・下段の文字が欠けない値。0.66 だと円形で欠ける）

FONT_CANDIDATES = [
    "C:/Windows/Fonts/YuGothB.ttc",
    "C:/Windows/Fonts/meiryob.ttc",
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc",
    "/usr/share/fonts/truetype/noto/NotoSansCJK-Bold.ttc",
    "/usr/share/fonts/noto-cjk/NotoSansCJK-Bold.ttc",
    "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc",
]


# ---- 色（palette から読む） ---------------------------------------------------

def _hex(s: str) -> tuple[int, int, int]:
    s = s.upper().replace("0XFF", "")
    return int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16)


def load_palette(path: Path = PALETTE_DART) -> tuple[dict[str, tuple[int, int, int]], dict[str, str]]:
    """(資格ID → ライトの塗り色, 資格ID → 分野名) を ukalab_palette.dart から読む。"""
    text = path.read_text(encoding="utf-8")
    certs: dict[str, tuple[int, int, int]] = {}
    fields: dict[str, str] = {}
    pat = re.compile(
        r"\w+\('([a-z0-9_]+)',\s*'[^']*',\s*UkalabField\.(\w+),\s*Color\(0x([0-9A-Fa-f]{8})\),\s*Color\(0x[0-9A-Fa-f]{8}\)\)"
    )
    for m in pat.finditer(text):
        certs[m.group(1)] = _hex("0x" + m.group(3))
        fields[m.group(1)] = m.group(2)
    if not certs:
        raise RuntimeError(f"資格色を読めませんでした: {path}")
    return certs, fields


# ---- 部品 ---------------------------------------------------------------------

def find_font(explicit: str | None = None) -> str:
    for p in ([explicit] if explicit else []) + FONT_CANDIDATES:
        if p and os.path.exists(p):
            return p
    raise RuntimeError("日本語の太字フォントが見つかりません。--font で指定してください（例: NotoSansCJK-Bold.ttc）")


def render_symbol(svg_path: Path, width_px: int, bg: tuple[int, int, int]) -> Image.Image:
    """白いシンボル SVG を、幅 width_px の透明 PNG にする。__BG__ は背景色に置き換える。"""
    svg = svg_path.read_text(encoding="utf-8").replace("__BG__", "#%02X%02X%02X" % bg)
    svg = re.sub(r'<svg ', f'<svg width="{width_px}" height="{width_px}" ', svg, count=1)
    doc = pymupdf.open(stream=svg.encode("utf-8"), filetype="svg")
    pix = doc[0].get_pixmap(alpha=True)
    return Image.frombytes("RGBA", (pix.width, pix.height), pix.samples)


def render_symbol_image(png_path: Path) -> Image.Image:
    """単色背景に白で描かれた絵（Canva 等で作った PNG）から、白いシルエット（透明背景）を取り出す。

    背景色は四隅の中央値とみなし、背景→白 の度合いを不透明度にする。
    出力は RGBA（RGB は白、A がシルエット）。余白は呼び出し側で切る。
    """
    im = Image.open(png_path).convert("RGB")
    w, h = im.size
    corners = [im.getpixel(p) for p in ((2, 2), (w - 3, 2), (2, h - 3), (w - 3, h - 3))]
    bg = tuple(sorted(c[i] for c in corners)[len(corners) // 2] for i in range(3))
    px = im.load()
    out = Image.new("RGBA", im.size, (255, 255, 255, 0))
    op = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            a = 0.0
            n = 0
            for c, c0 in zip((r, g, b), bg):
                if c0 < 250:
                    a += max(0.0, min(1.0, (c - c0) / (255 - c0)))
                    n += 1
            a = a / n if n else 0.0
            a = 0.0 if a < 0.08 else min(1.0, (a - 0.08) / 0.84)  # 圧縮ノイズを落とす
            if a:
                op[x, y] = (255, 255, 255, int(a * 255))
    return out


def fit_text(draw: ImageDraw.ImageDraw, text: str, font_path: str, target_h: int, max_w: int):
    """高さ target_h を目標に、幅が max_w を超えるなら縮める。(font, bbox) を返す。"""
    size = target_h
    while size > 8:
        font = ImageFont.truetype(font_path, size, index=0)
        l, t, r, b = draw.textbbox((0, 0), text, font=font)
        if (r - l) <= max_w and (b - t) <= target_h * 1.15:
            return font, (l, t, r, b)
        size -= 2
    font = ImageFont.truetype(font_path, 8, index=0)
    return font, draw.textbbox((0, 0), text, font=font)


@dataclass
class Box:
    name: str
    x0: int
    y0: int
    x1: int
    y1: int

    def intersects(self, o: "Box", margin: int = 0) -> bool:
        return not (
            self.x1 + margin <= o.x0 or o.x1 + margin <= self.x0 or self.y1 + margin <= o.y0 or o.y1 + margin <= self.y0
        )


@dataclass
class Layout:
    boxes: list[Box]
    image: Image.Image  # 内容だけ（透明背景）


def _compose(short: str, symbol: Path, fill: tuple[int, int, int], font_path: str, small: bool) -> Layout:
    """内容（文字・シンボル）を透明キャンバスに配置する。"""
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(canvas)
    white = (255, 255, 255, 255)
    boxes: list[Box] = []
    max_w = int(SIZE * 0.88)

    # 試験名（下部）
    name_h = int(SIZE * NAME_H)
    nf, nb = fit_text(d, short, font_path, name_h, max_w)
    nw, nh = nb[2] - nb[0], nb[3] - nb[1]
    name_bottom = int(SIZE * 0.93)
    nx = (SIZE - nw) // 2 - nb[0]
    ny = name_bottom - nh - nb[1]
    d.text((nx, ny), short, font=nf, fill=white)
    boxes.append(Box("name", nx + nb[0], ny + nb[1], nx + nb[2], ny + nb[3]))

    # 上段「うかラボ」（最小サイズ版では省略）。左に合格の桜（シリーズ共通のマーク）を添える
    title_bottom = 0
    if not small:
        mark_h = int(SIZE * TITLE_H * MARK_SCALE)
        mark_gap = int(SIZE * MARK_GAP)
        tf, tb = fit_text(d, TITLE, font_path, int(SIZE * TITLE_H), max_w - mark_h - mark_gap)
        tw, th = tb[2] - tb[0], tb[3] - tb[1]
        group_w = mark_h + mark_gap + tw
        gx = (SIZE - group_w) // 2  # 桜＋タイトルをまとめて中央に置く
        ty0 = int(SIZE * 0.07)
        tx = gx + mark_h + mark_gap - tb[0]
        ty = ty0 - tb[1]
        d.text((tx, ty), TITLE, font=tf, fill=white)
        boxes.append(Box("title", tx + tb[0], ty + tb[1], tx + tb[2], ty + tb[3]))
        title_bottom = ty + tb[3]
        # 桜は文字の縦中央にそろえる
        sak = render_symbol(SYMBOL_DIR / "sakura.svg", SIZE, fill)
        sb = sak.getbbox() or (0, 0, sak.width, sak.height)
        sak = sak.crop(sb)
        k = mark_h / max(sak.width, sak.height)
        sak = sak.resize((max(1, int(sak.width * k)), max(1, int(sak.height * k))), Image.LANCZOS)
        my = ty + tb[1] + (th - sak.height) // 2
        canvas.alpha_composite(sak, (gx, my))
        boxes.append(Box("mark", gx, my, gx + sak.width, my + sak.height))
        title_bottom = max(title_bottom, my + sak.height)

    # シンボル（上段と試験名の間の中央）。余白を除いた見た目の幅が目標になるよう拡縮する
    is_image = symbol.suffix.lower() == '.png'
    sw = int(SIZE * (SMALL_SYMBOL_W if small else (IMAGE_SYMBOL_W if is_image else SYMBOL_W)))
    top = (title_bottom if title_bottom else int(SIZE * 0.05)) + int(SIZE * 0.04)
    bottom = boxes[0].y0 - int(SIZE * 0.04)
    avail_h = bottom - top
    raw = render_symbol_image(symbol) if symbol.suffix.lower() == '.png' else render_symbol(symbol, SIZE, fill)  # 大きく描いてから余白を切る
    bb = raw.getbbox() or (0, 0, raw.width, raw.height)
    raw = raw.crop(bb)
    scale = min(sw / raw.width, (avail_h * 0.92) / raw.height)
    sym = raw.resize((max(1, int(raw.width * scale)), max(1, int(raw.height * scale))), Image.LANCZOS)
    sy = top + (avail_h - sym.height) // 2
    sx = (SIZE - sym.width) // 2
    canvas.alpha_composite(sym, (sx, sy))
    boxes.append(Box("symbol", sx, sy, sx + sym.width, sy + sym.height))
    return Layout(boxes, canvas)


def _gradient(fill: tuple[int, int, int]) -> Image.Image:
    """分野色の塗り＋ごく弱い縦グラデ（上 白14% → 下 黒10%）。"""
    base = Image.new("RGB", (SIZE, SIZE), fill)
    over = Image.new("RGBA", (SIZE, SIZE))
    px = over.load()
    for y in range(SIZE):
        t = y / (SIZE - 1)
        if t < 0.5:
            a = int(255 * 0.14 * (1 - t * 2))
            c = (255, 255, 255, a)
        else:
            a = int(255 * 0.10 * ((t - 0.5) * 2))
            c = (0, 0, 0, a)
        for x in range(SIZE):
            px[x, y] = c
    return Image.alpha_composite(base.convert("RGBA"), over).convert("RGB")


def build_one(spec: dict, certs, font_path: str, out: Path) -> dict:
    cid = spec["id"]
    if cid not in certs:
        raise KeyError(f"未知の資格ID: {cid}")
    fill = certs[cid]
    if spec.get("symbol_image"):
        symbol = Path(spec["symbol_image"])  # 中央に差し込む画像（PNG）。絶対パスか、実行場所からの相対
    else:
        symbol = SYMBOL_DIR / f"{spec['symbol']}.svg"
    if not symbol.exists():
        raise FileNotFoundError(symbol)
    result = {}

    full = _compose(spec["short"], symbol, fill, font_path, small=False)
    bg = _gradient(fill)
    img = bg.convert("RGBA")
    img.alpha_composite(full.image)
    img.convert("RGB").save(out / f"{cid}_1024.png")
    result["full"] = full.boxes

    small = _compose(spec["short"], symbol, fill, font_path, small=True)
    img2 = bg.convert("RGBA")
    img2.alpha_composite(small.image)
    img2.convert("RGB").save(out / f"{cid}_small_1024.png")
    result["small"] = small.boxes

    # Android adaptive: 前景は中央66%以内、背景は分野色の単色
    inner = int(SIZE * ADAPTIVE_SAFE)
    fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    scaled = full.image.resize((inner, inner), Image.LANCZOS)
    off = (SIZE - inner) // 2
    fg.alpha_composite(scaled, (off, off))
    fg.save(out / f"{cid}_fg.png")
    Image.new("RGB", (SIZE, SIZE), fill).save(out / f"{cid}_bg.png")
    k = ADAPTIVE_SAFE
    result["adaptive"] = [
        Box(b.name, int(off + b.x0 * k), int(off + b.y0 * k), int(off + b.x1 * k), int(off + b.y1 * k))
        for b in full.boxes
    ]
    return result


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--spec", required=True, help="アイコン定義の JSON")
    ap.add_argument("--out", required=True, help="出力フォルダ")
    ap.add_argument("--font", help="日本語の太字フォント（ttf/ttc）")
    a = ap.parse_args(argv)

    certs, _ = load_palette()
    font = find_font(a.font)
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    specs = json.loads(Path(a.spec).read_text(encoding="utf-8"))
    layouts = {}
    for s in specs:
        layouts[s["id"]] = build_one(s, certs, font, out)
        print("生成:", s["id"], s["short"])
    # 配置の記録（check_icons.py が使う）
    dump = {
        cid: {k: [b.__dict__ for b in v] for k, v in lay.items()} for cid, lay in layouts.items()
    }
    (out / "layout.json").write_text(json.dumps(dump, ensure_ascii=False, indent=1), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
