# Drag-and-Drop Song Reordering

## Overview

Add drag-and-drop reordering to the home page song list. The order is persisted and backwards compatible with older app versions.

## Data Model

Add a `sortOrder` field to `Song`:

```dart
final int sortOrder; // default 0, lower = higher in list
```

- `dart_mappable` handles deserialization of old data without this field — defaults to `0`
- Old app versions ignore the unknown field in Sembast/backup JSON — no crash or data loss
- Songs are sorted ascending by `sortOrder`

## Repository Changes (`SongRepository`)

- `getAllSongs()`: sort results by `sortOrder` ascending
- `addSongFile()`: assign `sortOrder = 0` to the new song, increment all existing songs' `sortOrder` by 1 (new songs appear at top)
- New method `reorderSongs(List<Song> reorderedSongs)`: batch-update `sortOrder` for all songs based on their new list positions

## State Management (`AllSongsCubit`)

- Add `reorderSongs(int oldIndex, int newIndex)`:
  - Optimistically reorder the local song list
  - Reassign `sortOrder` values (index-based: position 0 gets sortOrder 0, etc.)
  - Persist via `songRepository.reorderSongs()`

## UI Changes (`HomePage`)

- Replace `ListView.separated` with `ReorderableListView.separated`
- Long-press initiates drag (default Flutter behavior)
- `onReorder` callback calls `AllSongsCubit.reorderSongs(oldIndex, newIndex)`
- Horizontal swipe-to-delete (`Slidable`) remains unchanged — no gesture conflict since drag uses long-press

## Backwards Compatibility

| Scenario | Behavior |
|----------|----------|
| Old data (no `sortOrder` field) | Defaults to `0` for all songs, preserving existing insertion order |
| Old app reads new data | Ignores unknown `sortOrder` field — Sembast and JSON are schema-flexible |
| Backup/restore across versions | `sortOrder` is part of song JSON; old versions skip it, new versions read it |
| New song added | Gets `sortOrder = 0`, existing songs shift down |

## Files to Modify

1. `lib/data/models/song.dart` — add `sortOrder` field
2. `lib/data/repositories/song_repository.dart` — sorting + reorder method + new song ordering
3. `lib/features/home/cubit/all_songs_cubit.dart` — add `reorderSongs` method
4. `lib/features/home/home_page.dart` — switch to `ReorderableListView.separated`
5. Regenerate `song.mapper.dart` via `dart run build_runner`
