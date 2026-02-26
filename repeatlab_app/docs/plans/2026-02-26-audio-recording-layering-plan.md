# Audio Recording & Layering Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Allow users to record audio over imported tracks with loop-aware boundaries, manage recording layers, and export mixed audio.

**Architecture:** Use `record` package for mic capture, store WAV files on disk, persist layer metadata in Sembast via a new `RecordingRepository`, manage recording lifecycle with `RecordingCubit`, and play back layers via SoLoud alongside the existing AudioPlayers backing track. Feature-gated: 1 free layer per song, unlimited for premium.

**Tech Stack:** `record` (recording), `flutter_soloud` (layer playback), `ffmpeg_kit_flutter_new_min` (export mix-down), `sembast` (persistence), `flutter_bloc` (state), `dart_mappable` (models), `permission_handler` (mic permissions)

---

### Task 1: Add Dependencies

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Add record and permission_handler packages**

Add to `pubspec.yaml` dependencies section:

```yaml
  record: ^5.2.1
  permission_handler: ^11.3.1
```

**Step 2: Install dependencies**

Run: `flutter pub get`
Expected: Dependencies resolve successfully

**Step 3: Configure platform permissions**

Add microphone permission to iOS Info.plist at `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>RepeatLab needs microphone access to record your practice sessions over imported tracks.</string>
```

Add microphone permission to Android manifest at `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

**Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml
git commit -m "chore: add record and permission_handler dependencies"
```

---

### Task 2: Create RecordingLayer Model

**Files:**
- Create: `lib/data/models/recording_layer.dart`
- Test: `test/data/models/recording_layer_test.dart`
- Modify: `test/helpers/mock_data.dart`

**Step 1: Write the failing test**

Create `test/data/models/recording_layer_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:repeatlab/data/models/recording_layer.dart';

void main() {
  group('RecordingLayer', () {
    test('creates instance with required fields', () {
      final layer = RecordingLayer(
        id: 'layer-1',
        songId: 'song-1',
        filePath: '/path/to/recording.wav',
        startPosition: const Duration(seconds: 30),
        duration: const Duration(seconds: 15),
        createdAt: DateTime(2026, 2, 26),
      );

      expect(layer.id, 'layer-1');
      expect(layer.songId, 'song-1');
      expect(layer.filePath, '/path/to/recording.wav');
      expect(layer.startPosition, const Duration(seconds: 30));
      expect(layer.duration, const Duration(seconds: 15));
      expect(layer.volume, 1.0);
      expect(layer.isMuted, false);
      expect(layer.label, isNull);
    });

    test('serializes to and from map', () {
      final layer = RecordingLayer(
        id: 'layer-1',
        songId: 'song-1',
        filePath: '/path/to/recording.wav',
        startPosition: const Duration(seconds: 30),
        duration: const Duration(seconds: 15),
        createdAt: DateTime(2026, 2, 26),
        volume: 0.8,
        isMuted: true,
        label: 'Guitar take 1',
      );

      final map = layer.toMap();
      final restored = RecordingLayerMapper.fromMap(map);

      expect(restored.id, layer.id);
      expect(restored.songId, layer.songId);
      expect(restored.filePath, layer.filePath);
      expect(restored.startPosition, layer.startPosition);
      expect(restored.duration, layer.duration);
      expect(restored.volume, layer.volume);
      expect(restored.isMuted, layer.isMuted);
      expect(restored.label, layer.label);
      expect(restored.createdAt, layer.createdAt);
    });

    test('copyWith creates modified copy', () {
      final layer = RecordingLayer(
        id: 'layer-1',
        songId: 'song-1',
        filePath: '/path/to/recording.wav',
        startPosition: const Duration(seconds: 30),
        duration: const Duration(seconds: 15),
        createdAt: DateTime(2026, 2, 26),
      );

      final muted = layer.copyWith(isMuted: true, volume: 0.5);

      expect(muted.isMuted, true);
      expect(muted.volume, 0.5);
      expect(muted.id, layer.id);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/recording_layer_test.dart`
Expected: FAIL - cannot find `recording_layer.dart`

**Step 3: Create the RecordingLayer model**

Create `lib/data/models/recording_layer.dart`:

```dart
import 'package:dart_mappable/dart_mappable.dart';
import 'package:repeatlab/data/models/song.dart';

part 'recording_layer.mapper.dart';

@MappableClass(
  includeCustomMappers: [DurationMapper(), DateTimeMapper()],
)
class RecordingLayer with RecordingLayerMappable {
  final String id;
  final String songId;
  final String filePath;
  final Duration startPosition;
  final Duration duration;
  final double volume;
  final bool isMuted;
  final DateTime createdAt;
  final String? label;

  const RecordingLayer({
    required this.id,
    required this.songId,
    required this.filePath,
    required this.startPosition,
    required this.duration,
    required this.createdAt,
    this.volume = 1.0,
    this.isMuted = false,
    this.label,
  });
}

class DateTimeMapper extends SimpleMapper<DateTime> {
  const DateTimeMapper();

  @override
  DateTime decode(dynamic value) {
    return DateTime.fromMillisecondsSinceEpoch(value as int);
  }

  @override
  dynamic encode(DateTime self) {
    return self.millisecondsSinceEpoch;
  }
}
```

**Step 4: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `recording_layer.mapper.dart`

**Step 5: Run test to verify it passes**

Run: `flutter test test/data/models/recording_layer_test.dart`
Expected: PASS

**Step 6: Add mock data for tests**

Add to `test/helpers/mock_data.dart`:

```dart
import 'package:repeatlab/data/models/recording_layer.dart';
```

And add these constants inside the `MockData` class:

```dart
  // ========== Recording Layers ==========

  static final recordingLayer1 = RecordingLayer(
    id: 'recording-1',
    songId: 'song-medium',
    filePath: '/recordings/song-medium/recording-1.wav',
    startPosition: const Duration(seconds: 15),
    duration: const Duration(seconds: 15),
    createdAt: DateTime(2026, 2, 26),
    label: 'Guitar take 1',
  );

  static final recordingLayer2 = RecordingLayer(
    id: 'recording-2',
    songId: 'song-medium',
    filePath: '/recordings/song-medium/recording-2.wav',
    startPosition: const Duration(minutes: 1, seconds: 30),
    duration: const Duration(seconds: 30),
    createdAt: DateTime(2026, 2, 26),
    volume: 0.8,
  );
```

**Step 7: Commit**

```bash
git add lib/data/models/recording_layer.dart lib/data/models/recording_layer.mapper.dart test/data/models/recording_layer_test.dart test/helpers/mock_data.dart
git commit -m "feat: add RecordingLayer model with serialization"
```

