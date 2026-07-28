# RepeatLab – Feature Roadmap (based on cancellation reasons)

Prioritized by frequency + feasibility from the cancellation-reason analysis. For each priority: what the feature should do, not the technical implementation. Implementation plans follow in the second half of this document.

---

## Priority 1 – High Impact

### 1. In-App Audio Recording
**Why:** Most frequent concrete feature request (9× over 10 months).
**What it should do:**
- Record an audio track directly in the app (microphone) instead of only importing external files.
- The recording is added to the library like a normal song — usable with all existing functionality (loops, speed, pitch, metronome).
- Start/stop/pause while recording.
- Name the recording and save it directly.
- Optional (later): play back an existing song while recording along with it (overdub / "play along with the music") — this was an explicitly mentioned use case (practicing your own voice in a multi-part piece).

### 2. Loop Repetitions with Count/Timer
**Why:** Users expect to define how often or how long a loop plays — currently a loop only runs endlessly or is switched manually.
**What it should do:**
- Configurable per loop: "repeat X times" (enter a number) OR "repeat for Y minutes" (timer).
- After reaching the count/time: automatically stop, jump to the next loop, or continue playing the song normally (selectable).
- Live indicator during playback: "Repetition 3 of 8" or similar.

### 3. Loop Re-Entry Without Delay (Bug Fix)
**Why:** Complaint about noticeable latency when jumping from the loop end back to the loop start — contradicts the advertised seamless looping.
**What it should do:**
- When the loop end point is reached, the jump back to the start point must happen without an audible gap/delay, regardless of loop length or playback speed.

---

## Priority 2 – Medium Impact, Good Feasibility

### 4. Set Loop Start Point by Tapping Instead of Only Dragging
**Why:** Concrete, easily fixable UX complaint.
**What it should do:**
- When setting a loop point: tap directly on the desired position in the waveform to place the loop point there — not only possible via dragging/sliding.
- Fine-tuning via dragging remains available in addition.

### 5. Simplify Onboarding / First Steps
**Why:** Mentioned multiple times: "too complicated", "hard to use", "can't figure out how to create good loops/tracks".
**What it should do:**
- Short, focused getting-started flow directly on the first song: import song → set first loop → play, in at most 3 steps, with visual hints directly on the relevant controls (not a pure text tour).
- An easily discoverable "How do I create a good loop/track?" help text or short video directly in the loop editor.

### 6. Reminder Before Trial Ends
**Why:** Several cancellations due to accidental purchase / missed trial end — not a product defect, but avoidable frustration.
**What it should do:**
- Push notification approx. 1–2 days before the free trial expires, explaining how to cancel and that the trial converts into a paid subscription.

---

## Priority 3 – Investigate / Later

### 7. Support More Audio Formats Reliably
**Why:** Occasional, unspecific complaints about format problems.
**What it should do:**
- On failed import: a clear error message stating which format/problem occurred instead of silent failure — as a first step, before adding new formats.

### 8. YouTube Import
**Why:** Demand exists (2×), but legally/store-wise risky.
**What it should do:**
- For now only investigate/research, do not implement directly. If pursued: only via officially permitted routes (e.g. the user downloads a file themselves and imports it normally) — no direct in-app download of YouTube content.

### 9. Feature Comparison with "Music Speed Changer"
**Why:** One user felt the app was weaker in comparison, without giving details.
**What it should do:**
- Not a feature of its own — research task: review the competitor app's feature set and identify open gaps before prioritizing this.

---

*Basis: cancellation-reason analysis (RepeatLab_Kuendigungsgruende.xlsx), data period 2025-05-19 – 2026-07-11.*

---
---

# Implementation Plans

How each roadmap item could be introduced in RepeatLab, based on the current architecture (Flutter, Cubit/BLoC state management, SoLoud + AudioPlayers playback, media_kit for video, Sembast persistence, `PremiumSubscriptionCubit` gating, 16-language l10n via ARB files).


## 1. Tap to Set Loop Points on the Waveform

- The waveform widget (`lib/features/song/widgets/wave_form_soloud.dart`) already translates horizontal positions to song positions for scrubbing. Add a tap handler in "loop editing" context:
  - When the user is placing/adjusting a loop (loop active or a dedicated "edit" state), a single tap on the waveform moves the nearest loop handle (start or end, whichever is closer) to the tapped position; scrub-on-tap remains the behavior outside editing.
  - Alternative if mode-detection is ambiguous: long-press on the waveform opens a small context action "Set loop start here / Set loop end here".
