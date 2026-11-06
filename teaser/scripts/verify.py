"""Decode and inspect the complete export; create QA sheets and metadata."""
from pathlib import Path
import sys
BASE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE / '.deps'))
import json
import re
import struct
import subprocess
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import imageio_ffmpeg

OUT = BASE / 'output'
VIDEO = OUT / 'talentlink-teaser-40s.mp4'
ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
reader = imageio_ffmpeg.read_frames(str(VIDEO), pix_fmt='rgb24')
meta = next(reader)
count = 0
minimum = 255.0
samples = {}
for frame in reader:
    image = np.frombuffer(frame, dtype=np.uint8).reshape(1080, 1920, 3)
    minimum = min(minimum, float(image[::36, ::36].mean()))
    # Review one frame per second and both sides of every chapter transition.
    edges = [4, 9, 12, 18, 23, 27, 32, 36]
    if count % 30 == 0 or count in [round(t*30)+o for t in edges for o in [-1, 1, 6]]:
        samples[count] = Image.fromarray(image).resize((480, 270), Image.Resampling.LANCZOS)
    count += 1

font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 16)
items = sorted(samples.items())
for page in range((len(items)+19)//20):
    selected = items[page*20:(page+1)*20]
    sheet = Image.new('RGB', (1920, 1490), '#e9e3e0')
    d = ImageDraw.Draw(sheet)
    for j, (frame, image) in enumerate(selected):
        x, y = (j%4)*480, (j//4)*298
        sheet.paste(image, (x,y))
        d.text((x+10,y+273), f'{frame/30:05.2f}s / frame {frame}', fill='#241e23', font=font)
    sheet.save(OUT / f'qa-export-{page+1}.jpg', quality=92)

result = subprocess.run([ffmpeg, '-hide_banner', '-i', str(VIDEO), '-vn',
    '-af', 'loudnorm=I=-16:TP=-1:LRA=11:print_format=json', '-f', 'null', '-'],
    capture_output=True, text=True, check=True)
match = re.search(r'\{\s*"input_i".*?\}', result.stderr, re.S)
loudness = json.loads(match.group()) if match else {}

# Inspect MP4 atom order to verify streaming-friendly fast start.
atoms = []
with VIDEO.open('rb') as f:
    while True:
        pos = f.tell()
        header = f.read(8)
        if len(header) < 8:
            break
        size, kind = struct.unpack('>I4s', header)
        if size == 1:
            size = struct.unpack('>Q', f.read(8))[0]
        if size == 0:
            break
        atoms.append({'type':kind.decode('ascii'), 'offset':pos})
        f.seek(pos+size)
types = [a['type'] for a in atoms]

checks = {
    'duration_40_seconds': abs(meta['duration']-40) < .04,
    'frame_count_1200': count == 1200,
    'resolution_1920_1080': list(meta['size']) == [1920,1080],
    'frame_rate_30': meta['fps'] == 30,
    'codec_h264': meta['codec'] == 'h264',
    'no_unintended_black_frames': minimum > 50,
    'audio_near_minus16_lufs': abs(float(loudness['input_i'])+16) <= 1,
    'audio_true_peak_below_minus1_dbtp': float(loudness['input_tp']) <= -1,
    'fast_start': types.index('moov') < types.index('mdat'),
    'audio_aac_stereo_48khz': bool(re.search(r'Audio: aac.*48000 Hz, stereo', result.stderr)),
}
report = {'metadata':meta, 'decoded_frames':count, 'minimum_sampled_frame_brightness':minimum,
    'loudness':loudness, 'mp4_atoms':atoms, 'checks':checks,
    'file_bytes': VIDEO.stat().st_size,
    'notes':['Actual Flutter-rendered app frames with editorial motion and tap indicators.',
      'Fictional offline data; simulated interview is labelled.',
      'Original instrumental; no voiceover.',
      'Source UI animation sampling approximately 12 fps; export 30 fps.']}
(OUT / 'verification.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
if not all(checks.values()):
    raise SystemExit('Export failed one or more validation checks.')