---

### Task 3: Create RecordingRepository

**Files:**
- Create: `lib/data/repositories/recording_repository.dart`
- Test: `test/data/repositories/recording_repository_test.dart`
- Modify: `test/helpers/mock_repositories.dart`

**Step 1: Write the failing test**

Create `test/data/repositories/recording_repository_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:repeatlab/data/models/recording_layer.dart';
import 'package:repeatlab/data/repositories/recording_repository.dart';
import 'package:sembast/sembast_memory.dart';

import '../../helpers/mock_data.dart';

void main() {
  late Database db;
  late RecordingRepository repository;

  setUp(() async {
    db = await databaseFactoryMemory.openDatabase('test.db');
    repository = RecordingRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('RecordingRepository', () {
    test('returns empty list when no layers exist for song', () async {
      final layers = await repository.getLayersForSong('nonexistent');
      expect(layers, isEmpty);
    });

    test('adds and retrieves a recording layer', () async {
      await repository.addLayer(MockData.recordingLayer1);

      final layers = await repository.getLayersForSong('song-medium');
      expect(layers, hasLength(1));
      expect(layers.first.id, 'recording-1');
      expect(layers.first.songId, 'song-medium');
    });

    test('updates a recording layer', () async {
      await repository.addLayer(MockData.recordingLayer1);

      final updated = MockData.recordingLayer1.copyWith(
        volume: 0.5,
        isMuted: true,
      );
      await repository.updateLayer(updated);

      final layers = await repository.getLayersForSong('song-medium');
      expect(layers.first.volume, 0.5);
      expect(layers.first.isMuted, true);
    });

    test('deletes a recording layer', () async {
      await repository.addLayer(MockData.recordingLayer1);
      await repository.addLayer(MockData.recordingLayer2);

      await repository.deleteLayer(MockData.recordingLayer1);

      final layers = await repository.getLayersForSong('song-medium');
      expect(layers, hasLength(1));
      expect(layers.first.id, 'recording-2');
    });

    test('deletes all layers for a song', () async {
      await repository.addLayer(MockData.recordingLayer1);
      await repository.addLayer(MockData.recordingLayer2);

      await repository.deleteAllLayersForSong('song-medium');

      final layers = await repository.getLayersForSong('song-medium');
      expect(layers, isEmpty);
    });

    test('counts layers for a song', () async {
      await repository.addLayer(MockData.recordingLayer1);
      await repository.addLayer(MockData.recordingLayer2);

      final count = await repository.getLayerCountForSong('song-medium');
      expect(count, 2);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/data/repositories/recording_repository_test.dart`
Expected: FAIL - cannot find `recording_repository.dart`

**Step 3: Create the RecordingRepository**

Create `lib/data/repositories/recording_repository.dart`:

```dart
import 'dart:developer';
import 'dart:io';

import 'package:repeatlab/data/models/recording_layer.dart';
import 'package:sembast/sembast.dart';

class RecordingRepository {
  final Database db;

  final _store = StoreRef<String, Map<String, dynamic>>('recording_layers');

  RecordingRepository({required this.db});

  Future<List<RecordingLayer>> getLayersForSong(String songId) async {
    final records = await _store.find(
      db,
      finder: Finder(filter: Filter.equals('songId', songId)),
    );
    return records
        .map((r) => RecordingLayerMapper.fromMap(r.value))
        .toList();
  }

  Future<void> addLayer(RecordingLayer layer) async {
    await _store.add(db, layer.toMap());
  }

  Future<void> updateLayer(RecordingLayer layer) async {
    await _store.update(
      db,
      layer.toMap(),
      finder: Finder(filter: Filter.equals('id', layer.id)),
    );
  }

  Future<void> deleteLayer(RecordingLayer layer) async {
    await _store.delete(
      db,
      finder: Finder(filter: Filter.equals('id', layer.id)),
    );

    // Delete the audio file from disk
    try {
      final file = File(layer.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (ex) {
      log('Failed to delete recording file: $ex', name: 'RecordingRepository');
    }
  }

  Future<void> deleteAllLayersForSong(String songId) async {
    final layers = await getLayersForSong(songId);

    // Delete all audio files
    for (final layer in layers) {
      try {
        final file = File(layer.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (ex) {
        log('Failed to delete recording file: $ex', name: 'RecordingRepository');
      }
    }

    // Delete the song's recording directory
    try {
      final dir = Directory(layers.first.filePath).parent;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      // Directory may not exist or layers may be empty
    }

    await _store.delete(
      db,
      finder: Finder(filter: Filter.equals('songId', songId)),
    );
  }

  Future<int> getLayerCountForSong(String songId) async {
    final records = await _store.find(
      db,
      finder: Finder(filter: Filter.equals('songId', songId)),
    );
    return records.length;
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/data/repositories/recording_repository_test.dart`
Expected: PASS

**Step 5: Add mock to test helpers**

Add to `test/helpers/mock_repositories.dart`:

```dart
import 'package:repeatlab/data/repositories/recording_repository.dart';

class MockRecordingRepository extends Mock implements RecordingRepository {}
```

**Step 6: Register RecordingRepository in dependency injection**

Modify `lib/app/view/repository_wrapper.dart` — add import and provider:

Import:
```dart
import 'package:repeatlab/data/repositories/recording_repository.dart';
```

Add after the `SongRepository` provider:
```dart
        RepositoryProvider(
          create: (context) => RecordingRepository(db: db),
        ),
```

**Step 7: Commit**

```bash
git add lib/data/repositories/recording_repository.dart test/data/repositories/recording_repository_test.dart test/helpers/mock_repositories.dart lib/app/view/repository_wrapper.dart
git commit -m "feat: add RecordingRepository with Sembast persistence"
```

---

### Task 4: Create RecordingCubit with State

**Files:**
- Create: `lib/features/song/cubit/recording/recording_cubit.dart`
- Create: `lib/features/song/cubit/recording/recording_state.dart`
- Test: `test/features/song/cubit/recording_cubit_test.dart`

**Step 1: Write the failing test**

