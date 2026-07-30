import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/features/pitch_control/widget/edit_song_key_dialog.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';

import '../../../helpers/mock_cubits.dart';
import '../../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSongCubit mockSongCubit;

  const testSong = Song(
    id: '1',
    title: 'Test Song',
    artist: 'Test Artist',
    fileName: 'test.mp3',
    duration: Duration(minutes: 3, seconds: 30),
    musicalKey: 'Am',
  );

  setUp(() {
    mockSongCubit = MockSongCubit();
    when(() => mockSongCubit.state).thenReturn(
      const SongState(song: testSong),
    );
    when(() => mockSongCubit.setOriginalKey(any())).thenAnswer((_) async {});
  });

  Future<void> pumpDialog(WidgetTester tester) async {
    await tester.pumpApp(
      BlocProvider<SongCubit>.value(
        value: mockSongCubit,
        child: const Scaffold(
          body: EditSongKeyDialog(currentOriginalKey: 'Am'),
        ),
      ),
      locale: const Locale('en'),
    );
    await tester.pumpAndSettle();
  }

  group('EditSongKeyDialog', () {
    testWidgets('lays out without overflowing or losing its size', (
      tester,
    ) async {
      await pumpDialog(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Cm'), findsOneWidget);
    });

    testWidgets('opens on the mode of the current key', (tester) async {
      await pumpDialog(tester);

      // Am is minor, so the minor grid must be showing.
      expect(find.text('C♯m'), findsOneWidget);
      expect(find.text('D♭'), findsNothing);
    });

    testWidgets('saving writes the picked key', (tester) async {
      await pumpDialog(tester);

      await tester.tap(find.byKey(const Key('song.pitch.key.Cm')));
      await tester.pump();
      await tester.tap(find.text('Set song key'));
      await tester.pump();

      verify(() => mockSongCubit.setOriginalKey('Cm')).called(1);
    });

    testWidgets('reset clears the key', (tester) async {
      await pumpDialog(tester);

      await tester.tap(find.byKey(const Key('song.pitch.keyClear')));
      await tester.pump();

      verify(() => mockSongCubit.setOriginalKey(null)).called(1);
    });
  });
}
