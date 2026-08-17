# iOS gapless loop — AVAudioEngine playback core (design)

**Date:** 2026-07-30
**Status:** Proposed — not started. Prerequisite (native loop-region trigger)
**shipped**; see "What already shipped" below.
**Branch context:** `feat/metronome-ios`
**Scope:** `ap/packages/audioplayers_darwin` (the darwin fork). No change to the
Dart app contract, Android, or the method-channel API.

---

## Problem

An iOS user reports loop points are not seamless — an audible gap/stutter each
time the loop restarts. Android is seamless; iOS is not.

### What already shipped (the trigger fix)

We ported the Android native loop region to darwin: `setLoopRegion` on
`WrappedMediaPlayer` installs an `AVPlayer` **boundary-time observer** at the
loop end that wraps in-process (no Dart timer, no method-channel round trip)
and emits `audio.onLoopWrap`. This replaced the Dart-timer + channel path that
let the playhead overshoot the loop end before the seek landed.

**Keep this fix.** It is strictly better than before and is the shipping
baseline. It solved the *trigger*, not the *seek*.

### Why it's still not seamless — measured

Instrumentation in `onLoopBoundaryReached` (overshoot at boundary; wall-clock
of the seek back to start) on device:

```
loop wrap: overshoot=0ms past end(16887ms), seek=66ms, landed=13232ms
loop wrap: overshoot=0ms past end(16887ms), seek=50ms, landed=13232ms
loop wrap: overshoot=0ms past end(16887ms), seek=48ms, landed=13232ms
```

- `overshoot=0ms` — the boundary observer is perfect. Trigger is solved.
- `seek=48–70ms` — `AVPlayerItem.seek(toleranceBefore:.zero, toleranceAfter:.zero)`
  stalls ~50–80 ms re-priming the playback buffer. **This is the gap the user
  hears** (~a 32nd note at 120 BPM).

**Codec ruled out.** Re-tested with an uncompressed 44.1 kHz WAV of the same
audio: `seek=79–84ms` — *worse* than MP3. So the cost is AVPlayer's seek
pipeline (flush + re-prime), not decode. Seek tolerance was rejected as a lever:
loosening it lands a few ms off each wrap, and `ClickTrackTap` re-anchors the
click grid to wherever it lands, so the metronome would drift every loop.

**Conclusion:** any loop built on `AVPlayer.seek` carries this ~50–80 ms gap.
Seamless iOS looping requires wrapping at the **buffer level**, where there is
no seek. That means replacing the AVPlayer playback core with **AVAudioEngine**.

---

## Goal

Loop restart with **no audible gap** (target: sub-few-ms, ideally sample-exact),
while preserving every current behavior and the existing method-channel/event
contract unchanged, so the Dart app and Android are untouched.

Behaviors that must survive the rewrite (current darwin feature set):

- Normal full-song play / pause / resume / stop / release / dispose.
- Precise seek (drag playhead, ±10 s buttons, set-loop-start/end).
- Rate change that **preserves pitch** (currently `player.rate` +
  `audioTimePitchAlgorithm = .timeDomain`).
- Independent pitch shift / transpose that is **time-neutral** (currently the
  Signalsmith stretcher inside `ClickTrackTap`).
- Native in-pipeline **click track** (`ClickGrid`/`ClickSynth`/`ClickTrackConfig`).
- `onDuration`, `onPositionChanged`, `onComplete`, `onSeekComplete`,
  `onLoopWrap`, `onPrepared`, `onLog` events.
- Loop region (gapless is the *new* requirement).
- Background playback + audio-session/interruption/route-change handling.

---

## The click/pitch ordering constraint (read this first)

This is the single most important subtlety and it dictates the whole graph.
Today, in `ClickTrackTap.processBuffer`, per source buffer:

1. The **transpose** (Signalsmith) is applied to the *source* audio in place.
2. The **click** is summed on top of the already-transposed audio.
3. The whole buffer then flows to AVPlayer's `.timeDomain` **rate** stage.

Net semantics we must preserve:

| Stage | Applies to source? | Applies to clicks? |
|---|---|---|
| Transpose (independent pitch) | yes | **no** (clicks added after) |
| Rate (speed, pitch-preserving) | yes | **yes** (clicks added before the rate stage → they stretch with tempo) |

So the required signal order is:

```
source → TRANSPOSE → (mix in CLICKS) → RATE(pitch-preserving) → output
```

`AVAudioUnitTimePitch` bundles transpose (`.pitch`, cents) **and** rate
(`.rate`, pitch-preserving) into one node — you cannot inject clicks *between*
them. Preserving the exact semantics therefore requires transpose and rate to
be **separate** stages with the click mix in the middle. See the graph below.

---

## Target architecture

### Graph

