"""Normalize the authored Auto-Turret source into its runtime pixel sprite."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
FRAME_SIZE = 64
MAX_SPRITE_SIZE = 58


def _normalize(source: Image.Image) -> Image.Image:
	"""Crop transparent padding, preserve aspect ratio, and keep crisp pixels."""
	bounds = source.getbbox()
	if bounds is None:
		raise ValueError("Auto-Turret source must contain non-transparent pixels.")
	cropped = source.crop(bounds)
	scale = min(MAX_SPRITE_SIZE / cropped.width, MAX_SPRITE_SIZE / cropped.height)
	new_size = (
		max(1, round(cropped.width * scale)),
		max(1, round(cropped.height * scale)),
	)
	sprite = cropped.resize(new_size, Image.Resampling.NEAREST)
	alpha = sprite.getchannel("A")
	palette = sprite.convert("RGB").quantize(colors=32, method=Image.Quantize.MEDIANCUT).convert("RGBA")
	palette.putalpha(alpha)
	output = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
	output.alpha_composite(palette, ((FRAME_SIZE - sprite.width) // 2, (FRAME_SIZE - sprite.height) // 2))
	return output


def main() -> None:
	source_path = ROOT / "art/source/auto_turret_generated_source_v1.png"
	output_path = ROOT / "art/vfx/turret/auto_turret_v1.png"
	output = _normalize(Image.open(source_path).convert("RGBA"))
	output_path.parent.mkdir(parents=True, exist_ok=True)
	output.save(output_path)
	print(f"Wrote {output_path.relative_to(ROOT)} ({FRAME_SIZE}x{FRAME_SIZE}px).")


if __name__ == "__main__":
	main()