Create `test/features/song/cubit/recording_cubit_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/data/models/recording_layer.dart';
import 'package:repeatlab/features/song/cubit/recording/recording_cubit.dart';

import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockRecordingRepository mockRecordingRepository;
  late MockCrashReportingRepository mockCrashReportingRepository;

  setUpAll(() {
    registerFallbackValue(MockData.recordingLayer1);
    registerFallbackValue(StackTrace.empty);
  });

  setUp(() {
    mockRecordingRepository = MockRecordingRepository();
    mockCrashReportingRepository = MockCrashReportingRepository();

    when(
      () => mockCrashReportingRepository.reportError(any(), any()),
    ).thenAnswer((_) async => null);
  });

  group('RecordingCubit', () {
    test('has correct initial state', () {
      final cubit = RecordingCubit(
        songId: 'song-1',
        recordingRepository: mockRecordingRepository,
        crashReportingRepository: mockCrashReportingRepository,
      );

      expect(cubit.state.status, RecordingStatus.idle);
      expect(cubit.state.layers, isEmpty);
      expect(cubit.state.countdownValue, isNull);
      expect(cubit.state.activeLayerId, isNull);
      expect(cubit.state.error, isNull);
    });

    test('loadLayers fetches layers from repository', () async {
      when(
        () => mockRecordingRepository.getLayersForSong('song-1'),
      ).thenAnswer((_) async => [MockData.recordingLayer1]);

      final cubit = RecordingCubit(
        songId: 'song-1',
        recordingRepository: mockRecordingRepository,
        crashReportingRepository: mockCrashReportingRepository,
      );

      await cubit.loadLayers();

      expect(cubit.state.layers, hasLength(1));
      expect(cubit.state.layers.first.id, 'recording-1');
    });

    test('toggleMute toggles mute state for layer', () async {
      when(
        () => mockRecordingRepository.getLayersForSong('song-1'),
      ).thenAnswer((_) async => [MockData.recordingLayer1]);
      when(
        () => mockRecordingRepository.updateLayer(any()),
      ).thenAnswer((_) async {});

      final cubit = RecordingCubit(
        songId: 'song-1',
        recordingRepository: mockRecordingRepository,
        crashReportingRepository: mockCrashReportingRepository,
      );

      await cubit.loadLayers();
      await cubit.toggleMute(MockData.recordingLayer1);

      expect(cubit.state.layers.first.isMuted, true);
    });

    test('setVolume updates layer volume', () async {
      when(
        () => mockRecordingRepository.getLayersForSong('song-1'),
      ).thenAnswer((_) async => [MockData.recordingLayer1]);
      when(
        () => mockRecordingRepository.updateLayer(any()),
      ).thenAnswer((_) async {});

      final cubit = RecordingCubit(
        songId: 'song-1',
        recordingRepository: mockRecordingRepository,
        crashReportingRepository: mockCrashReportingRepository,
      );

      await cubit.loadLayers();
      await cubit.setVolume(MockData.recordingLayer1, 0.5);

      expect(cubit.state.layers.first.volume, 0.5);
    });

    test('deleteLayer removes layer from state', () async {
      when(
        () => mockRecordingRepository.getLayersForSong('song-1'),
      ).thenAnswer((_) async => [MockData.recordingLayer1, MockData.recordingLayer2]);
      when(
        () => mockRecordingRepository.deleteLayer(any()),
      ).thenAnswer((_) async {});

      final cubit = RecordingCubit(
        songId: 'song-1',
        recordingRepository: mockRecordingRepository,
        crashReportingRepository: mockCrashReportingRepository,
      );

      await cubit.loadLayers();
      await cubit.deleteLayer(MockData.recordingLayer1);

      expect(cubit.state.layers, hasLength(1));
      expect(cubit.state.layers.first.id, 'recording-2');
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/song/cubit/recording_cubit_test.dart`
Expected: FAIL - cannot find `recording_cubit.dart`

**Step 3: Create the RecordingState**

Create `lib/features/song/cubit/recording/recording_state.dart`:

```dart
part of 'recording_cubit.dart';

@MappableEnum()
enum RecordingStatus {
  idle,
  permissionDenied,
  countdown,
  recording,
  saving,
  error,
}

@MappableClass()
class RecordingState with RecordingStateMappable {
  final RecordingStatus status;
  final List<RecordingLayer> layers;
  final int? countdownValue;
  final String? activeLayerId;
  final Duration? currentRecordingDuration;
  final String? error;

  const RecordingState({
    this.status = RecordingStatus.idle,
    this.layers = const [],
    this.countdownValue,
    this.activeLayerId,
    this.currentRecordingDuration,
    this.error,
  });
}
```

**Step 4: Create the RecordingCubit**

Create `lib/features/song/cubit/recording/recording_cubit.dart`:

```dart
import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:repeatlab/data/models/recording_layer.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/recording_repository.dart';
import 'package:uuid/uuid.dart';

part 'recording_cubit.mapper.dart';
part 'recording_state.dart';

class RecordingCubit extends Cubit<RecordingState> {
  final String songId;
  final RecordingRepository recordingRepository;
  final CrashReportingRepository crashReportingRepository;

  Timer? _countdownTimer;
  AudioRecorder? _recorder;

  RecordingCubit({
    required this.songId,
    required this.recordingRepository,
    required this.crashReportingRepository,
  }) : super(const RecordingState());

  Future<void> loadLayers() async {
    try {
      final layers = await recordingRepository.getLayersForSong(songId);
      emit(state.copyWith(layers: layers));
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(state.copyWith(
        status: RecordingStatus.error,
        error: 'Failed to load recording layers: $ex',
      ));
    }
  }

  /// Start the recording countdown. When countdown finishes,
  /// calls [onCountdownComplete] so the caller can start playback,
  /// then begins recording.
  Future<void> startRecording({
    required Duration startPosition,
    required Duration? stopPosition,
    required Future<void> Function() onCountdownComplete,
  }) async {
    // Check microphone permission
    _recorder = AudioRecorder();
    final hasPermission = await _recorder!.hasPermission();

    if (!hasPermission) {
      emit(state.copyWith(status: RecordingStatus.permissionDenied));
      return;
    }

    // Start countdown
    emit(state.copyWith(
      status: RecordingStatus.countdown,
      countdownValue: 3,
    ));

    _countdownTimer?.cancel();
    var count = 3;

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) async {
        count--;
        if (count > 0) {
          emit(state.copyWith(countdownValue: count));
        } else {
          timer.cancel();
          await onCountdownComplete();
          await _beginRecording(startPosition, stopPosition);
        }
      },
    );
  }

  Future<void> _beginRecording(
    Duration startPosition,
    Duration? stopPosition,
  ) async {
    try {
      final layerId = const Uuid().v4();
      final appDir = await getApplicationDocumentsDirectory();
      final recordingDir = Directory('${appDir.path}/recordings/$songId');
      if (!await recordingDir.exists()) {
        await recordingDir.create(recursive: true);
      }
      final filePath = '${recordingDir.path}/$layerId.wav';

      await _recorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          numChannels: 1,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      emit(state.copyWith(
        status: RecordingStatus.recording,
        activeLayerId: layerId,
        countdownValue: null,
      ));

      dev.log('Recording started: $filePath', name: 'RecordingCubit');
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(state.copyWith(
        status: RecordingStatus.error,
        error: 'Failed to start recording: $ex',
        countdownValue: null,
      ));
    }
  }

  Future<void> stopRecording({
    required Duration startPosition,
  }) async {
    if (state.status != RecordingStatus.recording) return;

    emit(state.copyWith(status: RecordingStatus.saving));

    try {
      final path = await _recorder!.stop();
      if (path == null) {
        emit(state.copyWith(
          status: RecordingStatus.error,
          error: 'Recording failed - no file produced',
        ));
        return;
      }

      final file = File(path);
      if (!await file.exists()) {
        emit(state.copyWith(
          status: RecordingStatus.error,
          error: 'Recording file not found',
        ));
        return;
      }

      // Calculate recording duration from file
      // WAV at 44100Hz, 16-bit, mono: 88200 bytes per second + 44 byte header
      final fileSize = await file.length();
      final durationMs = ((fileSize - 44) / 88200 * 1000).round();
      final duration = Duration(milliseconds: durationMs);

      final layer = RecordingLayer(
        id: state.activeLayerId!,
        songId: songId,
        filePath: path,
        startPosition: startPosition,
        duration: duration,
        createdAt: DateTime.now(),
      );

      await recordingRepository.addLayer(layer);

      emit(state.copyWith(
        status: RecordingStatus.idle,
        layers: [...state.layers, layer],
        activeLayerId: null,
      ));

      dev.log('Recording saved: $path (${duration.inSeconds}s)', name: 'RecordingCubit');
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(state.copyWith(
        status: RecordingStatus.error,
        error: 'Failed to save recording: $ex',
        activeLayerId: null,
      ));
    }
  }

  void cancelRecording() {
    _countdownTimer?.cancel();
    _recorder?.stop();
    _recorder?.dispose();
    emit(state.copyWith(
      status: RecordingStatus.idle,
      countdownValue: null,
      activeLayerId: null,
    ));
  }

  Future<void> toggleMute(RecordingLayer layer) async {
    final updated = layer.copyWith(isMuted: !layer.isMuted);
    try {
      await recordingRepository.updateLayer(updated);
      final updatedLayers = state.layers
          .map((l) => l.id == layer.id ? updated : l)
          .toList();
      emit(state.copyWith(layers: updatedLayers));
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
    }
  }

  Future<void> setVolume(RecordingLayer layer, double volume) async {
    final updated = layer.copyWith(volume: volume.clamp(0.0, 1.0));
    try {
      await recordingRepository.updateLayer(updated);
      final updatedLayers = state.layers
          .map((l) => l.id == layer.id ? updated : l)
          .toList();
      emit(state.copyWith(layers: updatedLayers));
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
    }
  }

  Future<void> deleteLayer(RecordingLayer layer) async {
    try {
      await recordingRepository.deleteLayer(layer);
      final updatedLayers = state.layers
          .where((l) => l.id != layer.id)
          .toList();
      emit(state.copyWith(layers: updatedLayers));
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
    }
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _recorder?.dispose();
    return super.close();
  }
}
```

**Step 5: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates mapper files

**Step 6: Run test to verify it passes**

Run: `flutter test test/features/song/cubit/recording_cubit_test.dart`
Expected: PASS

**Step 7: Commit**

```bash
git add lib/features/song/cubit/recording/ test/features/song/cubit/recording_cubit_test.dart
git commit -m "feat: add RecordingCubit with state management"
```

---

### Task 5: Add Localization Strings

**Files:**
- Modify: `lib/l10n/arb/app_en.arb`

**Step 1: Add English localization strings**

Add the following entries to `lib/l10n/arb/app_en.arb` (before the closing `}`):

```json
    "record": "Record",
    "recording": "Recording...",
    "recordings": "Recordings",
    "recordingLayers": "Recording Layers",
    "startRecording": "Start Recording",
    "stopRecording": "Stop Recording",
    "deleteRecording": "Delete Recording",
    "deleteRecordingConfirmation": "Are you sure you want to delete this recording?",
    "recordingAdded": "Recording added",
    "recordingDeleted": "Recording deleted",
    "microphonePermissionRequired": "Microphone permission is required to record audio",
    "microphonePermissionDenied": "Microphone permission denied. Please enable it in Settings.",
    "exportMix": "Export Mix",
    "exportMixDescription": "Merge all recording layers with the original track into a single file",
    "mute": "Mute",
    "unmute": "Unmute",
    "volume": "Volume",
    "noRecordings": "No recordings yet",
    "tapRecordToStart": "Tap the record button to start",
    "recordingLayersPremiumDescription": "Upgrade to add more recording layers",
    "premiumFeatureRecordingLayers": "Unlimited Recording Layers"
```

**Step 2: Run localization generation**

Run: `flutter gen-l10n`
Expected: Generates updated localization files

**Step 3: Commit**

```bash
git add lib/l10n/
git commit -m "feat: add localization strings for recording feature"
```

---

### Task 6: Add Record Button to SongController

**Files:**
- Modify: `lib/features/song/view/song_controller.dart`
- Modify: `lib/features/song/view/song_page.dart`

**Step 1: Add RecordingCubit provider to SongPage**

Modify `lib/features/song/view/song_page.dart` — add import:

```dart
import 'package:repeatlab/data/repositories/recording_repository.dart';
import 'package:repeatlab/features/song/cubit/recording/recording_cubit.dart';
```

Add a new `BlocProvider` in the `MultiBlocProvider.providers` list after the `SongExporterCubit` provider:

```dart
        BlocProvider(
          create: (context) => RecordingCubit(
            songId: song.id,
            recordingRepository: context.read<RecordingRepository>(),
            crashReportingRepository: context.read<CrashReportingRepository>(),
          )..loadLayers(),
        ),
```

**Step 2: Add record button to SongController**

Modify `lib/features/song/view/song_controller.dart` — add import:

```dart
import 'package:repeatlab/features/song/cubit/recording/recording_cubit.dart';
```

Add a record button between the play button and the forward button. After the play/pause `BlocSelector` and `const SizedBox(width: 8)`, add:

```dart
              BlocSelector<RecordingCubit, RecordingState, RecordingStatus>(
                selector: (state) => state.status,
                builder: (context, status) {
                  final isRecording = status == RecordingStatus.recording;
                  final isCountdown = status == RecordingStatus.countdown;
                  return SizedBox(
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: isCountdown
                          ? null
                          : () => _onTapRecord(context),
                      icon: Icon(
                        isRecording
                            ? Icons.stop_circle_rounded
                            : Icons.fiber_manual_record_rounded,
                        size: 24,
                        color: (isRecording || isCountdown)
                            ? Colors.red
                            : null,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
```

Add the `_onTapRecord` method to the `SongController` class:

```dart
  void _onTapRecord(BuildContext context) {
    final recordingCubit = context.read<RecordingCubit>();
    final songCubit = context.read<SongCubit>();

    if (recordingCubit.state.status == RecordingStatus.recording) {
      // Stop recording
      songCubit.pauseSong();
      recordingCubit.stopRecording(
        startPosition: recordingCubit.state.layers.isEmpty
            ? Duration.zero
            : Duration.zero, // Will be set properly when recording starts
      );
    } else {
      // Start recording
      final activeLoop = songCubit.state.activeLoop;
      final startPos = activeLoop?.start ?? Duration.zero;
      final stopPos = activeLoop?.end;

      // Pause current playback, seek to start
      songCubit.pauseSong();
      songCubit.seekSong(startPos);

      recordingCubit.startRecording(
        startPosition: startPos,
        stopPosition: stopPos,
        onCountdownComplete: () async {
          await songCubit.seekSong(startPos);
          if (songCubit.state.isLoopModeEnabled && activeLoop != null) {
            await songCubit.togglePlayLoop(activeLoop);
          } else {
            await songCubit.togglePlaySong();
          }
        },
      );
    }
  }
```

**Step 3: Verify build compiles**

Run: `flutter build apk --debug --target-platform android-arm64 2>&1 | tail -5` (or just `flutter analyze`)
Expected: No compilation errors

**Step 4: Commit**

```bash
git add lib/features/song/view/song_controller.dart lib/features/song/view/song_page.dart
git commit -m "feat: add record button to song controller"
```

---

### Task 7: Add Countdown Overlay

**Files:**
- Create: `lib/features/song/widgets/recording_countdown_overlay.dart`
- Modify: `lib/features/song/view/song_page.dart`

**Step 1: Create the countdown overlay widget**

Create `lib/features/song/widgets/recording_countdown_overlay.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/features/song/cubit/recording/recording_cubit.dart';

class RecordingCountdownOverlay extends StatelessWidget {
  const RecordingCountdownOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RecordingCubit, RecordingState, int?>(
      selector: (state) =>
          state.status == RecordingStatus.countdown
              ? state.countdownValue
              : null,
      builder: (context, countdownValue) {
        if (countdownValue == null) return const SizedBox.shrink();

        return Container(
          color: Colors.black54,
          child: Center(
            child: Text(
              '$countdownValue',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 96,
              ),
            ),
          ),
        );
      },
    );
  }
}
```

**Step 2: Add overlay to SongPage**

Modify `lib/features/song/view/song_page.dart` — add import:

```dart
import 'package:repeatlab/features/song/widgets/recording_countdown_overlay.dart';
```

Wrap the `Scaffold` body in a `Stack` to overlay the countdown. In the `default` case of the `BlocSelector`, change the `Scaffold` to include a `Stack`:

```dart
                body: Stack(
                  children: [
                    CustomScrollView(
                      // ... existing sliver content ...
                    ),
                    const Positioned.fill(
                      child: RecordingCountdownOverlay(),
                    ),
                  ],
                ),
```

**Step 3: Verify build compiles**

Run: `flutter analyze`
Expected: No errors

**Step 4: Commit**

```bash
git add lib/features/song/widgets/recording_countdown_overlay.dart lib/features/song/view/song_page.dart
git commit -m "feat: add recording countdown overlay"
```

---

### Task 8: Add Loop-Aware Auto-Stop

**Files:**
- Modify: `lib/features/song/view/song_page.dart`

**Step 1: Add position listener for auto-stop**

In `_SongViewState`, add a `BlocListener` for the `RecordingCubit` inside the existing `MultiBlocListener.listeners` list:

```dart
        BlocListener<RecordingCubit, RecordingState>(
          listenWhen: (previous, current) =>
              previous.status != current.status,
          listener: (context, recordingState) {
            if (recordingState.status == RecordingStatus.idle &&
                recordingState.layers.length > (previous?.layers.length ?? 0)) {
              SnackbarHelper.showSuccess(context, context.l10n.recordingAdded);
            } else if (recordingState.status == RecordingStatus.permissionDenied) {
              SnackbarHelper.showError(
                context,
                context.l10n.microphonePermissionDenied,
              );
            } else if (recordingState.status == RecordingStatus.error) {
              SnackbarHelper.showError(
                context,
                recordingState.error ?? 'Recording error',
              );
            }
          },
        ),
```

Also add a position stream listener for auto-stop at loop boundary. In `_SongViewState`, add a `StreamSubscription` field and set it up in `initState` or via a `BlocListener`. The simplest approach: in the `SongController._onTapRecord` method, set up a position listener that checks if the loop end is reached and stops recording.

A cleaner approach: Add auto-stop logic to `RecordingCubit.startRecording` by accepting a `Stream<Duration>` positionStream and listening for the stop position:

Modify `lib/features/song/cubit/recording/recording_cubit.dart` — add a field and update `_beginRecording`:

```dart
  StreamSubscription<Duration>? _positionSubscription;
```

In `_beginRecording`, after `emit(state.copyWith(...))`, add:

```dart
      // Set up auto-stop at loop boundary
      if (stopPosition != null && positionStream != null) {
        _positionSubscription?.cancel();
        _positionSubscription = positionStream!.listen((position) {
          if (position >= stopPosition && state.status == RecordingStatus.recording) {
            stopRecording(startPosition: startPosition);
            _positionSubscription?.cancel();
          }
        });
      }
```

Update `startRecording` signature to accept the position stream:

```dart
  Future<void> startRecording({
    required Duration startPosition,
    required Duration? stopPosition,
    required Future<void> Function() onCountdownComplete,
    Stream<Duration>? positionStream,
  }) async {
```

Store it as a field:

```dart
  Stream<Duration>? _positionStream;
```

And in `startRecording`, before the countdown: `_positionStream = positionStream;`

Pass it through to `_beginRecording`.

Update `close()` and `cancelRecording()` to cancel `_positionSubscription`.

**Step 2: Update SongController to pass position stream**

In `lib/features/song/view/song_controller.dart`, update the `_onTapRecord` call:

```dart
      recordingCubit.startRecording(
        startPosition: startPos,
        stopPosition: stopPos,
        positionStream: songCubit.positionStream,
        onCountdownComplete: () async {
          // ...
        },
      );
```