```
AVAudioPlayerNode          ← streams the file (full-song) or a PCM buffer (loop)
      │                      transpose is applied to the buffers *before*
      │                      scheduling (Signalsmith), so the node output is
      │                      already transposed but NOT clicked and NOT rated
      ▼
AVAudioSourceNode (clicks) ─�merge─►  (clicks summed onto the transposed stream)
      ▼
AVAudioUnitTimePitch        ← rate only: .rate = speed, .pitch = 0
 (pitch-preserving stretch)   (clicks stretch with tempo, matching Android)
      ▼
mainMixerNode → outputNode
```

Rationale for keeping **Signalsmith** for transpose (rather than
`AVAudioUnitTimePitch.pitch`): (a) parity with Android, which uses Signalsmith;
(b) it keeps transpose *off* the clicks by construction (transpose is baked into
the source buffers, clicks are added after). Rate stays on the native
`AVAudioUnitTimePitch` node with `.pitch = 0`, which is pitch-preserving.

### Gapless loop mechanism (the core win)

Load the loop region `[start, end]` once into an `AVAudioPCMBuffer` (seconds of
audio → ~MBs, cheap). Two viable schedulers:

- **Preferred — queued segments with per-iteration callbacks.** Schedule the
  loop buffer, then in each `completionHandler`
  (`completionCallbackType: .dataPlayedBack`) emit `onLoopWrap` and schedule the
  *next* iteration. Keep **N=2** iterations queued at all times so the next is
  already primed before the current finishes → the player node plays them
  back-to-back with **no gap**. This gives gaplessness *and* an exact per-wrap
  event for the metronome re-anchor.
- **Simpler fallback — `scheduleBuffer(_:at:options:.loops)`.** Hardware-gapless
  but no per-iteration callback; `onLoopWrap` would then be driven by a
  native timer synced to loop length. Audio is gapless regardless of timer
  jitter, but the metronome re-anchor event is less exact. Use only if the
  queued-segment callback proves fiddly.

Non-loop full-song playback uses `scheduleSegment(file, startingFrame:…)` which
streams from disk (low memory) — no full-song PCM load.

### Click synthesis in-graph

Reuse `ClickGrid` / `ClickSynth` / `ClickTrackConfig` unchanged (they are pure
DSP, already `swift test`-covered). Retire `ClickTrackTap.swift` (the
`MTAudioProcessingTap` + `AVMutableAudioMix` plumbing).

Two placement options for the click:

- **A — bake into the loop buffer** at schedule time: compute pulses over
  `[start, end]` with `ClickGrid.forEachPulseOverlapping` and sum
  `ClickSynth.sampleFloat` into the (already transposed) buffer copy. Gapless,
  deterministic, RT-safe (no realtime synthesis). Re-bake on click-config,
  transpose, or bounds change. Simplest for the loop path.
- **B — `AVAudioSourceNode` click generator** that reads the player node's
  current sample position (via `playerTime(forNodeTime:)`) and synthesizes
  clicks aligned to it. One path for loop *and* full-song, but requires
  sample-accurate position sync between the source node's render block and the
  player node output. This is the trickiest RT piece.

Recommendation: **A for the loop region** (where seamlessness matters) and B (or
the current behavior via a lightweight source node) for full-song. Start with A.

### Position, duration, seeking

