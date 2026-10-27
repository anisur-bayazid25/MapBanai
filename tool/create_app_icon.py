"""Generate adaptive and legacy icons from MapBanai's existing Broadway M.

Run with Pillow installed. The embedded outline preserves the M from the existing SVG wordmark. No font file is required or redistributed.
"""
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
BG = '#FFF8F0'
# Original MapBanai_logo.svg: Broadway M, fill #C04F15.
# Outline extracted from the same Broadway glyph; no font is redistributed.
PANELS = [('#C04F15', [(69.667, 32.889), (76.099, 54.87), (79.02, 64.607), (81.646, 73.429), (82.0, 74.55), (64.061, 74.55), (58.396, 53.69), (46.211, 72.013), (33.701, 54.605), (33.588, 55.006), (33.474, 55.413), (33.36, 55.825), (33.246, 56.243), (33.13, 56.667), (33.014, 57.096), (32.898, 57.531), (32.781, 57.972), (32.663, 58.418), (32.544, 58.87), (32.425, 59.328), (32.305, 59.791), (32.185, 60.26), (32.064, 60.735), (31.942, 61.215), (31.82, 61.701), (31.697, 62.192), (31.573, 62.689), (31.449, 63.192), (31.324, 63.701), (31.199, 64.215), (31.073, 64.734), (30.946, 65.26), (30.818, 65.791), (30.69, 66.328), (30.562, 66.87), (30.433, 67.418), (30.303, 67.971), (30.172, 68.531), (30.041, 69.096), (29.909, 69.666), (29.777, 70.242), (29.729, 70.461), (29.682, 70.674), (29.637, 70.881), (29.592, 71.083), (29.547, 71.279), (29.504, 71.469), (29.461, 71.654), (29.42, 71.833), (29.379, 72.006), (29.339, 72.174), (29.3, 72.337), (29.261, 72.493), (29.224, 72.644), (29.187, 72.79), (29.151, 72.93), (29.116, 73.064), (29.082, 73.192), (29.049, 73.315), (29.016, 73.433), (28.985, 73.544), (28.954, 73.65), (28.924, 73.751), (28.895, 73.846), (28.867, 73.935), (28.839, 74.019), (28.812, 74.097), (28.787, 74.169), (28.762, 74.236), (28.738, 74.297), (28.714, 74.353), (28.692, 74.402), (28.67, 74.447), (28.648, 74.488), (28.625, 74.527), (28.6, 74.565), (28.575, 74.602), (28.547, 74.638), (28.519, 74.672), (28.489, 74.705), (28.457, 74.737), (28.424, 74.768), (28.39, 74.797), (28.355, 74.825), (28.318, 74.851), (28.28, 74.877), (28.241, 74.901), (28.2, 74.923), (28.158, 74.945), (28.114, 74.965), (28.069, 74.984), (28.023, 75.001), (27.975, 75.017), (27.926, 75.032), (27.876, 75.046), (27.824, 75.058), (27.771, 75.069), (27.717, 75.079), (27.661, 75.087), (27.604, 75.094), (27.546, 75.1), (27.486, 75.105), (27.425, 75.108), (27.362, 75.11), (27.298, 75.111), (27.218, 75.11), (27.141, 75.107), (27.066, 75.103), (26.994, 75.097), (26.924, 75.089), (26.857, 75.08), (26.792, 75.068), (26.73, 75.055), (26.671, 75.041), (26.614, 75.024), (26.559, 75.006), (26.507, 74.986), (26.458, 74.965), (26.411, 74.941), (26.366, 74.916), (26.325, 74.889), (26.285, 74.861), (26.248, 74.831), (26.214, 74.799), (26.183, 74.765), (26.153, 74.729), (26.127, 74.692), (26.103, 74.653), (26.081, 74.613), (26.062, 74.57), (26.046, 74.526), (26.032, 74.48), (26.02, 74.433), (26.011, 74.384), (26.005, 74.333), (26.001, 74.28), (26.0, 74.226), (26.001, 74.207), (26.003, 74.183), (26.007, 74.154), (26.013, 74.121), (26.02, 74.083), (26.029, 74.04), (26.04, 73.992), (26.052, 73.94), (26.065, 73.882), (26.081, 73.82), (26.098, 73.754), (26.116, 73.682), (26.136, 73.606), (26.158, 73.524), (26.182, 73.438), (26.207, 73.348), (26.233, 73.252), (26.261, 73.152), (26.291, 73.047), (26.323, 72.937), (26.356, 72.822), (26.39, 72.703), (26.427, 72.579), (26.465, 72.45), (26.504, 72.316), (26.545, 72.177), (26.588, 72.034), (26.633, 71.886), (26.678, 71.733), (26.726, 71.575), (26.775, 71.413), (26.826, 71.246), (28.655, 64.961), (31.842, 54.103), (38.067, 32.889), (54.236, 56.287)])]


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
    vector+='</vector>\n'
    svg+='</svg>\n'
    put('assets/logo/app_icon.svg',svg)
    put('android/app/src/main/res/drawable/ic_launcher_foreground.xml',vector)
    mono=vector.replace('#C04F15','#FFFFFF')
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
    print('Generated adaptive, themed, legacy and platform icons from the existing MapBanai logo M.')


if __name__=='__main__':main()
