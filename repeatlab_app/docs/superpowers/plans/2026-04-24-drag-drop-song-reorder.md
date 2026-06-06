# Drag-and-Drop Song Reordering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to reorder songs on the home page via drag-and-drop, persisting the order across sessions with backwards compatibility.

**Architecture:** Add a `sortOrder` int field to `Song`, sort by it in the repository, use `ReorderableListView` in the UI. New songs get `sortOrder = 0` and push existing songs down.

**Tech Stack:** Flutter, Sembast, dart_mappable, flutter_bloc, ReorderableListView

---

### Task 1: Add `sortOrder` field to Song model

**Files:**
- Modify: `lib/data/models/song.dart`
- Regenerate: `lib/data/models/song.mapper.dart`
- Modify: `test/helpers/mock_data.dart`

- [ ] **Step 1: Add `sortOrder` field to Song**

In `lib/data/models/song.dart`, add the field to the class and constructor:

```dart
class Song with SongMappable {
  final String id;
  final String title;
  final String artist;
  final String fileName;
  final Duration duration;
  final int? bpm;
  final int? currentBpm;
  final List<Loop> loops;
  final LoopSort loopSort;
  final int sortOrder;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.fileName,
    required this.duration,
    this.bpm,
    this.currentBpm,
    this.loops = const [],
    this.loopSort = LoopSort.none,
    this.sortOrder = 0,
  });
```

- [ ] **Step 2: Regenerate mapper**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `song.mapper.dart` regenerated with `sortOrder` support. The default value of `0` ensures old data without the field deserializes correctly.

- [ ] **Step 3: Verify tests still pass**

Run:
```bash
flutter test test/data/repositories/song_repository_test.dart
```

Expected: All existing tests pass — `sortOrder` defaults to `0` so no mock data changes needed.

- [ ] **Step 4: Commit**

```bash
git add lib/data/models/song.dart lib/data/models/song.mapper.dart
git commit -m "feat: add sortOrder field to Song model"
```

---

### Task 2: Sort songs by `sortOrder` in repository and support reordering

**Files:**
- Modify: `lib/data/repositories/song_repository.dart`
- Modify: `test/data/repositories/song_repository_test.dart`

- [ ] **Step 1: Write failing tests for sorted retrieval and reordering**

Add to `test/data/repositories/song_repository_test.dart` inside the `SongRepository` group:

```dart
group('song ordering', () {
  test('getAllSongs returns songs sorted by sortOrder ascending', () async {
    final store = StoreRef<String, Map<String, dynamic>>('songs');
    await store.add(db, MockData.songShort.copyWith(sortOrder: 2).toMap());
    await store.add(db, MockData.songMedium.copyWith(sortOrder: 0).toMap());
    await store.add(db, MockData.songLong.copyWith(sortOrder: 1).toMap());

    final songs = await songRepository.getAllSongs();
    expect(songs[0].id, MockData.songMedium.id);
    expect(songs[1].id, MockData.songLong.id);
    expect(songs[2].id, MockData.songShort.id);
  });

  test('reorderSongs updates sortOrder for all songs', () async {
    final store = StoreRef<String, Map<String, dynamic>>('songs');
    await store.add(db, MockData.songShort.copyWith(sortOrder: 0).toMap());
    await store.add(db, MockData.songMedium.copyWith(sortOrder: 1).toMap());
    await store.add(db, MockData.songLong.copyWith(sortOrder: 2).toMap());

    // Reorder: move song at index 2 to index 0
    final reordered = [
      MockData.songLong.copyWith(sortOrder: 0),
      MockData.songShort.copyWith(sortOrder: 1),
      MockData.songMedium.copyWith(sortOrder: 2),
    ];
    await songRepository.reorderSongs(reordered);

    final songs = await songRepository.getAllSongs();
    expect(songs[0].id, MockData.songLong.id);
    expect(songs[1].id, MockData.songShort.id);
    expect(songs[2].id, MockData.songMedium.id);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
flutter test test/data/repositories/song_repository_test.dart
```

