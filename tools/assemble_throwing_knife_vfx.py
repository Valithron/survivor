from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
def main():
 im=Image.open(ROOT/'art/source/throwing_knife_generated_source_v1.png').convert('RGBA'); im=im.crop(im.getbbox()); im.thumbnail((58,26),Image.Resampling.NEAREST); a=im.getchannel('A'); im=im.convert('RGB').quantize(colors=20,method=Image.Quantize.MEDIANCUT).convert('RGBA'); im.putalpha(a); out=Image.new('RGBA',(64,64)); out.alpha_composite(im,((64-im.width)//2,(64-im.height)//2)); p=ROOT/'art/vfx/knives/throwing_knife_v1.png'; p.parent.mkdir(parents=True,exist_ok=True); out.save(p)
if __name__=='__main__': main()
