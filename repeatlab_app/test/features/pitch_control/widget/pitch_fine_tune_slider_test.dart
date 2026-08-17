import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/pitch_control/widget/pitch_fine_tune_slider.dart';
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
      () => mockSongCubit.setFineTuneCents(any()),
    ).thenAnswer((_) async => true);
    when(
      () => mockPremiumSubscriptionCubit.presentPaywall(
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpSlider(
    WidgetTester tester, {
    required int fineTuneCents,
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
          body: PitchFineTuneSlider(fineTuneCents: fineTuneCents),
        ),
      ),
      locale: const Locale('en'),
    );
  }

  group('PitchFineTuneSlider', () {
    testWidgets('idle reads 0 ct', (tester) async {
      await pumpSlider(tester, fineTuneCents: 0);

      expect(find.text('Fine tune'), findsOneWidget);
      expect(find.text('0 ct'), findsOneWidget);
    });

    testWidgets('engaged reads the signed cent value', (tester) async {
      await pumpSlider(tester, fineTuneCents: 18);

      expect(find.text('+18 ct'), findsOneWidget);
    });

    testWidgets('negative cents use a real minus sign', (tester) async {
      await pumpSlider(tester, fineTuneCents: -25);

      expect(find.text('−25 ct'), findsOneWidget);
    });

    testWidgets('the slider spans the full cent range', (tester) async {
      await pumpSlider(tester, fineTuneCents: 0);

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, SongCubit.minFineTuneCents.toDouble());
      expect(slider.max, SongCubit.maxFineTuneCents.toDouble());
      // One division per cent, so every value is reachable.
      expect(slider.divisions, 100);
      expect(find.text('−50'), findsOneWidget);
      expect(find.text('+50'), findsOneWidget);
    });

    testWidgets('dragging commits once, on release', (tester) async {
      await pumpSlider(tester, fineTuneCents: 0);

      await tester.drag(find.byType(Slider), const Offset(40, 0));
      await tester.pump();

      // onChanged must not write through — only onChangeEnd commits, so a
      // drag is one native call and one persist rather than dozens.
      verify(() => mockSongCubit.setFineTuneCents(any())).called(1);
    });

    testWidgets('a free user cannot move the slider', (tester) async {
      await pumpSlider(tester, fineTuneCents: 0, hasPremium: false);

      // Rendered at its true value rather than greyed out, so a free user can
      // see what they would be buying.
      expect(find.byType(Slider), findsOneWidget);

      // warnIfMissed: the AbsorbPointer swallowing this drag is the point.
      await tester.drag(
        find.byType(Slider),
        const Offset(40, 0),
        warnIfMissed: false,
      );
      await tester.pump();

      // The touch opens the paywall instead of changing the pitch.
      verifyNever(() => mockSongCubit.setFineTuneCents(any()));
      verify(
        () => mockPremiumSubscriptionCubit.presentPaywall(
          source: any(named: 'source'),
        ),
      ).called(1);
    });
  });
}
