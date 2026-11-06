"""Compose the 40s teaser from actual Flutter captures and original music.

Run from project root: py teaser/scripts/render.py [--preview]
Dependencies live in ignored teaser/.deps; no external media is downloaded.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'teaser'
sys.path.insert(0, str(BASE / '.deps'))
import argparse
import bisect
import functools
import json
import math
import subprocess
import wave
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import imageio_ffmpeg

W, H, FPS = 1920, 1080, 30
CAP = BASE / 'captures'
OUT = BASE / 'output'
ASSETS = BASE / 'assets'
OUT.mkdir(exist_ok=True, parents=True)
ASSETS.mkdir(exist_ok=True, parents=True)
TIMELINE = json.loads((BASE / 'timeline.json').read_text(encoding='utf-8'))
SOURCE = json.loads((CAP / 'frames.json').read_text())
SHOTS = TIMELINE['shots']
STARTS = [f['start'] for f in SOURCE['frames']]
FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
INK = '#241e23'
RED = '#b92332'
MUTED = '#71676c'
FONT_DIR = Path('C:/Windows/Fonts')


@functools.lru_cache(maxsize=32)
def font(size, bold=False):
    return ImageFont.truetype(str(FONT_DIR / ('seguisb.ttf' if bold else 'segoeui.ttf')), size)


def smooth(x):
    x = max(0, min(1, x))
    return x * x * (3 - 2 * x)


def label(draw, xy, text, size=22, fill=MUTED, bold=False):
    draw.text(xy, text, font=font(size, bold), fill=fill)


def rounded(draw, box, radius=20, fill=None, outline=None, width=1):
    draw.rounded_rectangle(tuple(round(v) for v in box), radius, fill=fill, outline=outline, width=width)


def background():
    y, x = np.mgrid[:H, :W].astype(np.float32)
    g = np.exp(-(((x - 1490) / 700) ** 2 + ((y - 470) / 740) ** 2))
    rgb = np.empty((H, W, 3), dtype=np.uint8)
    for c, (base, tint) in enumerate([(250, 10), (248, 24), (246, 22)]):
        rgb[:, :, c] = np.clip(base - g * tint, 0, 255)
    img = Image.fromarray(rgb, 'RGB')
    d = ImageDraw.Draw(img)
    d.ellipse((1050, 130, 1900, 980), outline='#e8d9db', width=2)
    d.ellipse((1130, 210, 1820, 900), outline='#eddddf', width=2)
    # Fine editorial grid, restricted to the background of the phone.
    for px in range(1100, 1901, 40):
        for py in range(140, 981, 40):
            d.ellipse((px, py, px + 2, py + 2), fill='#dfcdd0')
    return img


BG = background()
LOGO = Image.open(ROOT / 'assets/logo-talentlink.png').convert('RGBA')
LOGO.thumbnail((290, 86), Image.Resampling.LANCZOS)
SW, SH = 430, round(430 * 844 / 390)
PW, PH = SW + 28, SH + 28
SCREEN_MASK = Image.new('L', (SW, SH))
ImageDraw.Draw(SCREEN_MASK).rounded_rectangle((0, 0, SW, SH), radius=32, fill=255)
PHONE = Image.new('RGBA', (PW + 100, PH + 100))
sd = ImageDraw.Draw(PHONE)
rounded(sd, (50, 57, PW + 50, PH + 57), 48, fill=(55, 27, 36, 70))
PHONE = PHONE.filter(ImageFilter.GaussianBlur(20))
pd = ImageDraw.Draw(PHONE)
rounded(pd, (50, 50, PW + 50, PH + 50), 46, fill='#241f23', outline='#53464c', width=2)
rounded(pd, (55, 55, PW + 45, PH + 45), 42, outline='#78646d', width=1)
# Side buttons belong to the editorial device frame, not the app interface.
rounded(pd, (PW + 49, 210, PW + 53, 282), 2, fill='#51434b')
rounded(pd, (46, 180, 50, 228), 2, fill='#51434b')


@functools.lru_cache(maxsize=160)
def screenshot(file):
    with Image.open(CAP / file) as image:
        return image.convert('RGB').resize((SW, SH), Image.Resampling.LANCZOS)


def source_at(t):
    return SOURCE['frames'][max(0, bisect.bisect_right(STARTS, t + 1e-8) - 1)]


def phone_layer(t, shot):
    image = screenshot(source_at(t)['file'])
    layer = PHONE.copy()
    layer.paste(image, (64, 64), SCREEN_MASK)
    draw = ImageDraw.Draw(layer)
    # Use only actual recorded tap coordinates and times.
    for tap in SOURCE['taps']:
        age = t - tap['time']
        if 0 <= age < .42:
            x = 64 + tap['x'] / 390 * SW
            y = 64 + tap['y'] / 844 * SH
            radius = 12 + age * 38
            alpha = int(200 * (1 - age / .42))
            draw.ellipse((x-radius, y-radius, x+radius, y+radius), fill=(185, 35, 50, int(alpha*.16)), outline=(185, 35, 50, alpha), width=3)
    return layer


def scene_frame(t, shot_index):
    shot = SHOTS[shot_index]
    local = t - shot['start']
    entrance = smooth(local / .65)
    img = BG.copy().convert('RGBA')
    d = ImageDraw.Draw(img)
    img.alpha_composite(LOGO, (140, 81))
    label(d, (143, 178), 'TALENT MANAGEMENT SYSTEM', 17, '#82757c', True)
    label(d, (1410, 29), 'PRODUCT WALKTHROUGH  /  40 SEC', 16, '#8a777e', True)

    content = Image.new('RGBA', (W, H))
    c = ImageDraw.Draw(content)
    dy = round((1 - entrance) * 23)
    label(c, (145, 282 + dy), shot['kicker'], 21, RED, True)
    y = 329 + dy
    size = 88 if shot_index not in [0, 8] else 86
    for i, line in enumerate(shot['title']):
        label(c, (139, y), line, size, RED if i == len(shot['title'])-1 else INK, True)
        y += 100
    y = max(y + 27, 609 + dy)
    for line in shot['body']:
        label(c, (145, y), line, 27, MUTED)
        y += 40
    x = 145
    y += 28
    for tag in shot['tags']:
        tw = c.textlength(tag, font=font(17, True))
        rounded(c, (x, y, x + tw + 32, y + 40), 20, fill='#f3e4e6', outline='#e7ced3')
        label(c, (x + 16, y + 8), tag, 17, RED, True)
        x += tw + 44
    if entrance < 1:
        content.putalpha(content.getchannel('A').point(lambda a: round(a * entrance)))
    img.alpha_composite(content)

    # Editorial device motion is independent of the genuine app captures.
    px = 1198 + round(80 * (1-entrance))
    py = 11 + round(3 * math.sin(t * .7))
    if shot_index == 8:
        # End card reaches its final static layout by 37 seconds.
        py = 11
    img.alpha_composite(phone_layer(t, shot), (px, py))
    d = ImageDraw.Draw(img)

    # Chapter rhythm and a persistent truthful demo disclosure.
    for i, item in enumerate(SHOTS):
        x = 145 + i * 83
        rounded(d, (x, 919, x+65, 923), 2, fill=RED if i <= shot_index else '#dfd6d7')
    label(d, (145, 941), f'{shot_index+1:02d} / 09', 18, MUTED, True)
    label(d, (145, 999), 'OFFLINE DEMO  /  FICTIONAL DATA', 21, '#7c6670', True)
    return img.convert('RGB')


def render_frame(t):
    index = min(len(SHOTS)-1, max(0, bisect.bisect_right([s['start'] for s in SHOTS], t)-1))
    shot = SHOTS[index]
    frame = scene_frame(t, index)
    # Six-frame dissolve between editorial chapters; does not invent app actions.
    if index > 0 and t - shot['start'] < .20:
        before = scene_frame(shot['start'] - 1/FPS, index-1)
        frame = Image.blend(before, frame, smooth((t-shot['start'])/.20))
    if t < .3:
        frame = Image.blend(Image.new('RGB', (W, H), '#faf8f6'), frame, smooth(t/.3))
    return frame


def add_signal(stereo, signal, seconds, pan=0.0, gain=1):
    start = round(seconds * 48000)
    if start >= len(stereo):
        return
    n = min(len(signal), len(stereo)-start)
    stereo[start:start+n, 0] += signal[:n] * gain * math.sqrt((1-pan)/2)
    stereo[start:start+n, 1] += signal[:n] * gain * math.sqrt((1+pan)/2)


def note(midi):
    return 440 * 2 ** ((midi-69)/12)


def music():
    """Original 120 BPM instrumental, synthesized without samples."""
    sr = 48000
    audio = np.zeros((40*sr, 2), dtype=np.float32)
    rng = np.random.default_rng(724)
    # D minor / B-flat / F / C, two bars per chord.
    chords = [[50, 53, 57], [46, 50, 53], [48, 53, 57], [48, 52, 55]]
    for block in range(10):
        chord = chords[block % 4]
        t = np.arange(int(4.5*sr), dtype=np.float32)/sr
        env = np.minimum(t/.35, 1) * np.minimum((4.5-t)/.7, 1)
        pad = sum(np.sin(2*np.pi*note(n+12)*t + .4*np.sin(2*np.pi*.15*t)) for n in chord)/3
        add_signal(audio, pad*env, block*4, gain=.12)
    for beat in range(80):
        second = beat*.5
        chord = chords[(beat//8) % 4]
        # Rounded bass and soft kick.
        t = np.arange(int(.6*sr), dtype=np.float32)/sr
        bass = np.sin(2*np.pi*note(chord[0]-12)*t) * np.exp(-t*5) * np.minimum(t/.012, 1)
        add_signal(audio, bass, second, gain=.14)
        kick = np.sin(2*np.pi*(48*t + 3*(1-np.exp(-t*35)))) * np.exp(-t*19)
        if beat >= 8:
            add_signal(audio, kick, second, gain=.17)
        # Two soft plucks per beat with alternating stereo position.
        for off in [0, .25]:
            index = beat*2 + (1 if off else 0)
            pitch = chord[[0, 1, 2, 1, 0, 2, 1, 2][index % 8]]+24
            t2 = np.arange(int(.8*sr), dtype=np.float32)/sr
            pluck = (np.sin(2*np.pi*note(pitch)*t2) + .23*np.sin(2*np.pi*note(pitch)*2*t2))
            pluck *= np.exp(-t2*7)*np.minimum(t2/.008, 1)
            add_signal(audio, pluck, second+off, pan=.35 if index%2 else -.35, gain=.062)
            add_signal(audio, pluck, second+off+.375, pan=-.25 if index%2 else .25, gain=.018)
        if beat >= 16:
            t3 = np.arange(int(.07*sr), dtype=np.float32)/sr
            noise = rng.normal(0, 1, len(t3)).astype(np.float32)
            hat = np.diff(noise, prepend=0)*np.exp(-t3*65)
            add_signal(audio, hat, second+.25, pan=.3, gain=.014)
    # Gentle harmonic resolution at 36 seconds.
    for n in [62, 65, 69, 74]:
        t = np.arange(4*sr, dtype=np.float32)/sr
        bell = np.sin(2*np.pi*note(n)*t)*np.exp(-t*1.2)*np.minimum(t/.015, 1)
        add_signal(audio, bell, 36, gain=.05)
    # Actual taps receive a quiet, generated click, not a third-party sample.
    for tap in SOURCE['taps']:
        t = np.arange(int(.055*sr), dtype=np.float32)/sr
        click = np.sin(2*np.pi*1350*t)*np.exp(-t*100)*np.minimum(t/.002, 1)
        add_signal(audio, click, tap['time'], gain=.035)
    time = np.arange(len(audio))/sr
    audio *= (np.minimum(time/1.2, 1)*np.minimum((40-time)/1.7, 1))[:, None]
    audio /= max(1, np.max(np.abs(audio))/.85)
    path = ASSETS / 'original-score.wav'
    with wave.open(str(path), 'wb') as wav:
        wav.setparams((2, 2, sr, 0, 'NONE', 'not compressed'))
        wav.writeframes((audio*32767).astype('<i2').tobytes())
    normalized = ASSETS / 'score-master.wav'
    subprocess.run([FFMPEG, '-y', '-hide_banner', '-loglevel', 'error', '-i', str(path),
        '-af', 'loudnorm=I=-16:TP=-1:LRA=11', '-ar', '48000', '-c:a', 'pcm_s16le', str(normalized)], check=True)
    return normalized


def contact_sheet():
    # Include one readable result from every chapter.
    times = [2, 6, 11, 17, 22, 26, 31, 35, 38]
    sheet = Image.new('RGB', (1440, 876), '#eee9e6')
    d = ImageDraw.Draw(sheet)
    for i, t in enumerate(times):
        shot = render_frame(t).resize((480, 270), Image.Resampling.LANCZOS)
        x, y = (i%3)*480, (i//3)*292
        sheet.paste(shot, (x, y))
        d.text((x+10, y+272), f'{t:02d}s / {SHOTS[i]["id"]}', font=font(14, True), fill=INK)
    sheet.save(OUT / 'contact-sheet.jpg', quality=93)
    render_frame(12.7).save(OUT / 'talentlink-teaser-poster.png')


def render():
    score = music()
    target = OUT / 'talentlink-teaser-40s.mp4'
    log = (OUT / 'encode.log').open('w', encoding='utf-8')
    command = [FFMPEG, '-y', '-hide_banner', '-loglevel', 'warning',
        '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s:v', f'{W}x{H}', '-r', str(FPS), '-i', 'pipe:0',
        '-i', str(score), '-map', '0:v:0', '-map', '1:a:0', '-c:v', 'libx264', '-preset', 'medium',
        '-crf', '18', '-pix_fmt', 'yuv420p', '-r', str(FPS), '-frames:v', '1200',
        '-c:a', 'aac', '-b:a', '192k', '-ar', '48000', '-t', '40', '-movflags', '+faststart',
        '-metadata', 'title=TalentLink | Your next opportunity',
        '-metadata', 'comment=Offline prototype. Actual Flutter UI captures; fictional data and simulated interview. Original synthesized instrumental.', str(target)]
    proc = subprocess.Popen(command, stdin=subprocess.PIPE, stderr=log)
    try:
        for i in range(1200):
            proc.stdin.write(render_frame(i/FPS).tobytes())
            if i%150 == 0:
                print(f'Rendered {i}/1200 frames ({i/FPS:.1f}s)', flush=True)
        proc.stdin.close()
        if proc.wait() != 0:
            raise RuntimeError((OUT / 'encode.log').read_text())
    finally:
        log.close()
        if proc.poll() is None:
            proc.terminate()
    print(f'Exported {target}', flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--preview', action='store_true')
    args = parser.parse_args()
    contact_sheet()
    print('Poster and contact sheet ready.', flush=True)
    if not args.preview:
        render()
