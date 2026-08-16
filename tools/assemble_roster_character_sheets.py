"""Assemble Cooper's clean raster sprite sheet from trusted concept panels.

Ryan is intentionally not touched by this tool: his currently integrated sheet is
approved for gameplay testing. Cooper's prior sheet accepted whole 4x4 concept
panels, including disconnected source debris and VFX, which produced corrupted
cells. This revision only uses its clean top-row directional references and
keeps one complete body silhouette in every gameplay cell.
"""

from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
CELL = 64
DIRECTIONS = ("n", "ne", "e", "se", "s", "sw", "w", "nw")


def _panel(sheet: Image.Image, column: int, row: int) -> Image.Image:
    left = round(column * sheet.width / 4)
    right = round((column + 1) * sheet.width / 4)
    top = round(row * sheet.height / 4)
    bottom = round((row + 1) * sheet.height / 4)
    return sheet.crop((left, top, right, bottom)).convert("RGBA")


def _dominant_component(source: Image.Image) -> Image.Image:
    """Keep the sole large connected silhouette from a generated source panel."""
    image = source.convert("RGBA")
    width, height = image.size
    alpha = image.getchannel("A")
    pixels = alpha.load()
    visited: set[tuple[int, int]] = set()
    components: list[list[tuple[int, int]]] = []
    for y in range(height):
        for x in range(width):
            if (x, y) in visited or pixels[x, y] < 20:
                continue
            queue: deque[tuple[int, int]] = deque([(x, y)])
            visited.add((x, y))
            component: list[tuple[int, int]] = []
            while queue:
                px, py = queue.popleft()
                component.append((px, py))
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        nx, ny = px + dx, py + dy
                        if dx == 0 and dy == 0 or nx < 0 or ny < 0 or nx >= width or ny >= height:
                            continue
                        if (nx, ny) not in visited and pixels[nx, ny] >= 20:
                            visited.add((nx, ny))
                            queue.append((nx, ny))
            components.append(component)
    if not components:
        raise ValueError("No opaque Cooper pixels found in source panel")
    primary = max(components, key=len)
    output = Image.new("RGBA", image.size, (0, 0, 0, 0))
    source_pixels = image.load()
    output_pixels = output.load()
    for x, y in primary:
        output_pixels[x, y] = source_pixels[x, y]
    return output


