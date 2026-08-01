# Improving slow-down (time-stretch) quality on iOS

_Status: analysis / proposal — no code changed. Written 2026-08-01._

## TL;DR

Slowing a song down on iOS is done by **AVPlayer** with the pitch-preserving
algorithm set to **`.timeDomain`** — Apple's *cheapest, lowest-quality* option.
Switching it to **`.spectral`** is a one-line change and is very likely the
single biggest quality win. A separate, larger option is to route the
time-stretch through the **Signalsmith Stretch** library that is already
bundled (currently used for pitch only). Note that **video** slowdown uses a
different engine entirely (libmpv `scaletempo`) and is not affected by the
AVPlayer change.

## How slowing down works today

There are **two independent DSP paths**, and it matters which does what:

| Feature | iOS mechanism | Preserves |
|---|---|---|
| Speed / tempo (slow-down) | `AVPlayer.rate` + `AVAudioTimePitchAlgorithm.timeDomain` (Apple built-in) | pitch |
| Independent pitch / key | **Signalsmith Stretch** C++ lib inside an `MTAudioProcessingTap` | time (pitch-only) |

- Live engine: `RepeatlabAudioplayersServiceHandler` (a local fork of
  `audioplayers`, path deps under `../ap/packages/...`).
- User slow-down range: **0.5×–2.0×**; pitch range **±1250 cents** (±12.5
  semitones), converted `pow(2, cents/1200)` before hitting the native layer.
- The quality of a slowed-down song is therefore governed **entirely by
  `.timeDomain`**, which is a time-domain (WSOLA-style) stretcher. On
  polyphonic music slowed toward 0.5× it smears transients (drum hits get
  "flammy") and adds a warbly/phasey character. That is the likely artifact.
- Signalsmith is currently wired in **pitch-only mode** — it feeds *n* frames in
  and *n* out, so its time ratio is locked at 1.0. It is a transposer today, not
  a tempo changer, even though the library itself is a full time-stretcher.

### Key files

- `lib/data/services/repeatlab_audioplayers_service_handler.dart` — Dart mapping
  (speed 0.5–2.0×, pitch ±1250 cents, `pow(2, cents/1200)`).
- `lib/features/song/cubit/song/song_cubit.dart` — app logic
  (`setSpeedByMultiplier`, `setSpeedByBpm`, `setPitchSemitones`, …).
- `../ap/packages/audioplayers_darwin/.../WrappedMediaPlayer.swift` —
  `AVPlayer.rate` + `audioTimePitchAlgorithm = .timeDomain` (~line 311).
- `.../ClickTrackTap.swift` — `MTAudioProcessingTap` running the pitch DSP and
  mixing the metronome click. Pitch DSP is **bypassed at unity pitch**.
- `.../Sources/SignalsmithBridge/SignalsmithProcessor.{mm,h}` +
  `vendor/signalsmith-stretch/signalsmith-stretch.h` — the actual pitch-shift
  DSP.
- `.../AudioplayersDarwinPlugin.swift` — platform channel
  (`setPlaybackRate`, `setPitchShift`).
- `lib/data/services/video_player_handler.dart` — media_kit/libmpv `scaletempo`
  path (**video only**, separate engine).

## Options, ranked by effort vs. payoff

### Option A — Switch `.timeDomain` → `.spectral` (one line, biggest single win)

`AVAudioTimePitchAlgorithm.spectral` is Apple's phase-vocoder algorithm —
highest quality, and it preserves formants (keeps vocals natural). Apple
recommends `.spectral` for music and `.timeDomain` for voice.

- **Cost:** higher CPU and some added latency, both handled internally by
  AVPlayer. A non-issue for a single stream on any modern iPhone; heavier on
  very old devices.
- **Risk:** low — same API, supported enum value.
- **Try first.** Likely ~90% of the perceived improvement for near-zero
  engineering.

### Option B — Route the time-stretch through Signalsmith too (best quality + cross-platform parity, bigger change)

The bundled Signalsmith library *is* a full time-stretcher; only its pitch mode
is used today. Every song already flows through the tap, so the infrastructure
exists. Do the slow-down there instead of via `AVPlayer.rate`.

- **Upside:** one high-quality DSP engine, identical sound on iOS and Android,
  full control over quality (block size, formant preservation), and it stops
  **stacking two different engines** when a user slows down *and* shifts pitch
  at once (today that's `.timeDomain` on top of Signalsmith — compounding
  artifacts).
- **Cost:** significant. A tap can't change its own output duration, so playback
  rate must be decoupled from AVPlayer's clock — feed the tap faster/slower than
  real time, manage buffering, and re-derive position / seek / loop-boundary
  math against the stretch. The loop-timing code is sensitive.
- Signalsmith config currently uses `presetDefault`; `presetCheaper` also exists,
  so quality/CPU is tunable.

### Option C — Pick the algorithm by ratio / expose a quality toggle

Keep `.timeDomain` near 1.0× (transparent and cheap) and switch to `.spectral`
only past some slow-down threshold, or offer a "High quality (uses more
battery)" setting. Small change; good for battery-sensitive users. Best combined
with Option A.

## Important caveat: video uses a different engine

There is a **second, separate engine for video** (`video_player_handler.dart`,
media_kit/libmpv). Its slow-down quality comes from libmpv's **`scaletempo`**
filter, *not* AVPlayer. Consequences:

- Option A only improves **audio-file** playback. Slowed **video** (or audio via
  the video path) is untouched by the AVPlayer change.
- libmpv has better options (`scaletempo2`, or `af=rubberband` if built with
  librubberband) — a parallel fix would be needed there.
- Decide based on usage: if slow-down is mostly plain audio files, Option A
  alone covers most of it.

## Recommendation

1. **Do Option A first** and A/B it on a real device with drum-heavy and vocal
   material at 0.5×. One line, low risk, targets the exact bottleneck.
2. Only pursue **Option B** if `.spectral` still isn't enough, or you
   specifically want iOS↔Android parity and to fix the simultaneous
   slow-down + pitch-shift stacking case.
3. **Option C** is the polish layer on top of A.
4. Separately decide whether the **video** path warrants a matching libmpv tweak.

## Testing notes

- Because the Signalsmith pitch DSP is bypassed at unity pitch, the `.spectral`
  change is orthogonal to the tap when a user is *only* slowing down. The
  metronome-sync / loop-boundary concern only needs verifying in the
  **slow-down + pitch-shift simultaneously** case (narrower to test).
- Verify metronome click sync and loop-boundary timing still hold with the added
  spectral latency — the tap already does latency compensation for pitch, so
  it's likely fine, but test rather than assume.
