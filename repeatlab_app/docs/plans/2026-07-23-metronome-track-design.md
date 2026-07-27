# Metronome track design (grid-locked clicks)

**Date:** 2026-07-23
**Status:** Option A implemented (same day). Option B (native in-pipeline
clicks) implemented for **Android** the same day — see below; iOS keeps
Option A until an MTAudioProcessingTap follow-up.
**Branch context:** `feat/metronome`

## Option B implementation notes (Android, as built)

Clicks are synthesized inside the playback pipeline by a new
`ClickTrackAudioProcessor` in the audioplayers fork
(`ap/packages/audioplayers_android_exo`), inserted **first** in the
DefaultAudioSink processor chain — before the Signalsmith stretcher, where
frames are pure media time at natural rate (ExoPlayer is pinned to 1.0×;
speed lives in Signalsmith). A frame counter anchored by the wrapper on
every seek/stop/setSource places clicks sample-exactly, independent of
playback speed. Grid + synthesis math live in pure-Kotlin `ClickGrid` /
`ClickSynth` (JVM unit tested), mirroring `ClickTrackRenderer`'s constants.

Plumbing mirrors `setPitchShift`: `AudioPlayer.setClickTrack(...)` →
platform interface (UnsupportedError default) → method channel →
`WrappedPlayer.clickTrack` → `ExoPlayerWrapper` → processor (@Volatile
immutable config; toggle/volume are instant, within one audio buffer).

App side: `MediaPlayerHandler.setNativeClickTrack`, and `SongCubit` routes
audio songs per platform — Android → native pipeline (live volume, ~50 ms
coalesce on config resends, seeks/loops/speed are no-ops by construction),
iOS → baked ffmpeg track (unchanged), video → live `precise_metronome`.
`playSong` clears the processor grid so a new song never inherits the old
one; the Android startup purges the now-dead baked-mix cache
(`MetronomeTrackService.clearAll`).

Known bounded imprecision: ExoPlayer resumes at the codec frame at/before a
seek target (≤ ~26 ms constant per seek for AAC/MP3, 0 for WAV). If audible,
the refinement is a ForwardingAudioSink feeding `presentationTimeUs` into
the processor. `REPEAT_MODE_ONE` (gapless internal looping) is unsupported —
the app loops via Dart-side seeks, which re-anchor correctly.

Deferred: iOS MTAudioProcessingTap; post-stretch click placement (crisp
clicks at extreme slowdown); ForwardingAudioSink precision fix.

## Implementation notes (Option A, as built)

- `ClickTrackRenderer` (`lib/core/utils/click_track_renderer.dart`): pure
  Dart 16-bit mono WAV, sine-burst clicks (accent/beat/subdivision at
  different pitch+gain), grid `anchor + offset + n*period` in song time.
- `MetronomeTrackService` (`lib/data/services/metronome_track_service.dart`):
  ffmpeg `amix` (song unity + click at volume, `normalize=0`, `alimiter`)
  into `<appSupport>/metronome_mixes/<songId>/<configHash>.m4a`; one cached
  mix per song, evicted on settings change and on song deletion.
- `MediaPlayerHandler.swapSourceFile`: position/speed/pitch-preserving
  source swap in the audioplayers handler.
- `SongCubit`: audio songs route to the click track (enable = mix + swap,
  settings changes = 600 ms-debounced re-mix, seeks/loops/speed = no-ops by
  construction); **video songs keep the live `precise_metronome` path**
  because their file cannot be swapped. `isMetronomeGenerating` drives a
  busy spinner in the metronome panel.
- Click volume is baked into the mix (re-mix on slider release, not drag).

## Problem

The current metronome is a free-running native click engine
(`precise_metronome`, wrapped by `lib/data/services/song_metronome.dart`). It is
phase-aligned to the song exactly once, at start, via
`startAligned(offsetMs:)`. The song itself plays on a completely different
clock (ExoPlayer / audioplayers).

Two independent clocks can be aligned at one moment, but:

- Every **seek**, **loop wrap**, or **speed change** breaks the alignment.
- Even without discontinuities, the two clocks slowly **drift** apart.
- Re-anchoring on `seekEvents` (the obvious patch) always lags by the
  position-report latency, so each loop wrap produces one or two audibly
  wrong clicks. This is structural, not a tuning problem.

Since RepeatLab is a *looping* practice app, discontinuities are the common
case, not the edge case.

## How other apps solve it

Both honest architectures share one property: **the clicks live on the song's
clock, not their own.**

