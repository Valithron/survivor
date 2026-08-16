"""Build a compact two-frame atlas from Sterling's authored tracer source."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SIZE = 64

def main() -> None:
	source = Image.open(ROOT / "art/source/sterling_pistol_tracer_generated_source_v1.png").convert("RGBA")
	output = Image.new("RGBA", (SIZE * 2, SIZE), (0, 0, 0, 0))
	for index in range(2):
		cell = source.crop((0, index * source.height // 2, source.width, (index + 1) * source.height // 2))
		bounds = cell.getbbox()
		if bounds is None: raise ValueError("Sterling tracer source contains an empty frame.")
		cell = cell.crop(bounds)
		cell.thumbnail((60, 42), Image.Resampling.NEAREST)
		alpha = cell.getchannel("A")
		cell = cell.convert("RGB").quantize(colors=20, method=Image.Quantize.MEDIANCUT).convert("RGBA")
		cell.putalpha(alpha)
		output.alpha_composite(cell, (index * SIZE + 2, (SIZE - cell.height) // 2))
	path = ROOT / "art/vfx/sterling/sterling_pistol_tracer_sheet_v1.png"
	path.parent.mkdir(parents=True, exist_ok=True); output.save(path)
	print(f"Wrote {path.relative_to(ROOT)} (2x64px frames).")

if __name__ == "__main__": main()
