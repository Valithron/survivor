"""Assemble Ryan and Cooper's generated concept art into the player atlas contract.

The source concept sheets are authored raster art: each is a 4x4 grid of full-body
poses on transparent pixels.  This tool keeps those sources in ``art/source`` and
normalizes them to the existing 8-direction, 64 px player sheet (16 rows: 3 idle,
6 run, 2 basic, 1 hurt, 4 death).  Directional reuse is explicit and nearest
neighbour only; gameplay code does not know how the sheet was produced.

Run from the repository root with the bundled Python:
    python tools/assemble_roster_character_sheets.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageEnhance, ImageOps


ROOT = Path(__file__).resolve().parents[1]
CELL = 64
DIRECTIONS = ("n", "ne", "e", "se", "s", "sw", "w", "nw")


def _panel(sheet: Image.Image, column: int, row: int) -> Image.Image:
    left = round(column * sheet.width / 4)
    right = round((column + 1) * sheet.width / 4)
    top = round(row * sheet.height / 4)
    bottom = round((row + 1) * sheet.height / 4)
    return sheet.crop((left, top, right, bottom)).convert("RGBA")


def _remove_blood(image: Image.Image) -> Image.Image:
    output = image.copy()
    pixels = output.load()
    for y in range(output.height):
        for x in range(output.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha and red > 135 and red > green * 1.55 and red > blue * 1.55:
                pixels[x, y] = (red, green, blue, 0)
    return output


def _fit_to_anchor(source: Image.Image, max_width: int = 58, max_height: int = 60) -> Image.Image:
    bounds = source.getbbox()
    if bounds is None:
        raise ValueError("Source panel has no visible pixels")
    cropped = source.crop(bounds)
    scale = min(max_width / cropped.width, max_height / cropped.height)
    size = (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale)))
    scaled = cropped.resize(size, Image.Resampling.NEAREST)
    # Quantize the high-resolution generated art into a restrained game palette,
    # retaining its authored pixel clusters rather than introducing smoothing.
    rgb = scaled.convert("RGB").quantize(colors=48, method=Image.Quantize.MEDIANCUT).convert("RGBA")
    rgb.putalpha(scaled.getchannel("A"))
    canvas = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    canvas.alpha_composite(rgb, ((CELL - scaled.width) // 2, CELL - 2 - scaled.height))
    return canvas


def _offset(frame: Image.Image, x: int, y: int) -> Image.Image:
    output = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    output.alpha_composite(frame, (x, y))
    return output


def _recoil(frame: Image.Image, amount: int) -> Image.Image:
    # A small nearest-neighbour upper-body nudge is deliberately secondary to
    # the authored source pose; it keeps the basic rows distinct without making
    # a stationary gunslinger animation.
    return _offset(frame, -amount, amount // 2)


def _flash(frame: Image.Image, direction: str, warm: bool = True) -> Image.Image:
    vectors = {
        "n": (0, -1), "ne": (1, -1), "e": (1, 0), "se": (1, 1),
        "s": (0, 1), "sw": (-1, 1), "w": (-1, 0), "nw": (-1, -1),
    }
    dx, dy = vectors[direction]
    output = frame.copy()
    center_x = 32 + dx * 20
    center_y = 28 + dy * 12
    core = (255, 247, 196, 255) if warm else (232, 255, 174, 255)
    edge = (255, 171, 48, 255) if warm else (64, 232, 120, 255)
    for px, py, color in (
        (center_x, center_y, core),
        (center_x + dx, center_y + dy, edge),
        (center_x - dy, center_y + dx, edge),
        (center_x + dy, center_y - dx, edge),
    ):
        if 0 <= px < CELL and 0 <= py < CELL:
            output.putpixel((px, py), color)
    return output


def _death_variant(frame: Image.Image, frame_index: int) -> Image.Image:
    """Create a concise grounded collapse from clean authored body art."""
    if frame_index == 0:
        return _offset(frame, 0, -1)
    angle = (7, 18, 55)[frame_index - 1]
    collapsed = frame.rotate(
        angle,
        resample=Image.Resampling.NEAREST,
        center=(32, 46),
        expand=False,
    )
    output = _offset(collapsed, 2 * frame_index, min(frame_index * 2, 6))
    # Reapply a few authored boot/contact pixels so the shared player ground
    # anchor remains stable even as the upper silhouette falls sideways.
    contact = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    contact.alpha_composite(frame.crop((0, CELL - 4, CELL, CELL)), (0, CELL - 4))
    output.alpha_composite(contact)
    return output


def _assemble_character(source_path: Path, output_path: Path, character: str) -> None:
    source = Image.open(source_path).convert("RGBA")
    idle_panels = {
        "front": _fit_to_anchor(_panel(source, 0, 0)),
        "three_quarter": _fit_to_anchor(_panel(source, 1, 0)),
        "side": _fit_to_anchor(_panel(source, 2, 0)),
        "back": _fit_to_anchor(_panel(source, 3, 0)),
    }
    run_panels = [_fit_to_anchor(_panel(source, column, 1)) for column in range(4)]
    # Ability panels in the concept sheet deliberately include large VFX. They
    # remain valuable source art, but are not used as character atlas cells:
    # fitting them to 64 px would make the player body unreadably small. The
    # clean authored idle/run poses are the primary source for basic/hurt/death,
    # with restrained nearest-neighbour pose treatments below.
    action_panels = [run_panels[0], run_panels[1]]
    hurt_panel = idle_panels["front"]
    death_panels = [_death_variant(idle_panels["front"], index) for index in range(4)]

    direction_master = {
        "n": idle_panels["back"],
        "ne": idle_panels["three_quarter"],
        "e": idle_panels["side"],
        "se": idle_panels["three_quarter"],
        "s": idle_panels["front"],
    }
    for left, right in (("sw", "se"), ("w", "e"), ("nw", "ne")):
        direction_master[left] = ImageOps.mirror(direction_master[right])

    rows: list[list[Image.Image]] = []
    for idle_index in range(3):
        row: list[Image.Image] = []
        for direction in DIRECTIONS:
            base = direction_master[direction]
            row.append(_offset(base, 0, (0, 0, -1)[idle_index]))
        rows.append(row)

    # Six real locomotion frames use the four distinct authored movement panels,
    # with a restrained repeated contact/passing cadence.  Directional masters
    # still preserve the canonical front/diagonal/side/back read.
    run_sequence = [0, 1, 2, 3, 2, 1]
    stride_offsets = (-1, 0, 1, 1, 0, -1)
    for frame_index, panel_index in enumerate(run_sequence):
        row = []
        for direction in DIRECTIONS:
            if direction in {"e", "w"}:
                base = run_panels[2]
            elif direction in {"ne", "se", "nw", "sw"}:
                base = run_panels[1]
            elif direction == "n":
                base = run_panels[3]
            else:
                base = run_panels[0]
            # Use the authored movement panel as the primary pose and vary its
            # stride timing by selecting the neighboring source panel where it
            # is orientation-compatible.
            if panel_index in (1, 3) and direction in {"s", "ne", "se"}:
                base = run_panels[panel_index]
            if direction in {"w", "sw", "nw"}:
                base = ImageOps.mirror(base)
            # The source pose supplies the limb/torso change. A one-pixel
            # contact travel keeps even side/back directions visibly advancing
            # without introducing foot-jitter or changing the shared anchor.
            row.append(_offset(base, stride_offsets[frame_index], 0))
        rows.append(row)

    for action_index in range(2):
        row = []
        for direction in DIRECTIONS:
            base = action_panels[action_index]
            if direction in {"n", "ne", "e", "nw"}:
                base = ImageEnhance.Brightness(base).enhance(0.88)
            if direction in {"w", "sw", "nw"}:
                base = ImageOps.mirror(base)
            row.append(_flash(_recoil(base, action_index + 1), direction, warm=character == "ryan"))
        rows.append(row)

    row = []
    for direction in DIRECTIONS:
        base = hurt_panel
        if direction in {"w", "sw", "nw"}:
            base = ImageOps.mirror(base)
        row.append(_offset(base, -1 if direction in {"e", "se", "ne"} else 1, -1))
    rows.append(row)

    for death_panel in death_panels:
        row = []
        for direction in DIRECTIONS:
            base = death_panel
            if direction in {"w", "sw", "nw"}:
                base = ImageOps.mirror(base)
            row.append(base)
        rows.append(row)

    output = Image.new("RGBA", (CELL * len(DIRECTIONS), CELL * len(rows)), (0, 0, 0, 0))
    for row_index, row in enumerate(rows):
        for column_index, frame in enumerate(row):
            output.alpha_composite(frame, (column_index * CELL, row_index * CELL))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output.save(output_path)


def main() -> None:
    _assemble_character(
        ROOT / "art/source/ryan_concept_sheet_v1.png",
        ROOT / "art/characters/ryan/ryan_sheet_v2.png",
        "ryan",
    )
    _assemble_character(
        ROOT / "art/source/cooper_concept_sheet_v1.png",
        ROOT / "art/characters/cooper/cooper_sheet_v2.png",
        "cooper",
    )
    print("Assembled Ryan and Cooper 8-direction 64px player sheets.")


if __name__ == "__main__":
    main()