1. **Click as an audio track ("click stem")** — Moises' approach. Beat
   detection produces a beat map, a click track is rendered against it and
   mixed as just another stem. Loop, seek, slow down — the click cannot drift
   because it *is* part of the audio timeline.
2. **Click synthesized inside the playback engine** — the DAW approach
   (Logic, Ableton; also Capo/Anytune). The metronome is generated in the
   audio render callback from the transport's current *sample position* mapped
   through the beat grid. Sample-accurate by construction.

What does **not** work: a second player playing a click file "in sync" with
the song player. Two player instances don't share a clock; this just recreates
the drift problem.

## Option A (recommended): pre-rendered click track, mixed via ffmpeg

We already ship `ffmpeg_kit_flutter_new_min`, which makes this cheap:

1. Render a click-track WAV from the existing grid (BPM + tap-to-align anchor
   + time signature + subdivision + accents). This is silence with short click
   samples placed at beat times — writable as raw PCM in pure Dart, no ffmpeg
   needed for this step.
2. Mix it with the song via ffmpeg (`amix` + volume filter) into a cached
   file, keyed by `(song, bpm, anchor, time signature, subdivision, click
   volume)`.
3. Play the mixed file through the **existing single-player pipeline**,
   unchanged.

### Why it fits

- **Loop / seek / speed / pitch are all correct for free** — there is only one
  timeline.
- **Frequent speed changes cost nothing.** The speed slider acts on the mixed
  stream inside the player; clicks slow down and speed up in lockstep with the
  music, no re-render. (Under the current architecture, speed changes are one
  of the main sync-breakers.)
- Reuses the existing player, speed/pitch fork, and `SongCubit` orchestration.
- Same architecture as the market leader (Moises).
- Clean upgrade path: swap the uniform BPM grid for a detected beat map
  (tempo map) later and everything downstream stays identical. The
  oscillator-style metronome can never handle variable tempo well.

### Trade-offs (eyes open)

- **Toggling and metronome-config changes are not instant.** On/off means a
  position-preserving source swap (brief gap); click volume / subdivision /
  signature changes mean a re-mix (seconds; maskable with debounce or by
  pre-rendering 2–3 volume steps). Only metronome-specific knobs pay this
  cost — speed does not.
- **Stretched-click quality at extreme slowdowns** (~50–60%): the
  time-stretcher smears transients, so baked clicks can sound soft/"flammy".
  Mitigate by choosing a click sample that survives stretching (short
  sine-burst / woodblock, not a sharp tick). Moises accepts the same
  trade-off.
- **Pitch shift shifts the click's pitch** along with the song. Cosmetic.
- **Storage:** one mixed copy per song per config. Needs cache eviction;
  simplest policy is "regenerate on settings change, keep only latest".
- **Count-in / click-while-paused** cannot come from the baked track — keep
  `precise_metronome` for exactly that role. The two approaches compose.
- **Constant-BPM limitation remains:** for songs recorded without a click,
  a uniform grid drifts off the music — but no worse than today's metronome,
  and this architecture is the one that fixes it later via beat detection.

## Option B (v2 candidate): native in-engine synthesis

Generate clicks inside the playback pipeline from the sample position:

- Android: custom `AudioProcessor` injected into ExoPlayer.
- iOS: `AVAudioEngine` tap / source node.
- Sample-position → beat mapping must stay correct under time-stretch and the
  `setPitchShift` fork; new platform-channel APIs; changes land in the forked
  `audioplayers` and must be maintained against upstream indefinitely.

**Pros:** sample-accurate, instant toggle/volume, clicks synthesized *after*
the stretcher (crisp at any speed, unshifted pitch), free count-in.
**Cons:** two platforms of native audio work, hard to test, high maintenance.

## Effort estimate (solo implementation)

| | Option A (ffmpeg pre-mix) | Option B (native) |
|---|---|---|
| Scope | Pure Dart + one ffmpeg call + cache + source swap in `SongCubit` | Native audio code on both platforms, in the audioplayers fork |
| Effort | ~1–2 focused sessions | ~4–6× that; multi-week |
| Risk | Low, fully unit-testable | High, debugged by ear on devices |

## Recommendation

Ship **Option A**. Keep `precise_metronome` only for count-in / standalone
practice clicks. Treat **Option B** as a v2 only if real users complain about
toggle latency or stretched-click quality at extreme slowdowns.

## Open questions

- Is metronome config per-song and stable within a session (set once via
  tap-to-align, then practice)? Current UX suggests yes — this makes the
  re-mix cost nearly invisible.
- Pre-render volume steps vs. re-mix on volume change?
- Cache policy and size budget for mixed files.
- Click sample choice that survives time-stretching well.