Expected: `reorderSongs` test fails (method doesn't exist). `getAllSongs` sorted test may fail (no sorting yet).

- [ ] **Step 3: Implement sorting in `getAllSongs` and add `reorderSongs`**

In `lib/data/repositories/song_repository.dart`:

Update `getAllSongs`:
```dart
Future<List<Song>> getAllSongs() async {
  final records = await _store.find(
    db,
    finder: Finder(sortOrders: [SortOrder('sortOrder')]),
  );
  final songs = records.map((e) => SongMapper.fromMap(e.value)).toList();
  _songController.add(songs);

  return songs;
}
```

Add `reorderSongs` method:
```dart
Future<void> reorderSongs(List<Song> songs) async {
  for (final song in songs) {
    await _store.update(
      db,
      song.toMap(),
      finder: Finder(filter: Filter.equals('id', song.id)),
    );
  }
  await getAllSongs();
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
flutter test test/data/repositories/song_repository_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/song_repository.dart test/data/repositories/song_repository_test.dart
git commit -m "feat: sort songs by sortOrder and add reorderSongs method"
```

---

### Task 3: New songs get sortOrder 0 (appear at top)

**Files:**
- Modify: `lib/data/repositories/song_repository.dart`
- Modify: `test/data/repositories/song_repository_test.dart`

- [ ] **Step 1: Write failing test**

Add to `test/data/repositories/song_repository_test.dart` inside the `song ordering` group:

```dart
test('new songs are inserted with sortOrder 0 and existing songs shift down', () async {
  final store = StoreRef<String, Map<String, dynamic>>('songs');
  await store.add(db, MockData.songShort.copyWith(sortOrder: 0).toMap());
  await store.add(db, MockData.songMedium.copyWith(sortOrder: 1).toMap());

  // Simulate adding a new song by calling the internal insert logic
  // We need to test that incrementExistingSortOrders works
  await songRepository.incrementExistingSortOrders();

  final songs = await songRepository.getAllSongs();
  // Existing songs should have shifted: 0->1, 1->2
  expect(songs[0].sortOrder, 1);
  expect(songs[1].sortOrder, 2);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
flutter test test/data/repositories/song_repository_test.dart
```

Expected: FAIL — `incrementExistingSortOrders` doesn't exist.

- [ ] **Step 3: Implement `incrementExistingSortOrders` and wire it into `addSongFile`**

In `lib/data/repositories/song_repository.dart`, add the method:

```dart
Future<void> incrementExistingSortOrders() async {
  final records = await _store.find(db);
  for (final record in records) {
    final song = SongMapper.fromMap(record.value);
    await record.ref.update(
      db,
      song.copyWith(sortOrder: song.sortOrder + 1).toMap(),
    );
  }
}
```

In `addSongFile`, before `await _store.add(db, song.toMap());`, add:

```dart
// Shift existing songs down so the new song appears at the top
await incrementExistingSortOrders();
```

The `Song` constructor in `addSongFile` already defaults `sortOrder` to `0`, so no change needed there.

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
flutter test test/data/repositories/song_repository_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/song_repository.dart test/data/repositories/song_repository_test.dart
git commit -m "feat: new songs appear at top by shifting existing sortOrders"
```

---

### Task 4: Add `reorderSongs` to AllSongsCubit

**Files:**
- Modify: `lib/features/home/cubit/all_songs_cubit.dart`
- Modify: `test/features/home/cubit/all_songs_cubit_test.dart`

- [ ] **Step 1: Write failing test**

Add to `test/features/home/cubit/all_songs_cubit_test.dart` inside the `AllSongsCubit` group:

```dart
group('reorderSongs', () {
  blocTest<AllSongsCubit, AllSongsState>(
    'optimistically reorders songs and persists via repository',
    seed: () => AllSongsState(
      status: AllSongsStatus.loaded,
      songs: [MockData.songShort, MockData.songMedium, MockData.songLong],
    ),
    build: () {
      when(() => mockSongRepository.reorderSongs(any())).thenAnswer((_) async {});
      return buildCubit();
    },
    act: (cubit) => cubit.reorderSongs(2, 0),
    expect: () => [
      isA<AllSongsState>().having(
        (s) => s.songs.map((s) => s.id).toList(),
        'song ids',
        [MockData.songLong.id, MockData.songShort.id, MockData.songMedium.id],
      ),
    ],
    verify: (_) {
      verify(() => mockSongRepository.reorderSongs(any())).called(1);
    },
  );

  blocTest<AllSongsCubit, AllSongsState>(
    'emits error state when reorderSongs throws',
    seed: () => AllSongsState(
      status: AllSongsStatus.loaded,
      songs: [MockData.songShort, MockData.songMedium],
    ),
    build: () {
      when(() => mockSongRepository.reorderSongs(any())).thenThrow(
        Exception('Reorder failed'),
      );
      return buildCubit();
    },
    act: (cubit) => cubit.reorderSongs(1, 0),
    expect: () => [
      // Optimistic reorder
      isA<AllSongsState>().having(
        (s) => s.songs.map((s) => s.id).toList(),
        'song ids',
        [MockData.songMedium.id, MockData.songShort.id],
      ),
      // Error state after persistence fails
      isA<AllSongsState>().having(
        (s) => s.status,
        'status',
        AllSongsStatus.error,
      ),
    ],
    verify: (_) {
      verify(
        () => mockCrashReportingRepository.reportError(any(), any()),
      ).called(1);
    },
  );
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
flutter test test/features/home/cubit/all_songs_cubit_test.dart
```

Expected: FAIL — `reorderSongs` method doesn't exist on `AllSongsCubit`.

- [ ] **Step 3: Implement `reorderSongs` in AllSongsCubit**

Add to `lib/features/home/cubit/all_songs_cubit.dart`:

```dart
Future<void> reorderSongs(int oldIndex, int newIndex) async {
  final songs = List<Song>.from(state.songs);

  // ReorderableListView adjusts newIndex when moving down
  if (oldIndex < newIndex) {
    newIndex -= 1;
  }

  final song = songs.removeAt(oldIndex);
  songs.insert(newIndex, song);

  // Reassign sortOrder based on new positions
  final reordered = [
    for (int i = 0; i < songs.length; i++)
      songs[i].copyWith(sortOrder: i),
  ];

  // Optimistic update
  emit(state.copyWith(songs: reordered));

  try {
    await songRepository.reorderSongs(reordered);
  } catch (ex, stack) {
    crashReportingRepository.reportError(ex, stack);
    emit(
      state.copyWith(
        status: AllSongsStatus.error,
        errorMessage: ex.toString(),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
flutter test test/features/home/cubit/all_songs_cubit_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/cubit/all_songs_cubit.dart test/features/home/cubit/all_songs_cubit_test.dart
git commit -m "feat: add reorderSongs to AllSongsCubit with optimistic update"
```

---

### Task 5: Replace ListView with ReorderableListView on home page

**Files:**
- Modify: `lib/features/home/home_page.dart`

- [ ] **Step 1: Replace `ListView.separated` with `ReorderableListView.separated`**

In `lib/features/home/home_page.dart`, replace the `ListView.separated` block (lines 140-150) with:

```dart
return ReorderableListView.separated(
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
  separatorBuilder: (context, index) =>
      const SizedBox(height: 8),
  onReorder: (oldIndex, newIndex) {
    context.read<AllSongsCubit>().reorderSongs(
      oldIndex,
      newIndex,
    );
  },
  proxyDecorator: (child, index, animation) {
    return Material(
      color: Colors.transparent,
      child: child,
    );
  },
  children: [
    for (int index = 0; index < state.songs.length; index++)
      HomeTile(
        key: ValueKey(state.songs[index].id),
        song: state.songs[index],
      ),
  ],
);
```

Note: `ReorderableListView` requires each child to have a unique `Key`. We use `ValueKey(song.id)`.

- [ ] **Step 2: Manually test**

Run the app, verify:
1. Long-press a song tile to start dragging
2. Drag to a new position and release
3. Order persists after closing and reopening the app
4. Swipe-to-delete still works
5. Adding a new song places it at the top

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/home_page.dart
git commit -m "feat: enable drag-and-drop song reordering on home page"
```

---

### Task 6: Run full test suite and verify backwards compatibility

- [ ] **Step 1: Run all tests**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 2: Verify backwards compatibility of serialization**

The `Song` model with `sortOrder = 0` default means:
- Old JSON without `sortOrder` → deserializes with `sortOrder: 0` (all songs tie, insertion order preserved)
- New JSON with `sortOrder` → old app versions ignore the unknown field (Sembast is schema-flexible)
- Backup format: `sortOrder` is just another JSON field, transparent to old/new versions

No code changes needed — this is a verification step.

- [ ] **Step 3: Final commit if any fixups were needed**

```bash
git add -A
git commit -m "fix: address test/compat issues from reorder feature"
```
