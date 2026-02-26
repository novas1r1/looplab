import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
      ).thenAnswer(
          (_) async => [MockData.recordingLayer1, MockData.recordingLayer2]);
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
