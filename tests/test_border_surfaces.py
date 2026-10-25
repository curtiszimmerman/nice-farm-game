"""Check material source tiles before they enter either runtime atlas."""
import importlib.util
import os
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from make_sprites16 import Pixels


class BorderSurfaces(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source = ROOT / os.environ.get("BORDER_SURFACE_SOURCE", "scripts/border_surfaces16.py")
        if not source.exists():
            raise AssertionError("The new material surface artwork has not been created")
        spec = importlib.util.spec_from_file_location("border_surfaces16", source)
        cls.art = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = cls.art
        spec.loader.exec_module(cls.art)
        cls.tiles = cls.art.sprites(Pixels)

    def test_all_material_season_weather_variants_exist(self):
        expected = {
            f"tile_border_{material}_fill_{season}_{weather}_{variant}"
            for material in ("paving", "jetty")
            for season in ("spring", "summer", "autumn", "winter")
            for weather in ("sunny", "partly_cloudy", "rainy")
            for variant in range(4)
        }
        self.assertEqual(set(self.tiles), expected)
        for name, tile in self.tiles.items():
            self.assertEqual((tile.w, tile.h), (16, 16), name)
            self.assertTrue(all(tile.get(x, y)[3] == 255 for y in range(16) for x in range(16)), name)

    def test_variants_keep_matching_boundary_construction(self):
        for material in ("paving", "jetty"):
            for season in ("spring", "summer", "autumn", "winter"):
                for weather in ("sunny", "partly_cloudy", "rainy"):
                    tiles = [self.art.surface(Pixels, material, season, weather, v) for v in range(4)]
                    for x, y in [(x, y) for y in range(16) for x in range(16) if x in (0, 15) or y in (0, 15)]:
                        self.assertTrue(all(t.get(x, y) == tiles[0].get(x, y) for t in tiles), (material, season, weather, x, y))

    def test_season_and_weather_are_distinct_and_reproducible(self):
        for material in ("paving", "jetty"):
            states = [bytes(self.art.surface(Pixels, material, s, w).data)
                      for s in ("spring", "summer", "autumn", "winter")
                      for w in ("sunny", "partly_cloudy", "rainy")]
            self.assertEqual(len(set(states)), 12, material)
        self.assertNotEqual(self.tiles["tile_border_paving_fill_spring_sunny_0"].data,
                            self.tiles["tile_border_jetty_fill_spring_sunny_0"].data)
        repeat = self.art.sprites(Pixels)
        self.assertEqual({k: bytes(v.data) for k, v in self.tiles.items()},
                         {k: bytes(v.data) for k, v in repeat.items()})


if __name__ == "__main__":
    unittest.main()
