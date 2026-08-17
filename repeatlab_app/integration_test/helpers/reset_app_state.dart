import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:sembast/sembast_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'test_media.dart';

final _store = StoreRef<String, Map<String, dynamic>>('songs');

Future<String> _dbPath() async {
  final dir = await getApplicationDocumentsDirectory();
  await dir.create(recursive: true);
  return p.join(dir.path, 'repeatlab.db');
}

/// Resets the app to a known state before each E2E test.
///
/// Wipes the on-disk Sembast `songs` store **through a throwaway handle that is
/// closed before [bootstrap] opens the app's own handle** (two open handles on
/// one SQLite/Sembast file race), then clears preferences.
///
/// By default it skips onboarding and the song-page tutorial coach-marks and
/// pins the locale to English so text assertions are deterministic. The
/// onboarding flow passes `skipOnboarding: false`.
///
/// It also marks the current build's changelog as seen: otherwise the home
/// page shows the "What's new" bubble, whose bobbing animation repeats forever
/// and makes every `pumpAndSettle` time out.
Future<void> resetAppState({
  bool skipOnboarding = true,
  bool skipTutorial = true,
  String? languageCode = 'en',
}) async {
  final db = await databaseFactoryIo.openDatabase(await _dbPath());
  await _store.delete(db);
  await db.close();

  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  // Any build number is < this, so the changelog counts as already seen.
  await prefs.setInt(LocalConfigRepository.kChangelogVersionShown, 1 << 30);
  // The rate-app dialog (looping Lottie) is offered after adding a song when
  // two or more already exist; flows that reach that point must not get it.
  await prefs.setBool(LocalConfigRepository.kHasRatedApp, true);
  if (skipOnboarding) {
    await prefs.setBool(LocalConfigRepository.kIntroShown, true);
  }
  if (skipTutorial) {
    await prefs.setBool(LocalConfigRepository.kHasCompletedTutorial, true);
  }
  if (languageCode != null) {
    await prefs.setString(LocalConfigRepository.kLanguageCode, languageCode);
  }
}

/// Seeds one audio [Song] directly into the store and writes a matching silent
/// WAV into the app documents dir so it can actually be opened/played. Returns
/// the seeded song. Must be called AFTER [resetAppState] and BEFORE pumping the
/// app (the handle is closed before returning).
///
/// [bpm] / [musicalKey] pre-fill the song's tempo and key (as if tags or the
/// user had set them); [metronomeBeatAnchorMs] marks the metronome as already
/// synced, which unlocks the time-signature / advanced controls.
Future<Song> seedAudioSong({
  required String title,
  String artist = 'Test Artist',
  int sortOrder = 0,
  int loopCount = 0,
  int? bpm,
  String? musicalKey,
  int? metronomeBeatAnchorMs,
}) async {
  MapperContainer.globals.use(const DurationMapper());

  final appDir = await getApplicationDocumentsDirectory();
  final fileName = 'seed_${const Uuid().v4()}.wav';
  final file = File(p.join(appDir.path, fileName));
  await file.writeAsBytes(TestMedia.silentWavBytes(), flush: true);

  final id = const Uuid().v4();
  final song = Song(
    id: id,
    title: title,
    artist: artist,
    fileName: fileName,
    duration: const Duration(seconds: 2),
    sortOrder: sortOrder,
    loops: _buildSeedLoops(id, loopCount),
    bpm: bpm,
    musicalKey: musicalKey,
    metronomeBeatAnchorMs: metronomeBeatAnchorMs,
  );

  final db = await databaseFactoryIo.openDatabase(await _dbPath());
  await _store.add(db, song.toMap());
  await db.close();

  return song;
}

/// Builds [count] loops for [songId] — used to exercise the freemium gate (only
/// loop #0 is unlocked for non-Pro users).
List<Loop> _buildSeedLoops(String songId, int count) {
  return [
    for (var i = 0; i < count; i++)
      Loop(
        id: i + 1,
        name: 'Loop ${i + 1}',
        songId: songId,
        color: LoopColor.values[i % LoopColor.values.length],
        orderNumber: i,
        start: Duration(milliseconds: 100 * i),
        end: Duration(milliseconds: 100 * i + 500),
      ),
  ];
}