- **Position:** `playerNode.playerTime(forNodeTime: playerNode.lastRenderTime)`
  → `sampleTime`, converted to song ms. For the loop path, add the loop
  `startMs` offset (the buffer's frame 0 == loop start). This is item/media time
  and stays correct across rate because the render clock advances at output
  rate while the timePitch node maps it.
- **Duration:** `AVAudioFile.length / sampleRate`.
- **Seek:** `playerNode.stop()` → `scheduleSegment(file, startingFrame: target)`
  → `play()`. No AVPlayer re-prime → fast. Emits `onSeekComplete` (not
  `onLoopWrap`).
- **Completion:** full-song end = last segment's `completionHandler` → `onComplete`
  (replaces `AVPlayerItemDidPlayToEndTime`).

### Audio session, background, interruptions

`AVAudioEngine` needs the session category `.playback`, active. Must handle:
- `AVAudioEngineConfigurationChangeNotification` (route change) → re-wire/restart
  the engine and reschedule from the current position.
- `AVAudioSession.interruptionNotification` → on `.began` the engine stops; on
  `.ended` with `.shouldResume`, restart the engine and reschedule.
- Background: engine runs in the background with the `audio` background mode
  (already set for AVPlayer). Verify the queued-segment top-up keeps working
  when the app is backgrounded (it should — completion handlers still fire).

---

## Files touched

| File | Change |
|---|---|
| `WrappedMediaPlayer.swift` | **Rewrite** playback core: AVPlayer → AVAudioEngine graph. Every method (`setSourceUrl`, `play/resume/pause/stop/release/dispose`, `seek`, `setPlaybackRate`, `setPitchShift`, `setLoopRegion`, position/duration) reimplemented against the engine. |
| `ClickTrackTap.swift` | **Delete** (MTAudioProcessingTap/AudioMix). Click synthesis moves in-graph (bake-into-buffer and/or source node). |
| `ClickGrid.swift`, `ClickSynth.swift`, `ClickTrackConfig.swift` | **Reuse unchanged** (pure DSP). |
| `AudioplayersDarwinPlugin.swift` | Mostly unchanged — same method-channel cases; bodies already delegate to `WrappedMediaPlayer`. `onLoopWrap` emit stays. |
| Signalsmith bridge | Reuse; drive it as a pre-schedule buffer processor instead of from the tap. |
| Dart app / Android | **No change.** Contract preserved. |

---

## Staged rollout (behind a flag, playback never breaks)

Gate the new engine behind a runtime flag (a `setSourceUrl` arg or a debug
default) so AVPlayer stays the fallback until parity is proven. A/B on device by
comparing the `seek=`/gap measurement.

- **Phase 0 — baseline (done).** Native boundary-observer `setLoopRegion`
  (overshoot solved) ships as-is.
- **Phase 1 — engine playback parity.** AVAudioEngine plays a full song:
  play/pause/resume/stop/seek/duration/position/complete. No loop, no click, no
  pitch. Reach behavioral parity with AVPlayer for plain playback. Validate
  background + interruptions + route changes here (highest-risk surface).
- **Phase 2 — gapless loop.** Loop buffer + queued-segment scheduling +
  `onLoopWrap`. This is where the seamlessness win lands. Re-run the gap
  measurement — target sub-few-ms.
- **Phase 3 — click track in-graph.** Bake-into-buffer (option A). Verify grid
  alignment against the current tap output.
- **Phase 4 — rate + transpose.** `AVAudioUnitTimePitch` (rate, pitch=0) +
  Signalsmith transpose pre-schedule. Verify the click/pitch ordering table
  above holds (clicks stretch with tempo, are not transposed).
- **Phase 5 — cutover.** Flip the default, delete `ClickTrackTap.swift` and the
  AVPlayer path, remove the debug logging (`WrappedMediaPlayer.onLoopBoundaryReached`
  and the app's `_nativeLogSubscription`).

Each phase is independently shippable; the app can ride the AVPlayer path until
Phase 5.

---

## Risks

- **Highest-risk surface is not the loop — it's the boring core.** Background
  audio, interruptions, route changes, and session interplay are subtle on
  AVAudioEngine and easy to regress. Phase 1 exists to de-risk exactly this.
- **Click/pitch ordering** (the table above) is the most likely correctness
  regression. It's why transpose stays a separate pre-schedule stage.
- **Signalsmith parity** in a streaming (non-loop) transpose path may need a
  live source node rather than pre-buffering; acceptable to keep full-song
  transpose on a simpler path since the seamless requirement is loop-specific.
- **Memory:** loop buffers are small; full song must stay *streamed*
  (`scheduleSegment` of the file), never fully PCM-loaded.
- **Effort:** rewriting the app's most critical audio path. Realistically
  multiple days including device testing, not an afternoon.

---

## Alternatives considered (and rejected)

- **Keep AVPlayer, tune the seek** (tolerance / format). Rejected: measured
  ~50–80 ms floor, format-independent; tolerance drifts the click grid.
- **`AVQueuePlayer` + `AVPlayerLooper` over a clipped `AVComposition`.** Gapless
  and stays in AVFoundation, but loops a *whole item*, so the loop region must
  be a rebuilt sub-composition, re-created on every bounds edit, with the click
  tap re-attached and positions remapped to full-song time. It fights the
  scrub-in-the-full-song UX (drag / ±10 s / park-outside-loop-while-paused, per
  the recent skip-button commit) and is no cleaner than doing AVAudioEngine
  properly.

---

## Recommendation / decision point

The overshoot fix already shipped is a real, no-downside improvement — the loop
is *tighter* than before even with the residual seek gap. The remaining
~50–80 ms gap is only removable by the AVAudioEngine rewrite scoped above, which
is a multi-day change to the most critical audio path.

**Decision to make:** is fully-seamless iOS looping worth that scope now, or is
the 0 ms-overshoot improvement enough to close out the user complaint for this
release and schedule the engine rewrite as its own project?

If we proceed, do it phase-by-phase behind the flag — do **not** cut over to the
engine in one step.

---

## Validation

Reuse the existing instrumentation (repurpose the `loop wrap: … seek=…ms` log):
after Phase 2, the boundary-to-restart gap should read low single-digit ms (vs
48–84 ms today). Cross-check click-grid alignment and pitch/rate semantics
against the current tap on the same song/loop before deleting `ClickTrackTap`.
