# TalentLink 40-second teaser

## Delivery

- `output/talentlink-teaser-40s.mp4`: 40-second 1080p product teaser with an original
  instrumental score and captions.
- `output/talentlink-teaser-poster.png`: poster frame.
- `output/contact-sheet.jpg`: one representative frame from each chapter.
- `output/verification.json`: export metadata and validation results, generated
  during final verification.

The video features real Flutter-rendered app screens, not invented UI mockups.
Captures are edited to fit the storyboard and framed with editorial graphics.
The app uses fictional offline data, and the interview is explicitly simulated.
There is no voiceover. No media is uploaded or published by these scripts.

Verified export: 40.0 seconds, 1,200 frames, 1920 x 1080 at 30 fps, H.264/yuv420p,
AAC stereo at 48 kHz, fast-start metadata, 4,311,602 bytes. Measured audio:
-15.81 LUFS integrated and -1.67 dBTP true peak. Every frame decoded successfully;
representative frames and chapter-transition sheets were visually inspected.

## Reproduce on this Windows machine

Run commands from the project root. The SDK is at `D:/Flutter/flutter`; adapt the
SDK and font paths in `capture_test.dart` if moving to another machine.

```powershell
py -m pip install --target teaser/.deps -r teaser/requirements.txt

# Process-scoped exception for this installed SDK's previous Windows ownership.
$env:GIT_CONFIG_COUNT = '1'
$env:GIT_CONFIG_KEY_0 = 'safe.directory'
$env:GIT_CONFIG_VALUE_0 = 'D:/Flutter/flutter'
& D:/Flutter/flutter/bin/flutter.bat test teaser/capture_test.dart --no-pub

py teaser/scripts/render.py --preview
py teaser/scripts/render.py
py teaser/scripts/verify.py
```

The capture test exercises registration, login, save, apply, simulated interview,
training enrolment, calendar, company directory and the same candidate's profile.
It preloads the actual app logo and Flutter Roboto/Material icon fonts, replacing
the test harness's placeholder Ahem font. Every source PNG comes from Flutter's
real renderer. Short UI animation intervals are sampled at approximately 12 fps;
the 30 fps edit adds smooth device/caption motion and repeats held app frames.
Tap rings use recorded positions from actual actions. No pretend native app
animations are inserted.

`timeline.json` defines the nine chapters and captions. `captures/frames.json`
records source-frame timings and tap coordinates. Date labels follow the demo's
relative dates, so later captures may show different calendar dates.

The capture harness uses mocked preferences to isolate its fictional account.
It does not clear or modify the user's saved app accounts. Prepared profile and
résumé details belong to the same Nadia Rahman account registered in the video.

## Audio and encoding

The render script synthesizes a deterministic original stereo score at 48 kHz,
normalizes it toward -16 LUFS with a -1 dBTP ceiling, and fades its ending.
The export uses H.264, CRF 18, yuv420p, 30 fps, AAC stereo 192 kbps, and fast-start
metadata. No third-party audio samples are used; see `assets/CREDITS.md`.

Captures, dependencies, WAV intermediates and rendered QA frames are ignored by
Git. At the user's request, the final MP4, poster and verification report are
included in the private repository alongside scripts, timeline and credits.
