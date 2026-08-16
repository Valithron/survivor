"""Normalize approved Survivor art sources into deterministic sprite sheets.

The sources are retained under art/source.  This small tool removes their magenta
chroma key, snaps them to the 64 px gameplay template, and assembles the exact
animation rows used by the player and ordinary-zombie visual scenes. It deliberately uses
nearest-neighbour transforms and a limited palette so the shipped files are
native raster pixel-art assets, not runtime-drawn placeholders.

Run from the repository root with the bundled Python:
    <python> tools/assemble_prototype_sprite_sheets.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageEnhance, ImageOps


ROOT = Path(__file__).resolve().parents[1]
CELL = 64
DIRECTIONS = ("n", "ne", "e", "se", "s", "sw", "w", "nw")


def _load_chromakey_source(path: Path) -> Image.Image:
    """Return a tightly-cropped RGBA image after removing #ff00ff."""
    source = Image.open(path).convert("RGBA")
    pixels = source.load()
    for y in range(source.height):
        for x in range(source.width):
            red, green, blue, alpha = pixels[x, y]
            if red >= 210 and blue >= 150 and green <= 115:
                pixels[x, y] = (red, green, blue, 0)
            elif alpha:
                pixels[x, y] = (red, green, blue, 255)
    bounds = source.getbbox()
    if bounds is None:
        raise ValueError(f"No non-chroma pixels found in {path}")
    return source.crop(bounds)


def _load_facing_atlas(path: Path) -> dict[str, Image.Image]:
    """Split the approved five-facing Sterling atlas into named master poses."""
    atlas = Image.open(path).convert("RGBA")
    facings = ("n", "ne", "e", "se", "s")
    masters: dict[str, Image.Image] = {}
    for index, direction in enumerate(facings):
        left = atlas.width * index // len(facings)
        right = atlas.width * (index + 1) // len(facings)
        panel = atlas.crop((left, 0, right, atlas.height))
        pixels = panel.load()
        for y in range(panel.height):
            for x in range(panel.width):
                red, green, blue, alpha = pixels[x, y]
                if red >= 210 and blue >= 150 and green <= 115:
                    pixels[x, y] = (red, green, blue, 0)
                elif alpha:
                    pixels[x, y] = (red, green, blue, 255)
        bounds = panel.getbbox()
        if bounds is None:
            raise ValueError(f"No {direction} facing found in {path}")
        masters[direction] = panel.crop(bounds)
    masters["sw"] = ImageOps.mirror(masters["se"])
    masters["w"] = ImageOps.mirror(masters["e"])
    masters["nw"] = ImageOps.mirror(masters["ne"])
    return masters