- Keep drag-to-fine-tune unchanged; the tap is only coarse placement.
- Guard rails: tapping before the loop start while adjusting the end (and vice versa) shows the existing validation snackbar (`SnackbarHelper.showError`) already used for invalid loop bounds.
- Add a coach mark to the existing tutorial system advertising the new gesture once.
- Free feature (it improves the free single-loop flow too); no gating changes.


## 2. Loop Re-Entry Without Delay (Bug Fix)

### Investigation results (2026-07-27)

The complaint is reproducible from the code alone: the loop wrap is entirely reactive and Dart-driven, so the song always plays *past* the loop end before jumping back. The delay users hear is the sum of three stages:

**Stage 1 — Late detection (up to ~200 ms).** Loop wrapping lives in `RepeatlabAudioplayersServiceHandler` (`lib/data/services/repeatlab_audioplayers_service_handler.dart`): a position listener plus a 200 ms fallback `Timer.periodic` check `if (position >= loop.end) seek(loop.start)`. In the foreground, positions come from the audioplayers `FramePositionUpdater`, which fires once per UI frame and does an async platform-channel `getCurrentPosition()` round trip per tick; in the background frame callbacks stop entirely and only the 200 ms timer remains. So the end point is detected 1 frame to 200 ms *after* the audio has already passed it.

**Stage 2 — Slow seek path (several platform-channel round trips).** The wrap goes through the general `seek()` queue → `_performSeek()`, which first awaits `getDuration()` and `getCurrentPosition()` (two more channel round trips) before finally calling `audioPlayer.seek()`. These guards are useful for user seeks but pure overhead for a loop wrap whose target is already known and validated.

**Stage 3 — Engine seek latency.**
- **Android** (custom audioplayers fork, `../ap/packages/audioplayers_android_exo`, ExoPlayer backend): `seekTo` flushes the audio pipeline, including the Signalsmith time-stretch/pitch processor and the click-track processor, then re-buffers — the fork even has explicit anchor-before-seek handling for the click grid, confirming seeks are pipeline flushes. MP3 seeking in ExoPlayer is additionally only frame-accurate.
- **iOS** (fork of `audioplayers_darwin`, AVPlayer backend): `WrappedMediaPlayer.seek` calls `currentItem.seek(to:)` **without** `toleranceBefore/toleranceAfter` — AVPlayer's default tolerance is unbounded, so the wrap lands *near* the loop start, not on it, and precise re-buffering after a seek is where AVPlayer is slowest. This also explains "the loop doesn't restart exactly where I set it" reports if they appear.
- **Video** (`video_player_handler.dart`, media_kit): same reactive pattern on media_kit's position stream; acceptable for the video beta, out of scope for the first fix.

Notably, full-song repeat already wraps gaplessly because it's native (`ReleaseMode.loop` → ExoPlayer `REPEAT_MODE_ONE` / AVPlayer restart) — only *section* loops take the slow Dart round trip. That is the direction for the fix.

### Fix plan (ordered, incremental)

**Status (2026-07-27):** Steps 1, 2, and 4 are implemented. Step 1 lives in `repeatlab_audioplayers_service_handler.dart` (loop wraps use a dedicated `_performLoopWrapSeek` fast path plus a predictive one-shot `_loopWrapTimer` armed on every position update, rearmed on speed change/resume/loop enable, self-healed by the 200 ms background poll). Step 2 is done in the `../ap` fork's `WrappedMediaPlayer.swift` (zero-tolerance seek), wired into the app via a `audioplayers_darwin` path override in `pubspec.yaml`. Step 4's unit tests are in the `predictive loop wrap` group of the handler test. Step 3 (native ExoPlayer loop region) remains open.

Manual QA checklist for step 4: short loop (<2 s) at 0.5×/1×/2×, foreground and background, both platforms.

