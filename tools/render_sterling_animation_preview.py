"""Render a non-shipping contact sheet from Sterling's compiled gameplay atlas.

Run from the repository root after assembling the sheet:
    <python> tools/render_sterling_animation_preview.py --output <path>

The result is a review artifact only.  It deliberately reads the exact compiled
PNG that Godot consumes, rather than rebuilding frames from a second source.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
CELL = 64
SCALE = 2
DIRECTIONS = ("N", "NE", "E", "SE", "S", "SW", "W", "NW")
ROWS = (
    ("Idle 0", 0), ("Idle 1", 1), ("Idle 2", 2),
    ("Run 0", 3), ("Run 1", 4), ("Run 2", 5),
    ("Run 3", 6), ("Run 4", 7), ("Run 5", 8),
    ("Basic R", 9), ("Basic L", 10), ("Hurt", 11),
    ("Death 0", 12), ("Death 1", 13), ("Death 2", 14), ("Death 3", 15),
)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    source = Image.open(ROOT / "art/characters/sterling/sterling_sheet.png").convert("RGBA")
    tile = CELL * SCALE
    label_width = 86
    header_height = 38
    canvas = Image.new("RGBA", (label_width + tile * len(DIRECTIONS), header_height + tile * len(ROWS)), (8, 14, 26, 255))
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.load_default()

    for column, direction in enumerate(DIRECTIONS):
        x = label_width + column * tile
        draw.text((x + tile // 2 - 8, 12), direction, fill=(190, 216, 245, 255), font=font)
    for row_index, (label, sheet_row) in enumerate(ROWS):
        y = header_height + row_index * tile
        draw.line((0, y, canvas.width, y), fill=(23, 41, 66, 255))
        draw.text((8, y + tile // 2 - 5), label, fill=(156, 183, 218, 255), font=font)
        for column in range(len(DIRECTIONS)):
            frame = source.crop((column * CELL, sheet_row * CELL, (column + 1) * CELL, (sheet_row + 1) * CELL))
            frame = frame.resize((tile, tile), Image.Resampling.NEAREST)
            x = label_width + column * tile
            canvas.alpha_composite(frame, (x, y))

    args.output.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(args.output)
    print(f"Wrote Sterling animation preview: {args.output}")


if __name__ == "__main__":
    main()
