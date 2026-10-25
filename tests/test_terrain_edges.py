"""Validate the finished terrain artwork independently of unfinished stone borders."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from make_sprites16 import Pixels
import terrain_edges16 as art


class TerrainEdges(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sprites = art.sprites(Pixels)

    def test_complete_season_weather_corner_library(self):
        expected = set()
        for material in art.MATERIALS:
            for season in art.SEASONS:
                for weather in art.WEATHERS:
                    for variant in art.VARIANTS:
                        expected.update(f"tile_border_{material}_m{mask}_{season}_{weather}_{variant}" for mask in art.canonical_masks())
                        expected.update(f"border_quarter_{material}_{q}_{shape}_{season}_{weather}_{variant}"
                                        for q in art.QUADRANTS for shape in art.SHAPES)
        expected.update(("plant_overlay_sprout", "plant_overlay_turnip", "plant_overlay_bulb"))
        self.assertEqual(set(self.sprites), expected)
        self.assertEqual(len(self.sprites), 22515)
        for name, image in self.sprites.items():
            expected_size = 8 if name.startswith("border_quarter_") else 16
            self.assertEqual((image.w, image.h), (expected_size, expected_size), name)

    def test_diagonals_change_only_their_own_quarter(self):
        for material in art.MATERIALS:
            for sides, diagonal, corner in ((3, 16, (1, 0)), (6, 32, (1, 1)), (12, 64, (0, 1)), (9, 128, (0, 0))):
                a = art.tile(Pixels, material, sides, "spring", "sunny")
                b = art.tile(Pixels, material, sides | diagonal, "spring", "sunny")
                changed = {(x // 8, y // 8) for y in range(16) for x in range(16) if a.get(x, y) != b.get(x, y)}
                self.assertEqual(changed, {corner}, (material, sides))

    def test_normalized_geometry_and_reproducible_output(self):
        self.assertEqual(len(art.canonical_masks()), 47)
        for raw in range(256):
            self.assertEqual(art.normalize(art.normalize(raw)), art.normalize(raw))
        for material in art.MATERIALS:
            first = art.tile(Pixels, material, 223, "winter", "rainy", 3)
            second = art.tile(Pixels, material, 223, "winter", "rainy", 3)
            self.assertEqual(first.data, second.data)


if __name__ == "__main__":
    unittest.main()
