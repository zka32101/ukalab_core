import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_icons  # noqa: E402
import icon_gen  # noqa: E402

SPEC = Path(__file__).resolve().parent / "specs" / "sample.json"


class IconGenTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.out = Path(cls.tmp.name)
        rc = icon_gen.main(["--spec", str(SPEC), "--out", str(cls.out)])
        assert rc == 0

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def test_palette_is_read_from_dart(self):
        certs, fields = icon_gen.load_palette()
        self.assertEqual(len(certs), 17)
        self.assertEqual(certs["g_kentei"], (0x6D, 0x4A, 0xD8))
        self.assertEqual(fields["g_kentei"], "ai")

    def test_generated_icons_pass_all_checks(self):
        self.assertEqual(check_icons.check(SPEC, self.out), [])

    def test_four_files_per_icon(self):
        for s in json.loads(SPEC.read_text(encoding="utf-8")):
            for suf in ("1024", "small_1024", "fg", "bg"):
                self.assertTrue((self.out / f"{s['id']}_{suf}.png").exists(), suf)

    def test_small_version_has_no_title(self):
        lay = json.loads((self.out / "layout.json").read_text(encoding="utf-8"))
        for v in lay.values():
            self.assertNotIn("title", {b["name"] for b in v["small"]})
            self.assertIn("title", {b["name"] for b in v["full"]})

    def test_adaptive_foreground_is_inside_center_66_percent(self):
        from PIL import Image

        lo = (icon_gen.SIZE - icon_gen.SIZE * icon_gen.ADAPTIVE_SAFE) / 2 - 2
        for s in json.loads(SPEC.read_text(encoding="utf-8")):
            bb = Image.open(self.out / f"{s['id']}_fg.png").convert("RGBA").getchannel("A").getbbox()
            self.assertGreaterEqual(bb[0], lo)
            self.assertLessEqual(bb[2], icon_gen.SIZE - lo)

    def test_check_detects_overlap(self):
        lay_path = self.out / "layout.json"
        original = lay_path.read_text(encoding="utf-8")
        try:
            lay = json.loads(original)
            first = next(iter(lay))
            names = {b["name"]: b for b in lay[first]["full"]}
            # シンボルを試験名の上に重ねる
            names["symbol"]["y1"] = names["name"]["y0"] + 20
            lay_path.write_text(json.dumps(lay), encoding="utf-8")
            errs = check_icons.check(SPEC, self.out)
            self.assertTrue(any("重なる" in e for e in errs), errs)
        finally:
            lay_path.write_text(original, encoding="utf-8")

    def test_check_detects_low_contrast(self):
        # 白との比が 4.5 未満になる色は、検査で失敗する
        self.assertLess(check_icons.contrast((255, 255, 255), (245, 196, 0)), 4.5)
        self.assertGreaterEqual(check_icons.contrast((255, 255, 255), (0x6D, 0x4A, 0xD8)), 4.5)

    def test_unknown_cert_is_an_error(self):
        spec = Path(self.tmp.name) / "bad.json"
        spec.write_text(json.dumps([{"id": "nope", "short": "x", "symbol": "flask"}]), encoding="utf-8")
        with self.assertRaises(KeyError):
            icon_gen.main(["--spec", str(spec), "--out", str(self.out / "bad")])


if __name__ == "__main__":
    unittest.main()

class UkalabAppsSpecTest(unittest.TestCase):
    """実際のアプリ用の定義（specs/ukalab_apps.json）が、そのまま生成・検査を通る。"""

    def test_apps_spec_passes_all_checks(self):
        import tempfile
        spec = Path(__file__).resolve().parent / "specs" / "ukalab_apps.json"
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(icon_gen.main(["--spec", str(spec), "--out", tmp]), 0)
            self.assertEqual(check_icons.check(spec, Path(tmp)), [])