**Step 3: Run tests**

Run: `flutter test test/features/song/cubit/recording_cubit_test.dart`
Expected: PASS

**Step 4: Commit**

```bash
git add lib/features/song/cubit/recording/recording_cubit.dart lib/features/song/view/song_controller.dart lib/features/song/view/song_page.dart
git commit -m "feat: add loop-aware auto-stop and recording status listeners"
```

---

### Task 9: Create Recording Layers Panel UI

**Files:**
- Create: `lib/features/song/widgets/recording_layer_tile.dart`
- Create: `lib/features/song/widgets/recording_layers_panel.dart`
- Modify: `lib/features/song/view/song_page.dart`

**Step 1: Create RecordingLayerTile widget**

Create `lib/features/song/widgets/recording_layer_tile.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/duration_extension.dart';
import 'package:repeatlab/data/models/recording_layer.dart';
import 'package:repeatlab/l10n/l10n.dart';

class RecordingLayerTile extends StatelessWidget {
  final RecordingLayer layer;
  final VoidCallback onToggleMute;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onDelete;

  const RecordingLayerTile({
    super.key,
    required this.layer,
    required this.onToggleMute,
    required this.onVolumeChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: layer.isMuted ? Colors.grey : AppColors.primaryContainer,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              Icon(
                Icons.mic,
                size: 16,
                color: layer.isMuted ? Colors.grey : Colors.red,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  layer.label ?? context.l10n.record,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: layer.isMuted ? Colors.grey : null,
                  ),
                ),
              ),
              Text(
                layer.startPosition.toFormattedString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Text(' - '),
              Text(
                (layer.startPosition + layer.duration).toFormattedString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onToggleMute,
                  icon: Icon(
                    layer.isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Icon(Icons.volume_down, size: 16),
                Expanded(
                  child: Slider(
                    value: layer.volume,
                    onChanged: onVolumeChanged,
                    min: 0.0,
                    max: 1.0,
                  ),
                ),
                const Icon(Icons.volume_up, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Create RecordingLayersPanel widget**

Create `lib/features/song/widgets/recording_layers_panel.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/data/models/recording_layer.dart';
import 'package:repeatlab/features/song/cubit/recording/recording_cubit.dart';
import 'package:repeatlab/features/song/widgets/recording_layer_tile.dart';
import 'package:repeatlab/l10n/l10n.dart';