1. **Quick wins in the handler (Dart only, both platforms, low risk):**
   - Give loop wraps a dedicated fast path that skips `_performSeek`'s `getDuration`/`getCurrentPosition` round trips — the loop bounds are already validated.
   - Predictive scheduling: instead of polling for `position >= end`, arm a one-shot timer for `(loopEnd − currentPosition) / playbackSpeed` on every position update and fire the seek *at* the boundary rather than after it (rearm on seek/speed change/pause). This removes Stage 1 almost entirely and also fixes the background case (timers keep running when frame callbacks don't).
2. **iOS accuracy fix (one line, high value):** pass `toleranceBefore: .zero, toleranceAfter: .zero` for loop-wrap seeks in `WrappedMediaPlayer.seek` so the wrap lands exactly on the loop start. Measure whether the zero-tolerance seek is slow enough to need pre-buffering tricks before optimizing further.
3. **Native loop region (the real fix, Android first):** the fork already customizes ExoPlayer deeply (Signalsmith processors, click track), so add a native loop region there: either `ClippingMediaSource` over the loop bounds combined with `REPEAT_MODE_ONE` (ExoPlayer repeats clipped sources gaplessly), or a `PlayerMessage` scheduled at the loop-end position that triggers `seekTo` on the playback thread. Expose it as `setLoopRegion(start, end)` through the platform interface (same pattern as `setClickTrack`), fire the existing `seekEvents` on each native wrap so the metronome realigns — the handler comment already anticipates "native loop wraps the cubit never initiates". Dart-side wrapping stays as fallback for iOS/video until ported.
4. **Regression guard:** a handler-level unit test that fakes position updates and asserts the wrap seek is issued at/before the boundary (not after), plus a manual QA checklist entry: short loop (<2 s) at 0.5×/1×/2×, foreground and background, both platforms.

- Free vs. Premium: not applicable — this is a quality fix for everyone.


## 3. In-App Audio Recording

There is already an approved design document for this: `docs/plans/2026-02-26-audio-recording-layering-design.md` (Phase 1: single-layer recording over a backing track). The roadmap request is slightly broader — standalone recording as a library song — so the plan combines both:

**Phase A – Standalone recording into the library (the roadmap's core ask)**
- Add a "Record" entry next to the existing import actions on the home page (FAB/menu next to audio/video import).
- Use the `record` package (as chosen in the design doc) to capture mic input to WAV (44.1 kHz / 16-bit); request mic permission on first use.
- Recording screen with start/pause/stop, elapsed time, and a level meter; on stop, a name dialog (default: "Recording <date>"), then save.
- Reuse the existing import pipeline: the saved WAV goes through the same song-creation path as an imported file (waveform generation, Sembast `Song` entry, appears in the library). Loops, speed, pitch, and metronome then work with zero extra effort because the recording *is* a normal song.
- iOS: configure the audio session for record+playback; Android: foreground service if recording should survive backgrounding (can be deferred).
- Gating suggestion: recording itself Free (it drives engagement and was a cancellation reason), advanced follow-ups (overdub, unlimited layers) Premium.

**Phase B – Overdub / play along (the design doc's Phase 1)**
- Implement `RecordingCubit`, `RecordingLayer` model, layers panel, and loop-aware record-while-playing exactly as specified in the design doc: countdown → backing track plays via the existing engine → mic captured in parallel → layer plays back via SoLoud, mixed with the song.
- Export mix-down via the existing `ffmpeg_kit` dependency.
- Free: 1 layer per song, Premium: unlimited — same `_PremiumGate`/paywall pattern as speed/pitch/metronome (`presentPaywall(source: 'song_recording')`).

**Testing:** cubit unit tests, repository persist/load/delete tests, manual mic-permission and sync testing on both platforms (per the design doc's testing strategy).

## 4. Loop Repetitions with Count/Timer

- **Data model:** extend the `Loop` model (Sembast, dart_mappable) with `repeatMode` (`infinite` | `count` | `duration`), `repeatCount`, `repeatDuration`, and `afterLoopAction` (`stop` | `nextLoop` | `continueSong`). Default `infinite` keeps existing behavior and needs no migration logic beyond nullable/defaulted fields.
- **Playback logic:** `SongCubit` already detects the loop-end boundary to jump back to the start. Add a repetition counter to `SongState` (`currentRepetition`); on each wrap, increment it and check against the target count, or compare elapsed loop time against the timer. When the target is reached, execute the `afterLoopAction` (pause, activate next loop via the existing skip-to-loop logic, or deactivate loop mode so the song continues).
- **UI:**
  - Loop tile / loop edit sheet gets a compact "Repeat" control: ∞ / count stepper / minutes picker, plus the "afterwards" choice.
  - During playback, show "Repetition 3 of 8" (or remaining time) near the loop indicator on the song page; add the strings to all 16 ARB files.
  - Reset the counter on manual seek out of the loop, loop switch, or speed change of position (defined in the cubit, covered by unit tests).
- **Gating suggestion:** Free for the basic count on the single free loop (it addresses a cancellation reason directly), or Premium alongside "unlimited loops" — decide with the paywall analytics; wire through the existing `RepeatLabFeature` list if Premium.
- **Analytics:** new `AppAnalytics` events (`clickLoopRepeatMode`, target values) to learn which modes are used.
