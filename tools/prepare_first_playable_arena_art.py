"""Prepare exact world-size raster terrain from the approved M1 source art.

The source image is 1254 px square. Baking it once at the ArenaDefinition's
2560 x 2560 world size removes runtime fractional scaling from the scrolling
camera path, avoiding fine seams or exposed backdrop slivers while retaining
the approved arena composition.
"""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art" / "arena" / "shopping_center" / "parking_lot_background.png"
OUTPUT = ROOT / "art" / "arena" / "shopping_center" / "parking_lot_2560.png"
WORLD_SIZE = (2560, 2560)


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    terrain = source.resize(WORLD_SIZE, Image.Resampling.NEAREST)
    terrain.save(OUTPUT)
    print(f"Prepared {OUTPUT.relative_to(ROOT)} at {terrain.size[0]} x {terrain.size[1]} px")


if __name__ == "__main__":
    main()