class RecordingLayersPanel extends StatelessWidget {
  const RecordingLayersPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RecordingCubit, RecordingState, List<RecordingLayer>>(
      selector: (state) => state.layers,
      builder: (context, layers) {
        if (layers.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 24),
            AutoSizeText(
              context.l10n.recordings,
              minFontSize: 16,
              maxFontSize: 24,
              style: context.headlineSmall,
            ),
            const SizedBox(height: 8),
            ...layers.map(
              (layer) => RecordingLayerTile(
                key: ValueKey(layer.id),
                layer: layer,
                onToggleMute: () =>
                    context.read<RecordingCubit>().toggleMute(layer),
                onVolumeChanged: (volume) =>
                    context.read<RecordingCubit>().setVolume(layer, volume),
                onDelete: () => _onDeleteLayer(context, layer),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onDeleteLayer(
    BuildContext context,
    RecordingLayer layer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        title: Text(context.l10n.deleteRecording),
        content: Text(context.l10n.deleteRecordingConfirmation),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, color: AppColors.onError),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            label: Text(context.l10n.delete),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<RecordingCubit>().deleteLayer(layer);
    }
  }
}
```

**Step 3: Add RecordingLayersPanel to SongPage**

Modify `lib/features/song/view/song_page.dart` — add import:

```dart
import 'package:repeatlab/features/song/widgets/recording_layers_panel.dart';
```

Add `const RecordingLayersPanel()` in the first `SliverList`'s `SliverChildListDelegate`, after the `SongController` and before the `Divider`:

```dart
                          const RecordingLayersPanel(),
                          const Divider(height: 24),
```

(Remove the existing `const Divider(height: 24)` that was between SongController and the Loops header, since RecordingLayersPanel includes its own divider when layers exist.)

**Step 4: Verify build compiles**

Run: `flutter analyze`
Expected: No errors

**Step 5: Commit**

```bash
git add lib/features/song/widgets/recording_layer_tile.dart lib/features/song/widgets/recording_layers_panel.dart lib/features/song/view/song_page.dart
git commit -m "feat: add recording layers panel UI"
```

---

### Task 10: Add Recording Indicator on Waveform

**Files:**
- Modify: `lib/features/song/widgets/wave_form_soloud.dart`

**Step 1: Add recording indicator**

Modify `lib/features/song/widgets/wave_form_soloud.dart` — add import:

```dart
import 'package:repeatlab/features/song/cubit/recording/recording_cubit.dart';
```

Wrap the existing waveform container in a `BlocSelector` that adds a red border when recording:

```dart
BlocSelector<RecordingCubit, RecordingState, bool>(
  selector: (state) => state.status == RecordingStatus.recording,
  builder: (context, isRecording) {
    return Container(
      decoration: isRecording
          ? BoxDecoration(
              border: Border.all(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: // ... existing waveform widget ...
    );
  },
),
```

**Step 2: Verify build compiles**

Run: `flutter analyze`
Expected: No errors

**Step 3: Commit**

```bash
git add lib/features/song/widgets/wave_form_soloud.dart
git commit -m "feat: add red border recording indicator on waveform"
```

---

### Task 11: Add Layer Playback via SoLoud

**Files:**
- Create: `lib/data/services/recording_playback_service.dart`
- Modify: `lib/features/song/cubit/recording/recording_cubit.dart`
- Modify: `lib/features/song/view/song_page.dart`

**Step 1: Create RecordingPlaybackService**

Create `lib/data/services/recording_playback_service.dart`:

```dart
import 'dart:developer' as dev;

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:repeatlab/data/models/recording_layer.dart';

/// Manages playback of recording layers via SoLoud.
/// Each layer gets its own SoLoud source handle for independent volume/mute.
class RecordingPlaybackService {
  final SoLoud _soloud;

  /// Maps layer ID to loaded SoLoud source
  final Map<String, AudioSource> _sources = {};

  /// Maps layer ID to active sound handle
  final Map<String, SoundHandle> _handles = {};

  RecordingPlaybackService({required SoLoud soloud}) : _soloud = soloud;

  /// Load a recording layer file into SoLoud.
  Future<void> loadLayer(RecordingLayer layer) async {
    if (_sources.containsKey(layer.id)) return;

    try {
      final source = await _soloud.loadFile(layer.filePath);
      _sources[layer.id] = source;
      dev.log('Loaded recording layer: ${layer.id}', name: 'RecordingPlayback');
    } catch (ex) {
      dev.log('Failed to load layer ${layer.id}: $ex', name: 'RecordingPlayback');
      rethrow;
    }
  }

  /// Play a layer at a specific position within the song.
  /// [songPosition] is the current playback position in the song.
  /// The layer will be seeked to the correct offset.
  Future<void> playLayer(RecordingLayer layer, Duration songPosition) async {
    final source = _sources[layer.id];
    if (source == null) return;
    if (layer.isMuted) return;

    // Calculate where in the recording we should be
    final offset = songPosition - layer.startPosition;
    if (offset < Duration.zero || offset > layer.duration) return;

    try {
      final handle = await _soloud.play(
        source,
        volume: layer.volume,
        paused: true,
      );
      _soloud.seek(handle, offset);
      _soloud.setPause(handle, false);
      _handles[layer.id] = handle;
    } catch (ex) {
      dev.log('Failed to play layer ${layer.id}: $ex', name: 'RecordingPlayback');
    }
  }

  /// Start all loaded, unmuted layers at the correct offsets.
  Future<void> playAllLayers(
    List<RecordingLayer> layers,
    Duration songPosition,
  ) async {
    stopAll();
    for (final layer in layers) {
      if (!layer.isMuted) {
        await playLayer(layer, songPosition);
      }
    }
  }

  /// Stop a specific layer.
  void stopLayer(String layerId) {
    final handle = _handles.remove(layerId);
    if (handle != null) {
      try {
        _soloud.stop(handle);
      } catch (_) {}
    }
  }

  /// Stop all playing layers.
  void stopAll() {
    for (final entry in _handles.entries) {
      try {
        _soloud.stop(entry.value);
      } catch (_) {}
    }
    _handles.clear();
  }

  /// Update volume for a specific layer.
  void setLayerVolume(String layerId, double volume) {
    final handle = _handles[layerId];
    if (handle != null) {
      try {
        _soloud.setVolume(handle, volume);
      } catch (_) {}
    }
  }

  /// Mute/unmute a layer.
  void setLayerMute(String layerId, bool isMuted) {
    final handle = _handles[layerId];
    if (handle != null) {
      try {
        _soloud.setPause(handle, isMuted);
      } catch (_) {}
    }
  }

  /// Unload a layer source (when layer is deleted).
  Future<void> unloadLayer(String layerId) async {
    stopLayer(layerId);
    final source = _sources.remove(layerId);
    if (source != null) {
      await _soloud.disposeSource(source);
    }
  }

  /// Dispose all sources.
  Future<void> dispose() async {
    stopAll();
    for (final source in _sources.values) {
      await _soloud.disposeSource(source);
    }
    _sources.clear();
  }
}
```

**Step 2: Integrate with SongPage — sync layer playback with song playback**

This requires listening to the `SongCubit`'s `playerState` changes and starting/stopping layer playback accordingly. The cleanest approach is to add a `BlocListener` in `_SongViewState` that coordinates:

Modify `lib/features/song/view/song_page.dart` — add imports:

```dart
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:repeatlab/data/services/recording_playback_service.dart';
```

In `_SongViewState`, add a field:

```dart
  RecordingPlaybackService? _recordingPlayback;
```

In `initState` (or lazily on first use), initialize it:

```dart
  @override
  void initState() {
    super.initState();
    _recordingPlayback = RecordingPlaybackService(soloud: SoLoud.instance);
  }
```

In `dispose`, clean it up:

```dart
    _recordingPlayback?.dispose();
```

Add a `BlocListener<SongCubit, SongState>` that starts/stops recording layer playback when the main song starts/stops. This listener should be separate from the existing one — add it to the `MultiBlocListener`:

```dart
        BlocListener<SongCubit, SongState>(
          listenWhen: (previous, current) =>
              previous.playerState != current.playerState,
          listener: (context, songState) async {
            final layers = context.read<RecordingCubit>().state.layers;
            if (layers.isEmpty) return;

            if (songState.playerState == PlayerState.playing) {
              // Load layers if needed and start playback
              for (final layer in layers) {
                await _recordingPlayback?.loadLayer(layer);
              }
              final position = await context.read<SongCubit>().position;
              await _recordingPlayback?.playAllLayers(layers, position);
            } else {
              _recordingPlayback?.stopAll();
            }
          },
        ),
```

**Step 3: Verify build compiles**

Run: `flutter analyze`
Expected: No errors

**Step 4: Commit**

```bash
git add lib/data/services/recording_playback_service.dart lib/features/song/view/song_page.dart
git commit -m "feat: add SoLoud-based recording layer playback"
```

---

### Task 12: Add Feature Gating (Premium)

**Files:**
- Modify: `lib/features/song/view/song_controller.dart`
- Modify: `lib/data/models/repeatlab_feature.dart`

**Step 1: Add premium check before recording**

Modify the `_onTapRecord` method in `lib/features/song/view/song_controller.dart` — at the start of the else branch (start recording), add:

```dart
      // Check premium gate: free users get 1 recording per song
      final premiumCubit = context.read<PremiumSubscriptionCubit>();
      if (!premiumCubit.hasPremium &&
          recordingCubit.state.layers.isNotEmpty) {
        AppAnalytics.trackEvent('show_paywall_recording_layers');
        await premiumCubit.presentPaywall();
        return;
      }
```

Add the necessary imports:

```dart
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
```

**Step 2: Add feature to premium features list**

Modify `lib/data/models/repeatlab_feature.dart` — add a new entry to `getPremiumFeatures`:

```dart
  RepeatLabFeature(
    title: translator.premiumFeatureRecordingLayers,
    isPremium: true,
  ),
```

**Step 3: Verify build compiles**

Run: `flutter analyze`
Expected: No errors

**Step 4: Commit**

```bash
git add lib/features/song/view/song_controller.dart lib/data/models/repeatlab_feature.dart
git commit -m "feat: add premium gating for recording layers"
```

---

### Task 13: Add Export Mix-Down

**Files:**
- Modify: `lib/features/song/cubit/song_exporter/song_exporter_cubit.dart`

**Step 1: Add exportMix method to SongExporterCubit**

Add a new method to `SongExporterCubit` in `lib/features/song/cubit/song_exporter/song_exporter_cubit.dart`:

```dart
  /// Export the original song mixed with all recording layers.
  Future<void> exportMix({
    required Song song,
    required List<RecordingLayer> layers,
    required AudioExportFormat format,
    required int sampleRateHz,
  }) async {
    if (layers.isEmpty) return;

    emit(
      state.copyWith(
        status: SongExporterStatus.exporting,
        errorMessage: null,
        exportedFilePath: null,
        format: format,
        pendingBytes: null,
        suggestedFileName: null,
      ),
    );

    File? tempFile;

    try {
      final inputPath = await song.path;
      final outputFileName =
          '${_sanitizeFileName(song.title)}-mix-${sampleRateHz}Hz.${format.fileExtension}';
      final tempDirectory = await getTemporaryDirectory();
      final tempPath = p.join(tempDirectory.path, outputFileName);
      tempFile = File(tempPath);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // Build FFmpeg command with amix filter for all layers
      final command = _buildMixCommand(
        inputPath: inputPath,
        layerPaths: layers.map((l) => l.filePath).toList(),
        layerOffsets: layers.map((l) => l.startPosition).toList(),
        layerVolumes: layers.map((l) => l.isMuted ? 0.0 : l.volume).toList(),
        outputPath: tempPath,
        format: format,
        sampleRateHz: sampleRateHz,
      );

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final bytes = await tempFile.readAsBytes();
        await _deleteLocalFile(tempFile);

        emit(
          state.copyWith(
            status: SongExporterStatus.awaitingSave,
            pendingBytes: bytes,
            suggestedFileName: outputFileName,
          ),
        );
      } else {
        await _deleteLocalFile(tempFile);
        final logs = await session.getOutput();
        final error = 'FFmpeg mix failed with code ${returnCode?.getValue() ?? 'unknown'}';
        unawaited(
          crashReportingRepository.reportError(Exception(error), StackTrace.current),
        );
        emit(
          state.copyWith(
            status: SongExporterStatus.exportError,
            errorMessage: logs?.isNotEmpty == true ? '$error\n$logs' : error,
            pendingBytes: null,
            suggestedFileName: null,
          ),
        );
      }
    } catch (ex, stackTrace) {
      if (tempFile != null) {
        await _deleteLocalFile(tempFile);
      }
      unawaited(crashReportingRepository.reportError(ex, stackTrace));
      emit(
        state.copyWith(
          status: SongExporterStatus.exportError,
          errorMessage: ex.toString(),
          pendingBytes: null,
          suggestedFileName: null,
        ),
      );
    }
  }

  String _buildMixCommand({
    required String inputPath,
    required List<String> layerPaths,
    required List<Duration> layerOffsets,
    required List<double> layerVolumes,
    required String outputPath,
    required AudioExportFormat format,
    required int sampleRateHz,
  }) {
    // Build input arguments: original track + each layer
    final inputs = StringBuffer('-i "$inputPath"');
    for (final path in layerPaths) {
      inputs.write(' -i "$path"');
    }

    // Build filter_complex: delay each layer and set volumes
    final totalInputs = 1 + layerPaths.length;
    final filters = StringBuffer();

    for (var i = 0; i < layerPaths.length; i++) {
      final delayMs = layerOffsets[i].inMilliseconds;
      final vol = layerVolumes[i];
      filters.write('[${i + 1}]adelay=$delayMs|$delayMs,volume=$vol[a${i + 1}];');
    }

    // Amix all streams together
    filters.write('[0]');
    for (var i = 0; i < layerPaths.length; i++) {
      filters.write('[a${i + 1}]');
    }
    filters.write('amix=inputs=$totalInputs:duration=longest');

    final codecArgs = format.ffmpegCodecArgs();
    return '${inputs.toString()} -filter_complex "${filters.toString()}" -ar $sampleRateHz $codecArgs -y "$outputPath"';
  }
```

Add the RecordingLayer import:

```dart
import 'package:repeatlab/data/models/recording_layer.dart';
```

**Step 2: Verify build compiles**

Run: `flutter analyze`
Expected: No errors

**Step 3: Commit**

```bash
git add lib/features/song/cubit/song_exporter/song_exporter_cubit.dart
git commit -m "feat: add FFmpeg mix-down export for recording layers"
```

---

### Task 14: Clean Up Song Deletion

**Files:**
- Modify: `lib/features/song/cubit/song/song_cubit.dart`

**Step 1: Add recording cleanup to song deletion**

Modify `SongCubit` to accept `RecordingRepository` and clean up recordings when a song is deleted.

Add to the constructor parameters:

```dart
  final RecordingRepository? recordingRepository2;
```

(Named `recordingRepository2` to avoid conflict with `songRepository` naming. Or rename to `recordingRepo`.)

Actually, the cleaner approach: make `SongPage` handle cleanup via the `RecordingCubit`. In `_SongViewState._onTapDeleteSong`, before calling `context.read<SongCubit>().deleteSong()`, add:

```dart
      // Clean up recording layers
      final recordingRepository = context.read<RecordingRepository>();
      await recordingRepository.deleteAllLayersForSong(widget.song.id);
```

This requires adding the import to `song_page.dart` (already added in Task 6).

**Step 2: Verify build compiles**

Run: `flutter analyze`
Expected: No errors

**Step 3: Run all tests**

Run: `flutter test`
Expected: All tests pass

**Step 4: Commit**

```bash
git add lib/features/song/view/song_page.dart
git commit -m "feat: clean up recording files when song is deleted"
```

---

### Task 15: Manual Testing Checklist

**No files to modify — manual testing only.**

Test on a real device (recording requires real microphone):

**Step 1: Basic recording flow**
- Open a song
- Create a loop (e.g., 15 seconds)
- Tap record button
- Verify 3-2-1 countdown appears
- Verify playback starts at loop start after countdown
- Verify recording stops at loop end
- Verify recording appears in layers panel

**Step 2: Layer playback**
- Play the song with a recording layer
- Verify you hear both the backing track and recording
- Toggle mute on the layer — verify it goes silent
- Adjust volume slider — verify volume changes
- Delete the layer — verify it's removed

**Step 3: Premium gating**
- With a free account, add one recording
- Try to add a second recording
- Verify paywall is presented

**Step 4: Free recording (no loop)**
- Deactivate loop mode
- Tap record
- Verify recording starts from current position
- Tap stop — verify recording stops and saves

**Step 5: Recording indicator**
- Start recording
- Verify red border appears on waveform
- Stop recording — verify border disappears

**Step 6: Song deletion**
- Add a recording to a song
- Delete the song
- Verify recording files are cleaned up from disk

**Step 7: Export mix (if implemented)**
- Add a recording layer
- Export mix
- Verify exported file contains both original and recording
