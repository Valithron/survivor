from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
def n(im,size):
 b=im.getbbox(); im=im.crop(b); im.thumbnail((size-6,size-6),Image.Resampling.NEAREST); a=im.getchannel('A'); im=im.convert('RGB').quantize(colors=24,method=Image.Quantize.MEDIANCUT).convert('RGBA'); im.putalpha(a); o=Image.new('RGBA',(size,size)); o.alpha_composite(im,((size-im.width)//2,(size-im.height)//2)); return o
def main():
 s=Image.open(ROOT/'art/source/grenade_vfx_generated_source_alpha_v1.png').convert('RGBA'); c=[s.crop((x*s.width//2,y*s.height//2,(x+1)*s.width//2,(y+1)*s.height//2)) for y in range(2) for x in range(2)]; d=ROOT/'art/vfx/grenade'; d.mkdir(parents=True,exist_ok=True)
 p=Image.new('RGBA',(128,64)); p.alpha_composite(n(c[0],64),(0,0)); p.alpha_composite(n(c[1],64),(64,0)); p.save(d/'grenade_projectile_sheet_v1.png')
 e=Image.new('RGBA',(256,128)); e.alpha_composite(n(c[2],128),(0,0)); e.alpha_composite(n(c[3],128),(128,0)); e.save(d/'grenade_explosion_sheet_v1.png')
if __name__=='__main__': main()
