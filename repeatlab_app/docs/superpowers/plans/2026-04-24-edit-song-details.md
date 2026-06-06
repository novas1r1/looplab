# Edit Song Title & Artist Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to edit a song's title and artist from the song settings bottom sheet.

**Architecture:** Add an "Edit Song" action tile to the existing `SongSettingsBottomSheet`. Tapping it closes the sheet and shows an `AlertDialog` with two `TextField`s (title, artist). On save, `SongCubit.updateSongDetails()` calls `songRepository.updateSong()` with the updated song. The AppBar title is made reactive via `BlocSelector` so it updates immediately.

**Tech Stack:** Flutter, BLoC/Cubit, Sembast, dart_mappable, ARB localization (16 languages)

---

### Task 1: Add localization strings

**Files:**
- Modify: `lib/l10n/arb/app_en.arb`

- [ ] **Step 1: Add English localization strings**

Add these entries to `lib/l10n/arb/app_en.arb` (before the closing `}`):

```json
"editSong": "Edit Song",
"editSongTitle": "Title",
"editSongArtist": "Artist",
"editSongTitleRequired": "Title cannot be empty"
```

Note: The app already has a `"save": "Save"` key at line 73 — reuse it.

- [ ] **Step 2: Add translations to all other ARB files**

Use the flutter-arb-translator agent to translate the 4 new keys into all 15 non-English ARB files:
`app_ar.arb`, `app_de.arb`, `app_es.arb`, `app_fr.arb`, `app_hi.arb`, `app_it.arb`, `app_ja.arb`, `app_ko.arb`, `app_nl.arb`, `app_pl.arb`, `app_pt.arb`, `app_ru.arb`, `app_sv.arb`, `app_tr.arb`, `app_zh.arb`

- [ ] **Step 3: Run code generation**

Run: `flutter gen-l10n`
Expected: No errors, generated localizations updated.

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/
git commit -m "feat: add localization strings for edit song feature"
```

---

### Task 2: Add `updateSongDetails` method to SongCubit

**Files:**
- Modify: `lib/features/song/cubit/song/song_cubit.dart`

- [ ] **Step 1: Add `updateSongDetails` method**

Add this method to `SongCubit` (after the `deleteSong` method around line 836):

```dart
Future<void> updateSongDetails({
  required String title,
  required String artist,
}) async {
  emit(state.copyWith(status: SongStatus.updating));

  try {
    final updatedSong = state.song.copyWith(
      title: title,
      artist: artist,
    );
    await songRepository.updateSong(updatedSong);

    emit(
      state.copyWith(
        status: SongStatus.updated,
        song: updatedSong,
        error: null,
      ),
    );
  } catch (ex, stack) {
    unawaited(crashReportingRepository.reportError(ex, stack));
    emit(
      state.copyWith(
        status: SongStatus.error,
        error: 'Failed to update song details: $ex',
      ),
    );
  }
}
```

- [ ] **Step 2: Verify the app compiles**

Run: `flutter build ios --no-codesign 2>&1 | tail -5` (or `flutter analyze`)
Expected: No errors related to SongCubit.

- [ ] **Step 3: Commit**

```bash
git add lib/features/song/cubit/song/song_cubit.dart
git commit -m "feat: add updateSongDetails method to SongCubit"
```

---

### Task 3: Add "Edit Song" action to SongSettingsBottomSheet

**Files:**
- Modify: `lib/features/song/widgets/song_settings_bottom_sheet.dart`

- [ ] **Step 1: Add `onEditSong` callback parameter**

In `SongSettingsBottomSheet`, add a new callback alongside the existing `onDeleteSong`:

```dart
class SongSettingsBottomSheet extends StatelessWidget {
  final VoidCallback onDeleteSong;
  final VoidCallback onEditSong;

