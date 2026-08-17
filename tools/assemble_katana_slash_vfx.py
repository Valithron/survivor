"""Normalize the approved Katana slash source into the runtime VFX atlas.

The source is a three-stage raster effect generated for Survivor.  This tool
keeps the gameplay-facing atlas reproducible: three 128px cells, transparent
background, a bounded palette, and nearest-neighbour scaling only.
"""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
FRAME_SIZE = 128
FRAME_COUNT = 3


def _normalize(source: Image.Image) -> Image.Image:
	"""Keep source composition intact while reducing it to the game VFX scale."""
	frame = source.resize((FRAME_SIZE, FRAME_SIZE), Image.Resampling.NEAREST)
	alpha = frame.getchannel("A")
	rgb = frame.convert("RGB").quantize(colors=24, method=Image.Quantize.MEDIANCUT).convert("RGBA")
	rgb.putalpha(alpha)
	return rgb


def main() -> None:
	source_path = ROOT / "art/source/katana_slash_generated_source_v1.png"
	output_path = ROOT / "art/vfx/katana/katana_slash_sheet_v1.png"
	source = Image.open(source_path).convert("RGBA")
	if source.width % FRAME_COUNT != 0 or source.height <= 0:
		raise ValueError("Katana source must contain three equal horizontal cells.")
	cell_width = source.width // FRAME_COUNT
	output = Image.new("RGBA", (FRAME_SIZE * FRAME_COUNT, FRAME_SIZE), (0, 0, 0, 0))
	for index in range(FRAME_COUNT):
		frame = _normalize(source.crop((index * cell_width, 0, (index + 1) * cell_width, source.height)))
		if frame.getbbox() is None:
			raise ValueError("Katana VFX source contains an empty frame.")
		output.alpha_composite(frame, (index * FRAME_SIZE, 0))
	output_path.parent.mkdir(parents=True, exist_ok=True)
	output.save(output_path)
	print(f"Wrote {output_path.relative_to(ROOT)} ({FRAME_COUNT} x {FRAME_SIZE}px frames).")


if __name__ == "__main__":
	main()
