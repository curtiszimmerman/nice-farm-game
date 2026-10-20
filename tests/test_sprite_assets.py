"""Validate the generated, grid-aligned PNG asset catalog without extra packages."""
import json
import pathlib
import struct
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class SpriteAssets(unittest.TestCase):
    def test_rustic_pack_coverage_and_scale(self):
        base = ROOT / "src/native/art/option3"
        pack = json.loads((base / "pack.json").read_text())
        self.assertEqual(pack["tile_size"], 16)
        current = json.loads((base / pack["sprites"]).read_text())
        original = json.loads((ROOT / "src/native/art/option2/sprites.json").read_text())
        width, height = struct.unpack(">II", (base / pack["atlas"]).read_bytes()[16:24])
        self.assertTrue(original.keys() <= current.keys())
        for name, entry in current.items():
            x, y, w, h = entry["rect"]
            self.assertGreaterEqual(min(x, y), 0, name)
            self.assertLessEqual(x + w, width, name)
            self.assertLessEqual(y + h, height, name)
            if name in original:
                self.assertEqual((w, h), tuple((n + 1) // 2 for n in original[name]["rect"][2:]), name)
            if name.startswith("tile_"):
                self.assertEqual((w, h), (16, 16), name)
            if name.startswith("tree_"):
                self.assertEqual(entry["trunk_tiles"], [1, 2])
                self.assertEqual(entry["canopy_tiles"], [3, h // 16 - 2])

    def test_connected_fences_and_watered_crops(self):
        base = ROOT / "src/native/art/option2"
        manifest = json.loads((base / "sprites.json").read_text())
        for mask in range(16):
            self.assertIn(f"tile_fence_mask{mask}", manifest)
        for crop in ("sprout", "turnip", "bulb"):
            self.assertIn(f"crop_{crop}_wet", manifest)

    def test_atlas_and_tile_contract(self):
        base = ROOT / "src/native/art/option2"
        manifest = json.loads((base / "sprites.json").read_text())
        header = (base / "sprites.png").read_bytes()
        self.assertEqual(header[:8], b"\x89PNG\r\n\x1a\n")
        width, height = struct.unpack(">II", header[16:24])
        self.assertGreater(len(manifest), 150)
        for material in ("plaster", "log", "stone", "shop"):
            for half in ("top", "bottom"):
                self.assertIn(f"tile_{material}_door_{half}", manifest)
        for name, entry in manifest.items():
            x, y, w, h = entry["rect"]
            self.assertGreaterEqual(min(x, y), 0, name)
            self.assertLessEqual(x + w, width, name)
            self.assertLessEqual(y + h, height, name)
            if name.startswith("tile_"):
                self.assertEqual((w, h), (32, 32), name)
            if name.startswith("tree_"):
                self.assertEqual(w, 96, name)
                self.assertIn(h, (128, 160, 192), name)
                self.assertEqual(entry["trunk_tiles"], [1, 2])
                self.assertEqual(entry["canopy_tiles"], [3, h // 32 - 2])

    def test_original_art_is_preserved(self):
        import tarfile
        path = ROOT / "src/native/art/option1/original-art.tar"
        with tarfile.open(path) as archive:
            self.assertIn("src/native/world.gd", archive.getnames())
            self.assertIn("src/native/interior.gd", archive.getnames())


if __name__ == "__main__":
    unittest.main()
