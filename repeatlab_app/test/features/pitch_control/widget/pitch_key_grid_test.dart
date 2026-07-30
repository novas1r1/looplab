import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/pitch_control/widget/key_grid.dart';
import 'package:repeatlab/features/pitch_control/widget/pitch_key_grid.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';

import '../../../helpers/mock_cubits.dart';
import '../../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSongCubit mockSongCubit;
  late MockPremiumSubscriptionCubit mockPremiumSubscriptionCubit;

  const testSong = Song(
    id: '1',
    title: 'Test Song',
    artist: 'Test Artist',
    fileName: 'test.mp3',
    duration: Duration(minutes: 3, seconds: 30),
  );

  setUp(() {
    mockSongCubit = MockSongCubit();
    mockPremiumSubscriptionCubit = MockPremiumSubscriptionCubit();

    when(() => mockPremiumSubscriptionCubit.state).thenReturn(
      const PremiumSubscriptionState(),
    );
    when(() => mockSongCubit.state).thenReturn(
      const SongState(song: testSong),
    );
    when(
      () => mockSongCubit.setPitchByTargetKey(any()),
    ).thenAnswer((_) async => true);
    when(
      () => mockPremiumSubscriptionCubit.presentPaywall(
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpGrid(
    WidgetTester tester, {
    required String originalKey,
    int pitchSemitones = 0,
    bool hasPremium = true,
  }) async {
    when(() => mockPremiumSubscriptionCubit.hasPremium).thenReturn(hasPremium);

    await tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<PremiumSubscriptionCubit>.value(
            value: mockPremiumSubscriptionCubit,
          ),
          BlocProvider<SongCubit>.value(value: mockSongCubit),
        ],
        child: Scaffold(
          body: PitchKeyGrid(
            originalKey: originalKey,
            pitchSemitones: pitchSemitones,
          ),
        ),
      ),
      locale: const Locale('en'),
    );
  }

  group('PitchKeyGrid', () {
    testWidgets('shows the 12 major keys as musicians spell them', (
      tester,
    ) async {
      await pumpGrid(tester, originalKey: 'C');

      for (final label in [
        'C',
        'D♭',
        'D',
        'E♭',
        'E',
        'F',
        'F♯',
        'G',
        'A♭',
        'A',
        'B♭',
        'B',
      ]) {
        expect(find.text(label), findsOneWidget, reason: 'missing $label');
      }
      // Never the unwritable spellings a sharps-only helper would produce.
      expect(find.text('D♯'), findsNothing);
      expect(find.text('A♯'), findsNothing);
    });

    testWidgets('shows the 12 minor keys, which spell differently', (
      tester,
    ) async {
      await pumpGrid(tester, originalKey: 'Am');

      // Minor prefers C♯m and G♯m where major prefers D♭ and A♭.
      expect(find.text('C♯m'), findsOneWidget);
      expect(find.text('G♯m'), findsOneWidget);
      expect(find.text('E♭m'), findsOneWidget);
      expect(find.text('B♭m'), findsOneWidget);
    });

    testWidgets('badges the song key "orig" and the rest with offsets', (
      tester,
    ) async {
      await pumpGrid(tester, originalKey: 'G');

      expect(find.text('orig'), findsOneWidget);
      // From G: C is a 4th up, D a 5th down, B♭ a minor 3rd up.
      expect(find.text('+5'), findsOneWidget);
      expect(find.text('−5'), findsOneWidget);
      expect(find.text('+3'), findsOneWidget);
    });

    testWidgets('colour-codes the original and current keys apart', (
      tester,
    ) async {
      // C is the song's key, D is where it is playing after +2.
      await pumpGrid(tester, originalKey: 'C', pitchSemitones: 2);

      Color cellColor(String key) => tester
          .widget<Material>(
            find
                .ancestor(
                  of: find.byKey(Key('song.pitch.key.$key')),
                  matching: find.byType(Material),
                )
                .first,
          )
          .color!;

      // Matches the tiles above the grid: secondary = recorded in,
      // primaryContainer = playing now, everything else neutral.
      expect(cellColor('C'), AppColors.secondary);
      expect(cellColor('D'), AppColors.primaryContainer);
      expect(cellColor('E'), AppColors.surfaceContainerLow);
    });

    testWidgets('an untransposed song shows one highlighted cell', (
      tester,
    ) async {
      await pumpGrid(tester, originalKey: 'C');

      final color = tester
          .widget<Material>(
            find
                .ancestor(
                  of: find.byKey(const Key('song.pitch.key.C')),
                  matching: find.byType(Material),
                )
                .first,
          )
          .color;

      // Original and current are the same key here; "playing now" wins so
      // there is never more than one primary cell.
      expect(color, AppColors.primaryContainer);
    });

    testWidgets('tapping a key transposes to it', (tester) async {
      await pumpGrid(tester, originalKey: 'C');

      await tester.tap(find.byKey(const Key('song.pitch.key.D#')));
      await tester.pump();

      verify(() => mockSongCubit.setPitchByTargetKey('D#')).called(1);
    });

    testWidgets('a legacy +6 tritone keeps its stored offset', (tester) async {
      // Songs saved before the tie-break flipped still hold +6. Deriving the
      // badge would claim −6 while playback actually sits a tritone up.
      await pumpGrid(tester, originalKey: 'C', pitchSemitones: 6);

      expect(find.text('+6'), findsOneWidget);
      expect(find.text('−6'), findsNothing);
    });

    testWidgets('a fresh tritone pick reads as −6', (tester) async {
      await pumpGrid(tester, originalKey: 'C', pitchSemitones: -6);

      expect(find.text('−6'), findsOneWidget);
      expect(find.text('+6'), findsNothing);
    });

    testWidgets('a free user gets the paywall instead of a transpose', (
      tester,
    ) async {
      await pumpGrid(tester, originalKey: 'C', hasPremium: false);

      // The grid still renders, so the trade-offs are visible before buying.
      expect(find.byType(KeyGrid), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('song.pitch.key.D')),
        warnIfMissed: false,
      );
      await tester.pump();

      verifyNever(() => mockSongCubit.setPitchByTargetKey(any()));
      verify(
        () => mockPremiumSubscriptionCubit.presentPaywall(
          source: any(named: 'source'),
        ),
      ).called(1);
    });
  });
}
