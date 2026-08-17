from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
im=Image.open(ROOT/'art/source/cooper_ability_aura_generated_source_v1.png').convert('RGBA'); im=im.crop(im.getbbox()); im.thumbnail((112,112),Image.Resampling.NEAREST); a=im.getchannel('A'); im=im.convert('RGB').quantize(colors=24,method=Image.Quantize.MEDIANCUT).convert('RGBA'); im.putalpha(a); out=Image.new('RGBA',(128,128)); out.alpha_composite(im,((128-im.width)//2,(128-im.height)//2)); p=ROOT/'art/vfx/cooper/ability_aura_v1.png'; p.parent.mkdir(parents=True,exist_ok=True); out.save(p)
