from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
im=Image.open(ROOT/'art/source/ryan_charge_generated_source_v1.png').convert('RGBA'); im=im.crop(im.getbbox()); im.thumbnail((256,64),Image.Resampling.NEAREST); a=im.getchannel('A'); im=im.convert('RGB').quantize(colors=24,method=Image.Quantize.MEDIANCUT).convert('RGBA'); im.putalpha(a); out=Image.new('RGBA',(256,64)); out.alpha_composite(im,(0,(64-im.height)//2)); p=ROOT/'art/vfx/ryan/charge_trail_v1.png'; p.parent.mkdir(parents=True,exist_ok=True); out.save(p)