def _fit_to_anchor(source: Image.Image, max_width: int, max_height: int) -> Image.Image:
    """Scale a source to a transparent 64 px cell with a fixed foot anchor."""
    scale = min(max_width / source.width, max_height / source.height)
    size = (max(1, round(source.width * scale)), max(1, round(source.height * scale)))
    scaled = source.resize(size, Image.Resampling.NEAREST)
    # Palette reduction happens after normalisation, retaining a clear outline
    # while avoiding excessive near-duplicate colors from the source render.
    alpha = scaled.getchannel("A")
    rgb = scaled.convert("RGB").quantize(colors=48, method=Image.Quantize.MEDIANCUT).convert("RGBA")
    rgb.putalpha(alpha)
    canvas = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    canvas.alpha_composite(rgb, ((CELL - scaled.width) // 2, CELL - 2 - scaled.height))
    return canvas


def _offset(image: Image.Image, x_offset: int = 0, y_offset: int = 0) -> Image.Image:
    result = Image.new("RGBA", image.size, (0, 0, 0, 0))
    result.alpha_composite(image, (x_offset, y_offset))
    return result


def _direction_variant(base: Image.Image, direction: str) -> Image.Image:
    """Derive aligned eight-direction variants from the approved 3/4 source.

    Left-compatible facings mirror as mandated by the art contract. Northward
    facings use a restrained darkened treatment to keep the read distinct at
    Prototype scale without adding a different character design.
    """
    variant = base
    if direction in {"w", "sw", "nw"}:
        variant = ImageOps.mirror(variant)
    if direction in {"n", "ne", "nw"}:
        variant = ImageEnhance.Brightness(variant).enhance(0.78)
    if direction in {"e", "w"}:
        variant = _offset(variant, 0, 1)
    return variant


def _muzzle_flash(frame: Image.Image, direction: str, strength: int) -> Image.Image:
    """Stamp a tiny raster flash in the aim direction for basic/attack frames."""
    vectors = {
        "n": (0, -1), "ne": (1, -1), "e": (1, 0), "se": (1, 1),
        "s": (0, 1), "sw": (-1, 1), "w": (-1, 0), "nw": (-1, -1),
    }
    dx, dy = vectors[direction]
    output = frame.copy()
    center_x = 32 + dx * 20
    center_y = 31 + dy * 11
    points = [(center_x, center_y)]
    if strength > 1:
        points += [(center_x - dy, center_y + dx), (center_x + dy, center_y - dx)]
    if strength > 2:
        points += [(center_x + dx * 2, center_y + dy * 2)]
    for point_x, point_y in points:
        if 0 <= point_x < CELL and 0 <= point_y < CELL:
            output.putpixel((point_x, point_y), (255, 234, 150, 255))
    return output


def _hurt(frame: Image.Image) -> Image.Image:
    red = Image.new("RGBA", frame.size, (230, 92, 84, 0))
    alpha = frame.getchannel("A").point(lambda value: 92 if value else 0)
    red.putalpha(alpha)
    return Image.alpha_composite(frame, red)


def _death_frame(frame: Image.Image, index: int, total: int) -> Image.Image:
    """Make a brief, readable raster collapse while keeping the feet pivot stable."""
    if index == 0:
        return _hurt(frame)
    amount = index / (total - 1)
    width = round(CELL + 18 * amount)
    height = max(8, round(CELL * (1.0 - 0.40 * amount)))
    squeezed = frame.resize((width, height), Image.Resampling.NEAREST)
    output = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    output.alpha_composite(squeezed, ((CELL - width) // 2, CELL - 2 - height))
    if index == total - 1:
        alpha = output.getchannel("A").point(lambda value: value // 2)
        output.putalpha(alpha)
    return output


def _paste_sheet(rows: list[list[Image.Image]], destination: Path) -> None:
    sheet = Image.new("RGBA", (CELL * len(DIRECTIONS), CELL * len(rows)), (0, 0, 0, 0))
    for row_index, row in enumerate(rows):
        for column_index, frame in enumerate(row):
            sheet.alpha_composite(frame, (column_index * CELL, row_index * CELL))
    destination.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(destination)


def _player_rows(directed: dict[str, Image.Image]) -> list[list[Image.Image]]:
    rows: list[list[Image.Image]] = []

    # idle_0..2, run_0..5, basic_0..1, hurt, death_0..3
    for bob in (0, -1, 0):
        rows.append([_offset(directed[direction], 0, bob) for direction in DIRECTIONS])
    for frame_index in range(6):
        bob = (-1, 0, 1, 0, -1, 0)[frame_index]
        sway = (0, 1, 0, -1, 0, 1)[frame_index]
        rows.append([_offset(directed[direction], sway if direction in {"e", "se", "s"} else -sway, bob) for direction in DIRECTIONS])
    for strength in (2, 3):
        rows.append([_muzzle_flash(directed[direction], direction, strength) for direction in DIRECTIONS])
    rows.append([_hurt(directed[direction]) for direction in DIRECTIONS])
    for death_index in range(4):
        rows.append([_death_frame(directed[direction], death_index, 4) for direction in DIRECTIONS])
    return rows


def _zombie_rows(base: Image.Image) -> list[list[Image.Image]]:
    directed = {direction: _direction_variant(base, direction) for direction in DIRECTIONS}
    rows: list[list[Image.Image]] = []

    # run_0..3, attack_0..1, death_0..2
    for frame_index in range(4):
        bob = (0, -1, 1, 0)[frame_index]
        sway = (0, 1, -1, 0)[frame_index]
        rows.append([_offset(directed[direction], sway if direction in {"e", "se", "s"} else -sway, bob) for direction in DIRECTIONS])
    for strength in (1, 2):
        rows.append([_muzzle_flash(directed[direction], direction, strength) for direction in DIRECTIONS])
    for death_index in range(3):
        rows.append([_death_frame(directed[direction], death_index, 3) for direction in DIRECTIONS])
    return rows


def main() -> None:
    zombie_source = _load_chromakey_source(ROOT / "art/source/swarm_zombie_source_chromakey.png")
    fast_zombie_source = _load_chromakey_source(ROOT / "art/source/fast_zombie_source_v1.png")
    tank_zombie_source = _load_chromakey_source(ROOT / "art/source/tank_zombie_source_v1.png")
    sterling_masters = _load_facing_atlas(ROOT / "art/source/sterling_five_facing_atlas_chromakey.png")
    sterling = {
        direction: _fit_to_anchor(source, max_width=58, max_height=60)
        for direction, source in sterling_masters.items()
    }
    zombie = _fit_to_anchor(zombie_source, max_width=60, max_height=60)
    fast_zombie = _fit_to_anchor(fast_zombie_source, max_width=56, max_height=60)
    tank_zombie = _fit_to_anchor(tank_zombie_source, max_width=62, max_height=62)

    _paste_sheet(_player_rows(sterling), ROOT / "art/characters/sterling/sterling_sheet.png")
    _paste_sheet(_zombie_rows(zombie), ROOT / "art/enemies/swarm_zombie/swarm_zombie_sheet.png")
    _paste_sheet(_zombie_rows(fast_zombie), ROOT / "art/enemies/fast_zombie/fast_zombie_sheet.png")
    _paste_sheet(_zombie_rows(tank_zombie), ROOT / "art/enemies/tank_zombie/tank_zombie_sheet.png")
    print("Assembled Survivor pixel-art sheets:")
    print("  art/characters/sterling/sterling_sheet.png (8 x 16 frames)")
    print("  art/enemies/swarm_zombie/swarm_zombie_sheet.png (8 x 9 frames)")
    print("  art/enemies/fast_zombie/fast_zombie_sheet.png (8 x 9 frames)")
    print("  art/enemies/tank_zombie/tank_zombie_sheet.png (8 x 9 frames)")


if __name__ == "__main__":
    main()
