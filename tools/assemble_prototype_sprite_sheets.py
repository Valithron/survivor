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

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageOps


ROOT = Path(__file__).resolve().parents[1]
CELL = 64
DIRECTIONS = ("n", "ne", "e", "se", "s", "sw", "w", "nw")


def _is_chroma_key(red: int, green: int, blue: int) -> bool:
    return red >= 210 and blue >= 150 and green <= 115


def _is_magenta_chroma_or_fringe(red: int, green: int, blue: int) -> bool:
    """Recognize the atlas chroma key plus its generated purple edge fringe."""
    if _is_chroma_key(red, green, blue):
        return True
    # The supplied atlas has a handful of semi-key pixels blended against the
    # #ff00ff backing. They are not part of Sterling's cobalt/crimson palette
    # and become especially distracting at the 64 px gameplay scale.
    return red >= 130 and blue >= 120 and green <= 55 and abs(red - blue) <= 65


def _remove_magenta_fringe(image: Image.Image) -> Image.Image:
    """Clear opaque key-colour halo pixels left by an AI-source background."""
    output = image.copy()
    pixels = output.load()
    for y in range(output.height):
        for x in range(output.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha and _is_magenta_chroma_or_fringe(red, green, blue):
                pixels[x, y] = (red, green, blue, 0)
    return output


def _load_chromakey_source(path: Path) -> Image.Image:
    """Return a tightly-cropped RGBA image after removing #ff00ff."""
    source = Image.open(path).convert("RGBA")
    pixels = source.load()
    for y in range(source.height):
        for x in range(source.width):
            red, green, blue, alpha = pixels[x, y]
            if _is_chroma_key(red, green, blue):
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
                if _is_magenta_chroma_or_fringe(red, green, blue):
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


def _fit_to_anchor(
    source: Image.Image,
    max_width: int,
    max_height: int,
    clear_magenta_fringe: bool = False,
) -> Image.Image:
    """Scale a source to a transparent 64 px cell with a fixed foot anchor."""
    scale = min(max_width / source.width, max_height / source.height)
    size = (max(1, round(source.width * scale)), max(1, round(source.height * scale)))
    scaled = source.resize(size, Image.Resampling.NEAREST)
    # Palette reduction happens after normalisation, retaining a clear outline
    # while avoiding excessive near-duplicate colors from the source render.
    alpha = scaled.getchannel("A")
    rgb = scaled.convert("RGB").quantize(colors=48, method=Image.Quantize.MEDIANCUT).convert("RGBA")
    rgb.putalpha(alpha)
    if clear_magenta_fringe:
        rgb = _remove_magenta_fringe(rgb)
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


def _player_bounds(frame: Image.Image) -> tuple[int, int, int, int]:
    """Return an alpha bound with a sensible fallback for authored player cells."""
    bounds = frame.getbbox()
    return bounds if bounds is not None else (8, 4, 56, CELL - 2)


def _polygon_mask(points: list[tuple[int, int]]) -> Image.Image:
    """Build a hard-edged cell-local mask for a poseable sprite region."""
    mask = Image.new("L", (CELL, CELL), 0)
    ImageDraw.Draw(mask).polygon(points, fill=255)
    return mask


def _player_pose_masks(frame: Image.Image) -> dict[str, Image.Image]:
    """Return broad, hand-authored regions for the approved Sterling silhouette.

    The source is a finished flattened pixel-art facing atlas, not a layered rig.
    These deliberately conservative masks isolate only the animated silhouette
    masses: legs, split coat tails, lower hair, and gun arms.  Keeping the chest,
    face, and coat collar in the stationary core prevents proportional drift while
    still allowing every frame to have genuine internal pose movement.
    """
    left, _top, right, _bottom = _player_bounds(frame)
    center = (left + right) // 2
    return {
        "left_leg": _polygon_mask([
            (center - 18, 38), (center - 2, 38), (center + 1, 63), (center - 18, 63),
        ]),
        "right_leg": _polygon_mask([
            (center + 1, 38), (center + 18, 38), (center + 19, 63), (center - 1, 63),
        ]),
        "left_tail": _polygon_mask([
            (center - 20, 35), (center - 2, 36), (center + 1, 57), (center - 20, 58),
        ]),
        "right_tail": _polygon_mask([
            (center + 1, 35), (center + 20, 35), (center + 20, 58), (center - 1, 57),
        ]),
        "left_hair": _polygon_mask([
            (center - 20, 4), (center - 2, 3), (center - 3, 31), (center - 20, 36),
        ]),
        "right_hair": _polygon_mask([
            (center + 2, 3), (center + 20, 4), (center + 20, 36), (center + 3, 31),
        ]),
        "left_arm": _polygon_mask([
            (center - 22, 21), (center - 2, 20), (center + 1, 49), (center - 21, 54),
        ]),
        "right_arm": _polygon_mask([
            (center + 1, 20), (center + 22, 21), (center + 22, 54), (center - 1, 49),
        ]),
        "head": _polygon_mask([
            (center - 16, 2), (center + 16, 2), (center + 17, 25), (center - 17, 25),
        ]),
        "upper_body": _polygon_mask([
            (center - 20, 18), (center + 20, 18), (center + 20, 46), (center - 20, 46),
        ]),
        "lower_body": _polygon_mask([
            (center - 20, 38), (center + 20, 38), (center + 20, 63), (center - 20, 63),
        ]),
    }


def _separate_pose_regions(
    frame: Image.Image,
    masks: dict[str, Image.Image],
    names: tuple[str, ...],
) -> tuple[Image.Image, dict[str, Image.Image]]:
    """Lift selected flat-art regions into independently poseable pixel pieces."""
    combined = Image.new("L", (CELL, CELL), 0)
    pieces: dict[str, Image.Image] = {}
    source_alpha = frame.getchannel("A")
    for name in names:
        mask = masks[name]
        combined = ImageChops.lighter(combined, mask)
        piece = frame.copy()
        piece.putalpha(ImageChops.multiply(source_alpha, mask))
        pieces[name] = piece

    remaining = frame.copy()
    remaining.putalpha(ImageChops.subtract(source_alpha, combined))
    return remaining, pieces


def _transform_piece(
    piece: Image.Image,
    x_offset: int = 0,
    y_offset: int = 0,
    angle: int = 0,
    pivot: tuple[int, int] | None = None,
) -> Image.Image:
    """Move one hard-edged sprite region without filtering or subpixels."""
    if angle:
        return piece.rotate(
            angle,
            resample=Image.Resampling.NEAREST,
            center=pivot or (CELL // 2, CELL // 2),
            translate=(x_offset, y_offset),
        )
    return _offset(piece, x_offset, y_offset)


def _compose_player_pose(
    frame: Image.Image,
    transforms: dict[str, tuple[int, int, int, tuple[int, int] | None]],
    draw_order: tuple[str, ...],
) -> Image.Image:
    """Compose a frame from fixed core art plus selectively re-posed regions."""
    masks = _player_pose_masks(frame)
    names = tuple(name for name in draw_order if name in transforms)
    output, pieces = _separate_pose_regions(frame, masks, names)
    for name in draw_order:
        if name not in pieces:
            continue
        x_offset, y_offset, angle, pivot = transforms[name]
        output.alpha_composite(_transform_piece(pieces[name], x_offset, y_offset, angle, pivot))
    return output


def _restore_ground_contact(output: Image.Image, authored_frame: Image.Image) -> Image.Image:
    """Keep the authored boot-contact pixels on the common 64 px ground line.

    Pose masks intentionally overlap the long split coat.  Reapplying only the
    bottom two authored rows preserves an unambiguous planted-foot reference
    without reintroducing whole-body translation or a second static silhouette.
    """
    contact_mask = Image.new("L", (CELL, CELL), 0)
    ImageDraw.Draw(contact_mask).rectangle((0, CELL - 4, CELL - 1, CELL - 1), fill=255)
    contact = authored_frame.copy()
    contact.putalpha(ImageChops.multiply(authored_frame.getchannel("A"), contact_mask))
    output.alpha_composite(contact)
    return output


def _heading(direction: str) -> tuple[int, int]:
    vectors = {
        "n": (0, -1), "ne": (1, -1), "e": (1, 0), "se": (1, 1),
        "s": (0, 1), "sw": (-1, 1), "w": (-1, 0), "nw": (-1, -1),
    }
    return vectors[direction]


def _grounded_offset(x_offset: int, y_offset: int) -> tuple[int, int]:
    """Never drop a walking foot below the shared cell ground line."""
    return x_offset, min(0, y_offset)


def _run_pose(frame: Image.Image, direction: str, frame_index: int) -> Image.Image:
    """Author a six-phase speedster stride from regional pixel-art motion.

    This is intentionally a compact, controlled run.  The two feet alternate
    through contact, passing, and extension while the coat/hair lag the travel
    vector and the pistol arms counter-swing.  No whole-character translation,
    scaling, or squash is used.
    """
    heading_x, heading_y = _heading(direction)
    side_x, side_y = -heading_y, heading_x
    stride = (-2, -1, 1, 2, 1, -1)[frame_index]
    coat_wave = (1, 2, 1, -1, -2, -1)[frame_index]
    arm_swing = (1, 0, -1, -2, -1, 0)[frame_index]

    left_leg = _grounded_offset(
        heading_x * stride - side_x,
        heading_y * stride - side_y,
    )
    right_leg = _grounded_offset(
        -heading_x * stride + side_x,
        -heading_y * stride + side_y,
    )
    # Hair and split tails trail the movement vector with a restrained lateral
    # wave, keeping the speedster silhouette lively rather than fluttery.
    trailing_x = -heading_x * coat_wave
    trailing_y = -heading_y * coat_wave
    torso_pivot = (_player_bounds(frame)[0] + _player_bounds(frame)[2]) // 2, 39
    transforms = {
        "left_leg": (left_leg[0], left_leg[1], 0, None),
        "right_leg": (right_leg[0], right_leg[1], 0, None),
        # The tails may rise with acceleration but never fall below the authored
        # boot baseline; that keeps the shared Sprite2D feet pivot stable.
        "left_tail": (trailing_x - side_x, min(0, trailing_y), -coat_wave, torso_pivot),
        "right_tail": (trailing_x + side_x, min(0, trailing_y), coat_wave, torso_pivot),
        "left_hair": (trailing_x - side_x, max(-2, min(2, trailing_y)), -coat_wave, torso_pivot),
        "right_hair": (trailing_x + side_x, max(-2, min(2, trailing_y)), coat_wave, torso_pivot),
        "left_arm": (-heading_x * arm_swing, min(0, -heading_y * arm_swing), -arm_swing, torso_pivot),
        "right_arm": (heading_x * arm_swing, min(0, heading_y * arm_swing), arm_swing, torso_pivot),
    }
    output = _compose_player_pose(
        frame,
        transforms,
        ("left_leg", "right_leg", "left_tail", "right_tail", "left_hair", "right_hair", "left_arm", "right_arm"),
    )
    return _restore_ground_contact(output, frame)


def _idle_pose(frame: Image.Image, direction: str, frame_index: int) -> Image.Image:
    """Give the ready stance minute, internal breathing/settling motion."""
    if frame_index == 0:
        return frame.copy()
    heading_x, _heading_y = _heading(direction)
    settle = 1 if frame_index == 1 else -1
    tail_lift = -1 if frame_index == 1 else 0
    center = (_player_bounds(frame)[0] + _player_bounds(frame)[2]) // 2, 38
    transforms = {
        "left_hair": (-heading_x * settle, settle, -settle, center),
        "right_hair": (-heading_x * settle, settle, settle, center),
        "left_tail": (0, tail_lift, -settle, center),
        "right_tail": (0, tail_lift, settle, center),
        "left_arm": (0, -settle, 0, None),
        "right_arm": (0, -settle, 0, None),
    }
    output = _compose_player_pose(
        frame,
        transforms,
        ("left_tail", "right_tail", "left_hair", "right_hair", "left_arm", "right_arm"),
    )
    return _restore_ground_contact(output, frame)


def _muzzle_anchor(frame: Image.Image, direction: str, firing_left: bool) -> tuple[int, int]:
    """Place a small flash at a directional pistol tip, not at cell centre."""
    left, top, right, bottom = _player_bounds(frame)
    center_x = (left + right) // 2
    anchors = {
        "n": (center_x + (-5 if firing_left else 5), top + 23),
        "ne": (right - 1, top + 28),
        "e": (right, top + 33),
        "se": (right - 1, bottom - 20),
        "s": (center_x + (-10 if firing_left else 10), bottom - 14),
        "sw": (left, bottom - 20),
        "w": (left - 1, top + 33),
        "nw": (left, top + 28),
    }
    return anchors[direction]


def _stamp_muzzle_flash(
    frame: Image.Image,
    direction: str,
    firing_left: bool,
) -> Image.Image:
    """Apply a restrained warm flash after the pistol/forearm has recoiled."""
    heading_x, heading_y = _heading(direction)
    center_x, center_y = _muzzle_anchor(frame, direction, firing_left)
    output = frame.copy()
    pixels = [
        (center_x, center_y, (255, 246, 194, 255)),
        (center_x + heading_x, center_y + heading_y, (255, 190, 78, 255)),
        (center_x - heading_y, center_y + heading_x, (239, 139, 55, 255)),
        (center_x + heading_y, center_y - heading_x, (239, 139, 55, 255)),
        (center_x + heading_x * 2, center_y + heading_y * 2, (255, 218, 112, 255)),
    ]
    for point_x, point_y, color in pixels:
        if 0 <= point_x < CELL and 0 <= point_y < CELL:
            output.putpixel((point_x, point_y), color)
    return output


def _basic_pose(frame: Image.Image, direction: str, frame_index: int) -> Image.Image:
    """Make each alternating shot a running recoil frame, never a static pose."""
    output = _run_pose(frame, direction, (1, 4)[frame_index])
    heading_x, heading_y = _heading(direction)
    firing_left = frame_index == 1
    arm_name = "left_arm" if firing_left else "right_arm"
    center = (_player_bounds(frame)[0] + _player_bounds(frame)[2]) // 2, 35
    # The firing hand pulls a pixel back from the aim vector while the shoulder
    # turns into the shot.  It is intentionally small: Sterling's pistols are
    # quick, light semi-auto hand cannons, not heavy revolvers.
    output = _compose_player_pose(
        output,
        {
            arm_name: (-heading_x, min(0, -heading_y), -3 if firing_left else 3, center),
        },
        (arm_name,),
    )
    return _stamp_muzzle_flash(_restore_ground_contact(output, frame), direction, firing_left)


def _hurt_pose(frame: Image.Image, direction: str) -> Image.Image:
    """Add a compact impact recoil before applying the existing color feedback."""
    heading_x, heading_y = _heading(direction)
    recoil_x = -heading_x
    recoil_y = -heading_y
    center = (_player_bounds(frame)[0] + _player_bounds(frame)[2]) // 2, 38
    output = _compose_player_pose(
        frame,
        {
            # Upper masses can recoil either up or down; the boot-contact helper
            # below keeps this brief hit read from changing the feet pivot.
            "head": (recoil_x, recoil_y, -2 * heading_x, center),
            "upper_body": (recoil_x, recoil_y, -2 * heading_x, center),
            "left_arm": (recoil_x, recoil_y, 0, None),
            "right_arm": (recoil_x, recoil_y, 0, None),
        },
        ("head", "upper_body", "left_arm", "right_arm"),
    )
    red = Image.new("RGBA", output.size, (230, 92, 84, 0))
    alpha = output.getchannel("A").point(lambda value: 64 if value else 0)
    red.putalpha(alpha)
    return _restore_ground_contact(Image.alpha_composite(output, red), frame)


def _death_pose(frame: Image.Image, direction: str, frame_index: int) -> Image.Image:
    """Compose a four-stage defeated fall from articulated pixel regions."""
    if frame_index == 0:
        return _hurt_pose(frame, direction)

    # Fall to one screen side based on the facing.  This remains readable through
    # a horde while avoiding a direction-independent squash or uniform resize.
    fall_sign = 1 if direction in {"n", "ne", "e", "se"} else -1
    center_x = (_player_bounds(frame)[0] + _player_bounds(frame)[2]) // 2
    hip_pivot = (center_x, 45)
    if frame_index == 1:
        transforms = {
            "head": (fall_sign, 2, fall_sign * 7, hip_pivot),
            "upper_body": (fall_sign, 1, fall_sign * 5, hip_pivot),
            "left_arm": (fall_sign * 2, 2, fall_sign * 8, hip_pivot),
            "right_arm": (fall_sign * 2, 2, fall_sign * 8, hip_pivot),
            "left_tail": (fall_sign, 1, fall_sign * 4, hip_pivot),
            "right_tail": (fall_sign, 1, fall_sign * 4, hip_pivot),
        }
    elif frame_index == 2:
        transforms = {
            "head": (fall_sign * 7, 8, fall_sign * 32, hip_pivot),
            "upper_body": (fall_sign * 5, 4, fall_sign * 22, hip_pivot),
            "lower_body": (fall_sign * 2, 1, fall_sign * 9, hip_pivot),
            "left_arm": (fall_sign * 6, 5, fall_sign * 27, hip_pivot),
            "right_arm": (fall_sign * 6, 5, fall_sign * 27, hip_pivot),
            "left_hair": (fall_sign * 5, 6, fall_sign * 26, hip_pivot),
            "right_hair": (fall_sign * 5, 6, fall_sign * 26, hip_pivot),
        }
    else:
        transforms = {
            "head": (fall_sign * 15, 17, fall_sign * 70, hip_pivot),
            "upper_body": (fall_sign * 10, 10, fall_sign * 52, hip_pivot),
            "lower_body": (fall_sign * 5, 4, fall_sign * 31, hip_pivot),
            "left_arm": (fall_sign * 12, 11, fall_sign * 58, hip_pivot),
            "right_arm": (fall_sign * 12, 11, fall_sign * 58, hip_pivot),
            "left_tail": (fall_sign * 7, 5, fall_sign * 34, hip_pivot),
            "right_tail": (fall_sign * 7, 5, fall_sign * 34, hip_pivot),
            "left_hair": (fall_sign * 13, 14, fall_sign * 64, hip_pivot),
            "right_hair": (fall_sign * 13, 14, fall_sign * 64, hip_pivot),
        }
    return _compose_player_pose(
        frame,
        transforms,
        ("lower_body", "left_tail", "right_tail", "left_hair", "right_hair", "head", "upper_body", "left_arm", "right_arm"),
    )


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


def _safe_whole_pose_offset(frame: Image.Image, frame_index: int) -> Image.Image:
    """Produce a clean, grounded contact-step from an intact source silhouette.

    The old animation pass reposed broad rectangular masks from a flattened source
    atlas. Those masks crossed coat, pistol, and neighboring silhouette areas in
    several facings, which left duplicate bodies and fragments after compositing.
    This corrective path keeps each source cell whole, then gives the coat/hair a
    tiny authored shade-step so its six contact phases are never duplicate rasters.
    """
    contact_travel = (0, 1, 0, -1, 0, 1)[frame_index]
    output = _offset(frame, contact_travel, 0)
    pixels = output.load()
    candidates: list[tuple[int, int]] = []
    for y in range(24, CELL - 5):
        for x in range(CELL):
            red, green, blue, alpha = pixels[x, y]
            if alpha > 220 and blue >= red and blue >= green and blue > 45:
                candidates.append((x, y))
    # Recolour existing opaque cobalt/hair-edge pixels only.  This reads as a
    # controlled secondary cloth/hair phase rather than a detached effect or a
    # second source silhouette, while keeping the feet/pivot unchanged.
    if candidates:
        phase = (frame_index * 7) % len(candidates)
        for x, y in candidates[phase:phase + 4]:
            red, green, blue, alpha = pixels[x, y]
            pixels[x, y] = (min(255, red + 6), min(255, green + 8), min(255, blue + 12), alpha)
    return output


def _safe_basic_pose(frame: Image.Image, direction: str, frame_index: int) -> Image.Image:
    """One coherent recoil pose with only a deliberate tiny muzzle flash."""
    output = _offset(frame, -1 - frame_index, 0)
    return _stamp_muzzle_flash(output, direction, frame_index == 1)


def _safe_hurt_pose(frame: Image.Image, direction: str) -> Image.Image:
    """Keep the full silhouette intact while adding a compact hit response."""
    heading_x, _heading_y = _heading(direction)
    recoil_x = -heading_x if heading_x != 0 else (-1 if direction == "n" else 1)
    output = _offset(frame, recoil_x, 0)
    red = Image.new("RGBA", output.size, (230, 92, 84, 0))
    alpha = output.getchannel("A").point(lambda value: 64 if value else 0)
    red.putalpha(alpha)
    return Image.alpha_composite(output, red)


def _safe_death_pose(frame: Image.Image, direction: str, frame_index: int) -> Image.Image:
    """Four whole-pose fall stages; no cut-and-reassembled body regions."""
    if frame_index == 0:
        return _safe_hurt_pose(frame, direction)
    fall_sign = 1 if direction in {"n", "ne", "e", "se"} else -1
    angle = (8, 22, 58)[frame_index - 1] * fall_sign
    output = frame.rotate(
        angle,
        resample=Image.Resampling.NEAREST,
        center=(CELL // 2, CELL - 17),
        expand=False,
    )
    return _offset(output, fall_sign * frame_index, min(frame_index * 2, 6))


def _player_rows(directed: dict[str, Image.Image]) -> list[list[Image.Image]]:
    """Assemble a corruption-safe player sheet from one complete pose per cell."""
    rows: list[list[Image.Image]] = []

    # idle_0..2, run_0..5, basic_0..1, hurt, death_0..3
    for frame_index in range(3):
        rows.append([_offset(directed[direction], (0, 1, 0)[frame_index], 0) for direction in DIRECTIONS])
    for frame_index in range(6):
        rows.append([_safe_whole_pose_offset(directed[direction], frame_index) for direction in DIRECTIONS])
    for frame_index in range(2):
        rows.append([_safe_basic_pose(directed[direction], direction, frame_index) for direction in DIRECTIONS])
    rows.append([_safe_hurt_pose(directed[direction], direction) for direction in DIRECTIONS])
    for death_index in range(4):
        rows.append([_safe_death_pose(directed[direction], direction, death_index) for direction in DIRECTIONS])
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
        direction: _fit_to_anchor(source, max_width=58, max_height=60, clear_magenta_fringe=True)
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