def _fit_to_anchor(source: Image.Image) -> Image.Image:
    bounds = source.getbbox()
    if bounds is None:
        raise ValueError("Source panel has no visible pixels")
    cropped = source.crop(bounds)
    scale = min(58 / cropped.width, 60 / cropped.height)
    size = (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale)))
    scaled = cropped.resize(size, Image.Resampling.NEAREST)
    rgb = scaled.convert("RGB").quantize(colors=48, method=Image.Quantize.MEDIANCUT).convert("RGBA")
    rgb.putalpha(scaled.getchannel("A"))
    canvas = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    canvas.alpha_composite(rgb, ((CELL - scaled.width) // 2, CELL - 2 - scaled.height))
    return canvas


def _offset(frame: Image.Image, x: int, y: int) -> Image.Image:
    output = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    output.alpha_composite(frame, (x, y))
    return output


def _run_contact(frame: Image.Image, frame_index: int) -> Image.Image:
    """Keep Cooper as one clean silhouette while giving each contact phase a subtle gear shade step."""
    output = _offset(frame, (0, 1, 0, -1, 0, 1)[frame_index], 0)
    pixels = output.load()
    candidates: list[tuple[int, int]] = []
    for y in range(24, CELL - 5):
        for x in range(CELL):
            red, green, blue, alpha = pixels[x, y]
            if alpha > 220 and blue >= red and blue >= green and blue > 35:
                candidates.append((x, y))
    if candidates:
        phase = (frame_index * 7) % len(candidates)
        for x, y in candidates[phase:phase + 4]:
            red, green, blue, alpha = pixels[x, y]
            pixels[x, y] = (min(255, red + 5), min(255, green + 6), min(255, blue + 8), alpha)
    return output


def _flash(frame: Image.Image, direction: str) -> Image.Image:
    vectors = {
        "n": (0, -1), "ne": (1, -1), "e": (1, 0), "se": (1, 1),
        "s": (0, 1), "sw": (-1, 1), "w": (-1, 0), "nw": (-1, -1),
    }
    dx, dy = vectors[direction]
    output = frame.copy()
    cx, cy = 32 + dx * 20, 28 + dy * 12
    for x, y, color in (
        (cx, cy, (255, 247, 196, 255)),
        (cx + dx, cy + dy, (255, 176, 48, 255)),
        (cx - dy, cy + dx, (255, 176, 48, 255)),
        (cx + dy, cy - dx, (255, 176, 48, 255)),
    ):
        if 0 <= x < CELL and 0 <= y < CELL:
            output.putpixel((x, y), color)
    return output


def _hurt(frame: Image.Image, direction: str) -> Image.Image:
    recoil = _offset(frame, -1 if direction in {"e", "ne", "se"} else 1, 0)
    tint = Image.new("RGBA", recoil.size, (230, 92, 84, 0))
    tint.putalpha(recoil.getchannel("A").point(lambda value: 56 if value else 0))
    return Image.alpha_composite(recoil, tint)


def _death(frame: Image.Image, direction: str, index: int) -> Image.Image:
    if index == 0:
        return _hurt(frame, direction)
    fall_sign = 1 if direction in {"n", "ne", "e", "se"} else -1
    angle = (8, 22, 58)[index - 1] * fall_sign
    fallen = frame.rotate(angle, resample=Image.Resampling.NEAREST, center=(32, 47), expand=False)
    return _offset(fallen, fall_sign * index, min(index * 2, 6))


def _components(frame: Image.Image) -> list[int]:
    alpha = frame.getchannel("A")
    width, height = frame.size
    pixels = alpha.load()
    visited: set[tuple[int, int]] = set()
    sizes: list[int] = []
    for y in range(height):
        for x in range(width):
            if (x, y) in visited or pixels[x, y] < 20:
                continue
            queue: deque[tuple[int, int]] = deque([(x, y)])
            visited.add((x, y))
            size = 0
            while queue:
                px, py = queue.popleft(); size += 1
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        nx, ny = px + dx, py + dy
                        if dx == 0 and dy == 0 or nx < 0 or ny < 0 or nx >= width or ny >= height:
                            continue
                        if (nx, ny) not in visited and pixels[nx, ny] >= 20:
                            visited.add((nx, ny)); queue.append((nx, ny))
            sizes.append(size)
    return sorted(sizes, reverse=True)


def _validate(rows: list[list[Image.Image]]) -> None:
    if len(rows) != 16 or any(len(row) != 8 for row in rows):
        raise ValueError("Cooper sheet must be exactly 8 x 16 cells")
    for row_index, row in enumerate(rows):
        for direction_index, cell in enumerate(row):
            if cell.getbbox() is None:
                raise ValueError(f"Empty Cooper cell at row {row_index}, direction {direction_index}")
            secondary = _components(cell)[1:]
            maximum_secondary = 20 if row_index in (9, 10) else 0
            if secondary and secondary[0] > maximum_secondary:
                raise ValueError(f"Disconnected Cooper fragment at row {row_index}, direction {direction_index}")
    for direction_index in range(8):
        for row_index in range(3, 8):
            if rows[row_index][direction_index].tobytes() == rows[row_index + 1][direction_index].tobytes():
                raise ValueError(f"Duplicate Cooper run cells at rows {row_index}/{row_index + 1}, direction {direction_index}")


def _assemble_cooper() -> None:
    source = Image.open(ROOT / "art/source/cooper_concept_sheet_v1.png").convert("RGBA")
    panels = [_fit_to_anchor(_dominant_component(_panel(source, column, 0))) for column in range(4)]
    masters = {"n": panels[3], "ne": panels[1], "e": panels[2], "se": panels[1], "s": panels[0]}
    for left, right in (("sw", "se"), ("w", "e"), ("nw", "ne")):
        masters[left] = ImageOps.mirror(masters[right])
    rows: list[list[Image.Image]] = []
    for offset in (0, 1, 0):
        rows.append([_offset(masters[direction], offset, 0) for direction in DIRECTIONS])
    for frame_index in range(6):
        rows.append([_run_contact(masters[direction], frame_index) for direction in DIRECTIONS])
    for recoil in (1, 2):
        rows.append([_flash(_offset(masters[direction], -recoil, 0), direction) for direction in DIRECTIONS])
    rows.append([_hurt(masters[direction], direction) for direction in DIRECTIONS])
    for index in range(4):
        rows.append([_death(masters[direction], direction, index) for direction in DIRECTIONS])
    _validate(rows)
    output = Image.new("RGBA", (CELL * 8, CELL * 16), (0, 0, 0, 0))
    for row_index, row in enumerate(rows):
        for direction_index, cell in enumerate(row):
            output.alpha_composite(cell, (direction_index * CELL, row_index * CELL))
    output.save(ROOT / "art/characters/cooper/cooper_sheet_v2.png")


if __name__ == "__main__":
    _assemble_cooper()
    print("Assembled and sanity-checked Cooper's clean 8-direction player sheet.")
