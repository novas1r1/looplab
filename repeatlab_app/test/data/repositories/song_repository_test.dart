import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:sembast/sembast_memory.dart';

import '../../helpers/mock_data.dart';
import '../../helpers/mock_services.dart';

var _testDbCounter = 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock path_provider
  const MethodChannel pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );

  late Database db;
  late MockSoLoud mockSoLoud;
  late SongRepository songRepository;

  setUpAll(() {
    registerFallbackValue(MockData.songShort);
    registerFallbackValue(MockData.loopVerse);

    // Setup path_provider mock
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProviderChannel,
          (MethodCall call) async {
            if (call.method == 'getApplicationDocumentsDirectory') {
              return '/mock/app/documents';
            }
            return null;
          },
        );
  });

  setUp(() async {
    // Use unique database name for each test to ensure isolation
    _testDbCounter++;
    db = await databaseFactoryMemory.openDatabase('test_$_testDbCounter.db');
    mockSoLoud = MockSoLoud();
    songRepository = SongRepository(db: db, soLoud: mockSoLoud);
  });

  tearDown(() async {
    songRepository.dispose();
    await db.close();
  });

  group('SongRepository', () {
    group('getAllSongs', () {
      test('returns empty list when database is empty', () async {
        final songs = await songRepository.getAllSongs();
        expect(songs, isEmpty);
      });

      test('returns all songs from database', () async {
        // Manually insert songs into the database
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songShort.toMap());
        await store.add(db, MockData.songMedium.toMap());

        final songs = await songRepository.getAllSongs();
        expect(songs, hasLength(2));
      });

      test('emits songs on stream after getAllSongs', () async {
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songShort.toMap());

        // Listen to the stream before calling getAllSongs
        final songsFuture = songRepository.songs.first;
        await songRepository.getAllSongs();

        final songs = await songsFuture;
        expect(songs, hasLength(1));
        expect(songs.first.id, MockData.songShort.id);
      });
    });

    group('updateSong', () {
      test('updates song in database', () async {
        // First add a song
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songShort.toMap());

        // Update the song
        final updatedSong = MockData.songShort.copyWith(title: 'Updated Title');
        await songRepository.updateSong(updatedSong);

        // Verify the update
        final songs = await songRepository.getAllSongs();
        expect(songs.first.title, 'Updated Title');
      });

      test('emits updated songs on stream', () async {
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songShort.toMap());

        final updatedSong = MockData.songShort.copyWith(title: 'New Title');

        // Collect stream events
        final streamResults = <List<Song>>[];
        final subscription = songRepository.songs.listen(streamResults.add);

        await songRepository.updateSong(updatedSong);
        await Future<void>.delayed(Duration.zero);

        await subscription.cancel();

        expect(streamResults.last.first.title, 'New Title');
      });
    });

    group('deleteSong', () {
      test('removes song from database', () async {
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songShort.toMap());
        await store.add(db, MockData.songMedium.toMap());

        // Verify both songs exist
        var songs = await songRepository.getAllSongs();
        expect(songs, hasLength(2));

        // Delete one song
        await songRepository.deleteSong(MockData.songShort);

        // Verify only one song remains
        songs = await songRepository.getAllSongs();
        expect(songs, hasLength(1));
        expect(songs.first.id, MockData.songMedium.id);
      });
    });

    group('addLoopToSong', () {
      test('adds loop to song and returns updated song', () async {
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songMedium.toMap());

        final loop = Loop(
          id: 1,
          name: 'Test Loop',
          songId: MockData.songMedium.id,
          color: LoopColor.green,
          start: const Duration(seconds: 10),
          end: const Duration(seconds: 30),
        );

        final updatedSong = await songRepository.addLoopToSong(
          song: MockData.songMedium,
          loop: loop,
        );

        expect(updatedSong.loops, hasLength(1));
        expect(updatedSong.loops.first.name, 'Test Loop');
      });

      test('preserves existing loops when adding new loop', () async {
        final songWithLoop = MockData.songMedium.copyWith(
          loops: [MockData.loopVerse],
        );
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, songWithLoop.toMap());

        final newLoop = Loop(
          id: 2,
          name: 'New Loop',
          songId: MockData.songMedium.id,
          color: LoopColor.orange,
          start: const Duration(minutes: 2),
          end: const Duration(minutes: 3),
        );

        final updatedSong = await songRepository.addLoopToSong(
          song: songWithLoop,
          loop: newLoop,
        );

        expect(updatedSong.loops, hasLength(2));
      });
    });

    group('updateLoopForSong', () {
      test('updates existing loop in song', () async {
        final songWithLoop = MockData.songMedium.copyWith(
          loops: [MockData.loopVerse],
        );
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, songWithLoop.toMap());

        final updatedLoop = MockData.loopVerse.copyWith(
          name: 'Updated Verse',
          end: const Duration(minutes: 2),
        );

        final updatedSong = await songRepository.updateLoopForSong(
          song: songWithLoop,
          loop: updatedLoop,
        );

        expect(updatedSong.loops.first.name, 'Updated Verse');
        expect(updatedSong.loops.first.end, const Duration(minutes: 2));
      });

      test('does not modify other loops when updating one', () async {
        final songWithLoops = MockData.songMedium.copyWith(
          loops: [MockData.loopVerse, MockData.loopChorus],
        );
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, songWithLoops.toMap());

        final updatedVerse = MockData.loopVerse.copyWith(name: 'Updated Verse');

        final updatedSong = await songRepository.updateLoopForSong(
          song: songWithLoops,
          loop: updatedVerse,
        );

        expect(updatedSong.loops, hasLength(2));
        expect(updatedSong.loops[0].name, 'Updated Verse');
        expect(updatedSong.loops[1].name, MockData.loopChorus.name);
      });
    });

    group('deleteLoopForSong', () {
      test('removes loop from song', () async {
        final songWithLoops = MockData.songMedium.copyWith(
          loops: [MockData.loopVerse, MockData.loopChorus],
        );
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, songWithLoops.toMap());

        final updatedSong = await songRepository.deleteLoopForSong(
          song: songWithLoops,
          loop: MockData.loopVerse,
        );

        expect(updatedSong.loops, hasLength(1));
        expect(updatedSong.loops.first.id, MockData.loopChorus.id);
      });

      test('returns song with empty loops when last loop is deleted', () async {
        final songWithLoop = MockData.songMedium.copyWith(
          loops: [MockData.loopVerse],
        );
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, songWithLoop.toMap());

        final updatedSong = await songRepository.deleteLoopForSong(
          song: songWithLoop,
          loop: MockData.loopVerse,
        );

        expect(updatedSong.loops, isEmpty);
      });
    });

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

      test(
        'new songs are inserted with sortOrder 0 and existing songs shift down',
        () async {
          final store = StoreRef<String, Map<String, dynamic>>('songs');
          await store.add(
            db,
            MockData.songShort.copyWith(sortOrder: 0).toMap(),
          );
          await store.add(
            db,
            MockData.songMedium.copyWith(sortOrder: 1).toMap(),
          );

          // Simulate adding a new song by calling the internal insert logic
          await songRepository.incrementExistingSortOrders();

          final songs = await songRepository.getAllSongs();
          // Existing songs should have shifted: 0->1, 1->2
          expect(songs[0].sortOrder, 1);
          expect(songs[1].sortOrder, 2);
        },
      );

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

    group('clearDb', () {
      test('removes all songs from database', () async {
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songShort.toMap());
        await store.add(db, MockData.songMedium.toMap());
        await store.add(db, MockData.songLong.toMap());

        var songs = await songRepository.getAllSongs();
        expect(songs, hasLength(3));

        await songRepository.clearDb();

        songs = await songRepository.getAllSongs();
        expect(songs, isEmpty);
      });
    });

    group('stream behavior', () {
      test(
        'songs stream is broadcast and can have multiple listeners',
        () async {
          final store = StoreRef<String, Map<String, dynamic>>('songs');
          await store.add(db, MockData.songShort.toMap());

          final results1 = <List<Song>>[];
          final results2 = <List<Song>>[];

          final sub1 = songRepository.songs.listen(results1.add);
          final sub2 = songRepository.songs.listen(results2.add);

          await songRepository.getAllSongs();
          await Future<void>.delayed(Duration.zero);

          await sub1.cancel();
          await sub2.cancel();

          expect(results1, isNotEmpty);
          expect(results2, isNotEmpty);
          // Compare by id since Song's hashCode involves async path getter
          expect(results1.last.first.id, results2.last.first.id);
        },
      );
    });
  });
}
