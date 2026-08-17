# Known Issues

Tracked items the team has decided to defer. Each entry should record what the
issue is, why it's not blocking, and what would unblock fixing it.

## `BackupRepository.exportToFile` round-trips songs through `Map`

**Where:** `lib/data/repositories/backup/backup_repository.dart:99-108`

`Song`s are serialized to maps in the main isolate, shipped across the
`Isolate.run` boundary, then deserialized back to `Song`s inside the isolate
just so the serializer can call `.toMap()` again. This is wasteful but harmless.

**Why:** `Song` instances aren't easily transferable across isolates with
`dart_mappable`. Removing the round-trip would require either making `Song`
isolate-transferable or refactoring `BackupSerializer.encode` to accept maps
directly.

**Action:** Cleanup, not a bug. Add a comment explaining the round-trip when
touching this code next.

---

## `VideoPreview` performs an unchecked runtime cast to `VideoSongCubit`

**Where:** `lib/features/song/widgets/video_preview.dart:60`

```dart
final cubit = context.read<SongCubit>() as VideoSongCubit;
```

This is safe today because `VideoPreview` is only ever instantiated from the
video branch of `SongPage`, but the cast will throw at runtime if a future
caller ever wraps it around an audio song.

**Possible fix:** Expose `player` + `videoController` via a typed accessor on
`SongCubit` (or a dedicated mixin), or read the concrete cubit from a
`BlocSelector<VideoSongCubit, ...>` instead.

---

## `dependency_overrides: device_info_plus: 12.3.0` has no rationale

**Where:** `pubspec.yaml`

The hard pin overrides a transitive resolution but the reason isn't recorded.
Likely a sentry / wiredash version conflict.

**Action:** Next time we bump sentry_flutter or wiredash, retest without the
override and either remove the pin or add a comment explaining why it's still
required.

---

## `options.profilesSampleRate = 1.0` removed from Sentry init — confirm intent

**Where:** `lib/main.dart`

Sampling was at 100% on `main`; this branch drops the line entirely.
Removing profiling for the release makes sense (cost / noise), but the change
isn't documented in the commit history.

**Action:** Confirm with the team whether this was deliberate, then add a brief
comment in `main.dart` explaining the choice.

---

## No tests for `VideoPlayerHandler` or `VideoSongCubit`

**Where:** `test/data/services/`, `test/features/song/cubit/`

`VideoPlayerHandler` implements the same `MediaPlayerHandler` interface as the
audio handler, but only the audio handler has loop-bound / skip / completion
test coverage. Regressions in the video handler can only be caught manually.

**Possible fix:** Parameterize the existing handler tests so they exercise both
implementations against a shared contract.

---

## iOS loop restart has a residual ~50–80 ms gap (not fully seamless)

**Where:** `ap/packages/audioplayers_darwin` (`WrappedMediaPlayer.swift`)

iOS loops are triggered gaplessly (native boundary-observer `setLoopRegion`,
measured `overshoot=0ms`), but the seek back to the loop start goes through
`AVPlayerItem.seek(tolerance: .zero)`, which stalls ~50–80 ms re-priming the
playback buffer. Measured on device at 48–84 ms, and it's **codec-independent**
(an uncompressed WAV tested slightly worse than MP3), so it's the AVPlayer seek
pipeline, not decode. Android is seamless (ExoPlayer wraps in-buffer). A user
reported the iOS gap.

**Why deferred:** The only fix is replacing the AVPlayer playback core with an
`AVAudioEngine` buffer-loop graph (wrap at the buffer level, no seek) — a
multi-day rewrite of the most critical audio path. The trigger fix already
shipped tightens the loop and may be enough for now.

**Action / unblock:** Full design (target graph, click/pitch ordering
constraint, staged flag-gated rollout, alternatives) in
`docs/plans/2026-07-30-ios-gapless-loop-avaudioengine-design.md`. Decision
pending: do the rewrite now vs. ship the overshoot fix and schedule it
separately.