  const SongSettingsBottomSheet({
    super.key,
    required this.onDeleteSong,
    required this.onEditSong,
  });
```

Update the `show` static method to accept and pass through `onEditSong`:

```dart
static Future<void> show(
  BuildContext context, {
  required VoidCallback onDeleteSong,
  required VoidCallback onEditSong,
}) {
  final songCubit = context.read<SongCubit>();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => BlocProvider.value(
      value: songCubit,
      child: SongSettingsBottomSheet(
        onDeleteSong: onDeleteSong,
        onEditSong: onEditSong,
      ),
    ),
  );
}
```

- [ ] **Step 2: Add the "Edit Song" action tile in the build method**

In the Actions section of the `build` method, add an "Edit Song" tile as the first action (before "Report Bug & Feedback"). Insert it inside the `_SettingsCard` children list at line ~169:

```dart
_SettingsCard(
  children: [
    _ActionTile(
      icon: Icons.edit_outlined,
      title: context.l10n.editSong,
      onTap: () {
        Navigator.pop(context);
        onEditSong();
      },
    ),
    const _SettingsDivider(),
    _ActionTile(
      icon: Icons.feedback_outlined,
      title: context.l10n.reportBugAndFeedback,
      onTap: () {
        AppAnalytics.trackEvent(AppAnalytics.clickReportBug);
        AppAnalytics.trackEvent(AppAnalytics.viewFeedback);
        Navigator.pop(context);
        Wiredash.of(context).show(inheritMaterialTheme: true);
      },
    ),
    const _SettingsDivider(),
    _ActionTile(
      icon: Icons.delete_outline_rounded,
      title: context.l10n.deleteSong,
      isDestructive: true,
      onTap: () {
        Navigator.pop(context);
        onDeleteSong();
      },
    ),
  ],
),
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/song/widgets/song_settings_bottom_sheet.dart
git commit -m "feat: add edit song action tile to settings bottom sheet"
```

---

### Task 4: Wire up the edit dialog in SongPage

**Files:**
- Modify: `lib/features/song/view/song_page.dart`

- [ ] **Step 1: Make the AppBar title reactive to state changes**

In `_SongViewState.build()`, replace the static `widget.song.title` in the default AppBar (line 173) with a `BlocSelector`:

```dart
appBar: AppBar(
  title: BlocSelector<SongCubit, SongState, String>(
    selector: (state) => state.song.title,
    builder: (context, title) {
      return Text(title);
    },
  ),
  actions: [
    // ... existing actions unchanged
  ],
),
```

Also update the `loadError` case AppBar (line 156) similarly:

```dart
appBar: AppBar(
  title: BlocSelector<SongCubit, SongState, String>(
    selector: (state) => state.song.title,
    builder: (context, title) {
      return AutoSizeText(
        title,
        minFontSize: 20,
        maxFontSize: 24,
        maxLines: 2,
      );
    },
  ),
),
```

- [ ] **Step 2: Pass `onEditSong` to SongSettingsBottomSheet.show**

Update the `IconButton` onPressed at line ~185 to pass the new callback:

```dart
IconButton(
  icon: const Icon(Icons.more_vert),
  onPressed: () => SongSettingsBottomSheet.show(
    context,
    onDeleteSong: () => _onTapDeleteSong(context),
    onEditSong: () => _showEditSongDialog(context),
  ),
),
```

- [ ] **Step 3: Add the `_showEditSongDialog` method**

Add this method to `_SongViewState` (e.g. after `_onTapDeleteSong`):

```dart
Future<void> _showEditSongDialog(BuildContext context) async {
  final songCubit = context.read<SongCubit>();
  final currentSong = songCubit.state.song;

  final titleController = TextEditingController(text: currentSong.title);
  final artistController = TextEditingController(text: currentSong.artist);

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            elevation: 24,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(dialogContext)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
            title: Text(dialogContext.l10n.editSong),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: dialogContext.l10n.editSongTitle,
                    errorText: titleController.text.trim().isEmpty
                        ? dialogContext.l10n.editSongTitleRequired
                        : null,
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: artistController,
                  decoration: InputDecoration(
                    labelText: dialogContext.l10n.editSongArtist,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(dialogContext.l10n.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimaryContainer,
                ),
                onPressed: titleController.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(dialogContext).pop(true),
                child: Text(dialogContext.l10n.save),
              ),
            ],
          );
        },
      );
    },
  );

  if (result == true && context.mounted) {
    songCubit.updateSongDetails(
      title: titleController.text.trim(),
      artist: artistController.text.trim(),
    );
  }

  titleController.dispose();
  artistController.dispose();
}
```

- [ ] **Step 4: Verify the app compiles**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/song/view/song_page.dart
git commit -m "feat: add edit song dialog with title and artist fields"
```

---

### Task 5: Add analytics event (optional, follows existing pattern)

**Files:**
- Modify: `lib/core/utils/app_analytics.dart`

- [ ] **Step 1: Check if analytics constants exist and add one**

Look at `lib/core/utils/app_analytics.dart` for the pattern. Add:

```dart
static const clickEditSong = 'click_edit_song';
```

- [ ] **Step 2: Track the event in `_showEditSongDialog`**

Add at the top of `_showEditSongDialog`:

```dart
AppAnalytics.trackEvent(AppAnalytics.clickEditSong);
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/utils/app_analytics.dart lib/features/song/view/song_page.dart
git commit -m "feat: add analytics tracking for edit song"
```
