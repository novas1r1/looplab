# Audio Recording & Layering — Design Document

**Date:** 2026-02-26
**Status:** Approved
**Phase:** 1 (Single-layer recording, foundation for multi-layer)

## Goal

Allow users to record audio over imported tracks, building layers step by step. Phase 1 delivers single-layer recording with loop-aware boundaries, non-destructive layer management, and export mix-down. Free users get 1 layer per song; premium users get unlimited (Phase 2).

## Approach

Pragmatic middle ground: Use the `record` Flutter package for Phase 1 recording (cross-platform, fast to integrate). Use existing SoLoud engine for layer playback/mixing. Keep AudioPlayers untouched as the primary backing track playback engine. Migrate to native platform recording in Phase 2 if needed for latency.

---

## Data Model

### New Model: `RecordingLayer`

| Field | Type | Description |
|-------|------|-------------|
| id | String (UUID) | Unique identifier |
| songId | String | Reference to parent song |
| filePath | String | Path to recorded WAV file |
| startPosition | Duration | Where in the song this recording starts |
| duration | Duration | Length of the recording |
| volume | double | 0.0 - 1.0, default 1.0 |
| isMuted | bool | Toggle layer on/off |
| createdAt | DateTime | When the recording was made |
| label | String? | Optional user label (e.g. "Guitar take 2") |

### Relationship

- A `Song` gains a `List<RecordingLayer>`
- Layers stored in Sembast alongside the song
- Audio files stored in app documents directory

---

## Recording Flow & UX

### User Flow

1. User opens a song and sets up a loop (e.g. 0:30 - 0:45)
2. User taps **Record button** (mic icon in `SongController` playback controls)
3. App requests microphone permission (if not already granted)
4. 3-2-1 countdown overlay appears
5. Playback starts at loop start position; mic recording captures simultaneously
6. At loop end, recording automatically stops
7. Recorded layer appears in **Layers panel** below the waveform
8. User plays back song + recording together, can toggle/delete/adjust volume

### UX Details

- **Record button:** Mic icon added to existing playback controls bar, next to play/pause
- **Recording indicator:** Subtle red border/pulse on waveform area during recording
- **Countdown:** Visual 3-2-1 overlay
- **No loop active:** Recording goes from current position until user manually stops
- **Layers panel:** Collapsible section with layer tiles (similar to `LoopTile` pattern) — mute toggle, volume slider, delete action

### Phase 1 Constraints

- No live monitoring (user hears backing track only, not their own mic)
- No editing/trimming of recordings
- No effects on recorded audio
- No standalone recording (always requires a backing track)

---

## Audio Architecture

### Recording (`record` package)

- Captures mic input as WAV files (44.1kHz, 16-bit, mono)
- Recording starts synchronized with backing track playback position
- Files saved to: `recordings/{songId}/{layerId}.wav`

### Playback (Dual Engine — unchanged)

- **AudioPlayers:** Continues handling backing track playback (untouched)
- **SoLoud:** Handles recording layer playback only
  - Each layer gets its own SoLoud audio handle
  - Independent volume and mute control per layer

### Synchronization

- On record start: capture backing track's current position as `startPosition`
- On playback: seek recording layer to `currentPosition - layer.startPosition`
- Layer stays silent if `currentPosition` is outside `[startPosition, startPosition + duration]`

### Export Mix-Down (FFmpeg)

- Uses existing `ffmpeg_kit_flutter_new_min` dependency
- Overlays recording layers onto original track at their respective offsets
- Export as WAV or same format as original

---

## State Management

### New Cubit: `RecordingCubit`

```
RecordingState
├── status: RecordingStatus (idle | countdown | recording | saving)
├── layers: List<RecordingLayer>
├── countdownValue: int? (3, 2, 1)
├── activeLayerId: String? (currently recording layer)
├── currentRecordingDuration: Duration?
└── error: String?
```

### Cubit Interactions

- `RecordingCubit` reads from `SongCubit` for loop boundaries and playback position
- `RecordingCubit` tells `SongCubit` to start playback when countdown finishes
- `SongCubit` remains unchanged — no knowledge of recordings
- Layers panel UI listens to `RecordingCubit`

### New Repository: `RecordingRepository`

- Persists `RecordingLayer` metadata to Sembast
- Manages audio files on disk (save, delete, cleanup)
- Loads layers for a given song

### Feature Gating

- Free: 1 recording layer per song
- Premium: Unlimited layers
- Gate check in `RecordingCubit` before starting new recording
- Uses existing `PremiumSubscriptionCubit` and `RepeatLabFeature` pattern

### Permissions

- Microphone permission requested on first record tap
- Uses `record` package's built-in permission check

---

## File Management & Storage

### File Structure

```
app_documents_directory/
└── recordings/
    └── {songId}/
        ├── {layerId1}.wav
        ├── {layerId2}.wav
        └── ...
```

### Lifecycle

- Recording creates WAV file in song's recording directory
- Deleting a layer deletes the WAV file from disk
- Deleting a song deletes its entire recording directory
- No cloud sync — local only

### File Size

- WAV at 44.1kHz/16-bit mono: ~5 MB per minute
- Typical 15-second loop recording: ~1.25 MB
- No compression needed in Phase 1

### Export

- "Export Mix" uses FFmpeg to overlay layers onto original track
- Output saved to sharable location / share sheet

---

## Phase Boundaries

### Phase 1 — In Scope

- Record button in playback controls
- Microphone permission handling
- 3-2-1 countdown before recording starts
- Loop-aware recording (auto-stop at loop end, free record if no loop)
- Save recordings as WAV files
- Layers panel UI (list with mute/volume/delete)
- Playback of layers via SoLoud alongside AudioPlayers backing track
- Export mix-down via FFmpeg
- Feature gating: 1 layer free, unlimited premium

### Phase 2 — Out of Scope

- Live monitoring (hear yourself while recording)
- Multiple simultaneous recordings
- Recording trimming/editing
- Metronome countdown
- Standalone recording (without backing track)
- Audio effects on layers
- Native platform recording (replacing `record` package)
- AAC compression for storage optimization
- Layer reordering or color coding

---

## Testing Strategy

- Unit tests for `RecordingCubit` state transitions
- Unit tests for `RecordingRepository` (persist/load/delete)
- Integration test for record-then-playback flow
- Manual testing on both iOS and Android (mic permissions, audio sync)
