"""Generate MapBanai's vector mark, adaptive Android resources and legacy icons.

Run with Pillow installed. This draws the new vector design; no external art or
font is required, and the existing horizontal wordmark is kept separately.
"""
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
BG = '#115969'
PAPER = '#F5FCFA'
CORAL = '#F48150'
PANELS = [
    ('#D3EEE8', [(29,45),(43,40),(43,69),(29,74)]),
    (PAPER, [(43,40),(65,45),(65,74),(43,69)]),
    ('#A8D8D1', [(65,45),(79,40),(79,69),(65,74)]),
]
PIN = 'M54,24 C44,24 38,31 38,40 C38,50 54,62 54,62 C54,62 70,50 70,40 C70,31 64,24 54,24 Z'


def put(path, text):
    path = ROOT / path
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8')


def bezier(p, a, b, end):
    return [tuple((1-t)**3*p[k] + 3*(1-t)**2*t*a[k] + 3*(1-t)*t*t*b[k] + t**3*end[k]
                  for k in range(2)) for t in (i/64 for i in range(1,65))]


def render(size, *, square=False, round_icon=False):
    scale = size*4/108
    im = Image.new('RGBA', (size*4,size*4))
    draw = ImageDraw.Draw(im)
    draw.rounded_rectangle((0,0,size*4-1,size*4-1),radius=0 if square else (54 if round_icon else 24)*scale,fill=BG)
    for color, points in PANELS:
        draw.polygon([(x*scale,y*scale) for x,y in points],fill=color)
    for a,b in [((43,40),(43,69)),((65,45),(65,74))]:
        draw.line([(a[0]*scale,a[1]*scale),(b[0]*scale,b[1]*scale)],fill=BG,width=max(1,round(1.8*scale)))
    p=(54,24);points=[p]
    for a,b,end in [((44,24),(38,31),(38,40)),((38,50),(54,62),(54,62)),
                    ((54,62),(70,50),(70,40)),((70,31),(64,24),(54,24))]:
        points.extend(bezier(p,a,b,end));p=end
    draw.polygon([(x*scale,y*scale) for x,y in points],fill=CORAL)
    draw.ellipse((48.5*scale,33.5*scale,59.5*scale,44.5*scale),fill=PAPER)
    return im.resize((size,size),Image.Resampling.LANCZOS)


def main():
    paths=[]
    for color,points in PANELS:
        data='M'+' L'.join(f'{x},{y}' for x,y in points)+' Z'
        paths.append((color,data))
    vector='''<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">\n'''
    svg='<svg xmlns="http://www.w3.org/2000/svg" width="108" height="108" viewBox="0 0 108 108"><rect width="108" height="108" rx="24" fill="'+BG+'"/>'
    for color,data in paths:
        vector+=f'    <path android:fillColor="{color}" android:pathData="{data}"/>\n'
        svg+=f'<path fill="{color}" d="{data}"/>'
    folds='M43,40 L43,69 M65,45 L65,74'
    vector+=f'    <path android:fillColor="#00000000" android:strokeColor="{BG}" android:strokeWidth="1.8" android:pathData="{folds}"/>\n'
    vector+=f'    <path android:fillColor="{CORAL}" android:pathData="{PIN}"/>\n'
    vector+=f'    <path android:fillColor="{PAPER}" android:pathData="M54,33.5 A5.5,5.5 0,1 0,54,44.5 A5.5,5.5 0,1 0,54,33.5 Z"/>\n</vector>\n'
    svg+=f'<path fill="none" stroke="{BG}" stroke-width="1.8" d="{folds}"/><path fill="{CORAL}" d="{PIN}"/><circle cx="54" cy="39" r="5.5" fill="{PAPER}"/></svg>\n'
    put('assets/logo/app_icon.svg',svg)
    put('android/app/src/main/res/drawable/ic_launcher_foreground.xml',vector)
    mono='''<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#00000000" android:strokeColor="#FFFFFF" android:strokeWidth="3" android:strokeLineJoin="round" android:pathData="M30,48 L43,44 L65,49 L78,44 L78,70 L65,75 L43,70 L30,75 Z M43,64 L43,70 M65,65 L65,75"/>
    <path android:fillColor="#FFFFFF" android:fillType="evenOdd" android:pathData="'''+PIN+''' M54,33.5 A5.5,5.5 0,1 0,54,44.5 A5.5,5.5 0,1 0,54,33.5 Z"/>
</vector>
'''
    put('android/app/src/main/res/drawable/ic_launcher_monochrome.xml',mono)
    put('android/app/src/main/res/values/icon_colors.xml',f'<resources><color name="icon_background">{BG}</color></resources>\n')
    for version in (26,33):
        adaptive='<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n    <background android:drawable="@color/icon_background"/>\n    <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n'
        if version>=33: adaptive+='    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>\n'
        adaptive+='</adaptive-icon>\n'
        for name in ('ic_launcher','ic_launcher_round'):
            put(f'android/app/src/main/res/mipmap-anydpi-v{version}/{name}.xml',adaptive)
    for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
        render(size).save(ROOT/f'android/app/src/main/res/mipmap-{density}/ic_launcher.png')
        render(size,round_icon=True).save(ROOT/f'android/app/src/main/res/mipmap-{density}/ic_launcher_round.png')
    render(1024).save(ROOT/'assets/logo/app_icon.png')
    for platform in ('ios/Runner','macos/Runner'):
        folder=ROOT/platform/'Assets.xcassets/AppIcon.appiconset'
        contents=folder/'Contents.json'
        if not contents.exists():continue
        for item in json.loads(contents.read_text())['images']:
            if not item.get('filename'):continue
            size=round(float(item['size'].split('x')[0])*float(item['scale'].removesuffix('x')))
            icon=render(size,square=platform.startswith('ios'))
            if platform.startswith('ios'):icon=icon.convert('RGB')
            icon.save(folder/item['filename'])
    render(256).save(ROOT/'windows/runner/resources/app_icon.ico',format='ICO',sizes=[(x,x) for x in [16,24,32,48,64,128,256]])
    for file in (ROOT/'web').rglob('*.png'):
        if 'Icon' in file.name or file.name=='favicon.png':
            with Image.open(file) as old:size=old.width
            render(size,square='maskable' in file.name).save(file)
    preview=Image.new('RGB',(1000,360),'#F1F6F8')
    for x,size in [(32,256),(335,144),(535,96),(685,48),(800,24)]:
        icon=render(size);preview.paste(icon,(x,(360-size)//2),icon)
    preview.save(ROOT/'assets/logo/app_icon_preview.png')
    print('Generated adaptive, themed, legacy and platform icons from the new vector mark.')


if __name__=='__main__':main()
