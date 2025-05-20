import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:repeatlab/features/home/cubit/all_songs_cubit.dart';
import 'package:repeatlab/l10n/arb/app_localizations.dart';

class MockSongRepository extends Mock implements SongRepository {
  @override
  Stream<List<Song>> get songs => Stream.value([]);
}

class MockAllSongsCubit extends MockCubit<AllSongsState> implements AllSongsCubit {
  @override
  final SongRepository songRepository;

  MockAllSongsCubit({
    required this.songRepository,
  });
}

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget,
  ) {
    final mockSongRepository = MockSongRepository();
    final allSongsCubit = MockAllSongsCubit(songRepository: mockSongRepository);

    when(() => mockSongRepository.getAllSongs()).thenAnswer(
      (_) => Future.value([]),
    );
    when(() => allSongsCubit.state).thenReturn(
      const AllSongsState(),
    );

    when(() => allSongsCubit.loadSongs()).thenAnswer(
      (_) => Future.value(),
    );

    return pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: allSongsCubit),
        ],
        child: Builder(
          builder: (context) {
            return MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: widget,
            );
          },
        ),
      ),
    );
  }
}

/*import 'package:audioplayers/audioplayers.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:drumbitious/core/cubit/audio_player/audio_player_cubit.dart';
import 'package:drumbitious/core/cubit/firebase_auth/firebase_auth_cubit.dart';
import 'package:drumbitious/core/cubit/premium_subscription/premium_subscription_cubit.dart';
import 'package:drumbitious/core/ui/app_themes.dart';
import 'package:drumbitious/data/repositories/repositories.dart';
import 'package:drumbitious/l10n/l10n.dart';
import 'package:drumbitious/screens/changelog_dialog/cubits/changelog_dialog_cubit.dart';
import 'package:drumbitious/screens/dashboard/cubit/dashboard/dashboard_cubit.dart';
import 'package:drumbitious/screens/exercise_statistics/cubits/exercise_statistics_cubit.dart';
import 'package:drumbitious/screens/intro/cubit/intro_cubit.dart';
import 'package:drumbitious/screens/login/cubit/login_cubit.dart';
import 'package:drumbitious/screens/rate_app_dialog/cubit/rate_app_cubit.dart';
import 'package:drumbitious/screens/session/cubit/session/session_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_repositories.dart';

class MockChangelogDialogCubit extends MockCubit<ChangelogDialogState>
    implements ChangelogDialogCubit {}

class MockAudioPlayerCubit extends MockCubit<AudioPlayerState>
    implements AudioPlayerCubit {}


extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    ChangelogDialogCubit? changelogDialogCubit,
    AudioPlayerCubit? audioPlayerCubit,
    AudioPlayer? audioPlayer,
    PremiumSubscriptionCubit? premiumSubscriptionCubit,
    RateAppCubit? rateAppCubit,
    DashboardCubit? dashboardCubit,
    SessionCubit? sessionCubit,
    FirebaseAuthCubit? firebaseAuthCubit,
    IntroCubit? introCubit,
    LocalConfigRepository? localConfigRepository,
    AuthRepository? authRepository,
  }) {
    final mockChangelogDialogCubit =
        changelogDialogCubit ?? MockChangelogDialogCubit();
    final mockAudioPlayerCubit = audioPlayerCubit ?? MockAudioPlayerCubit();
    // final mockAudioPlayer = audioPlayer ?? MockAudioPlayer();
    final mockPremiumSubscriptionCubit =
        premiumSubscriptionCubit ?? MockPremiumSubscriptionCubit();
    final mockRateAppCubit = rateAppCubit ?? MockRateAppCubit();
    final mockDashboardCubit = dashboardCubit ?? MockDashboardCubit();
    final mockSessionCubit = sessionCubit ?? MockSessionCubit();
    final mockFirebaseAuthCubit = firebaseAuthCubit ?? MockFirebaseAuthCubit();
    final mockIntroCubit = introCubit ?? MockIntroCubit();

    final mockLocalConfigRepository =
        localConfigRepository ?? MockLocalConfigRepository();

    final mockAuthRepository = authRepository ?? MockAuthRepository();

    when(() => mockChangelogDialogCubit.checkChangelogDialog()).thenAnswer(
      (_) => Future.value(),
    );

    when(() => mockAudioPlayerCubit.state).thenReturn(
      const AudioPlayerState(),
    );

    when(() => mockChangelogDialogCubit.state).thenReturn(
      const ChangelogDialogState(
        status: ChangelogStatus.loaded,
      ),
    );

    when(() => mockAudioPlayerCubit.state).thenReturn(
      const AudioPlayerState(),
    );

    when(() => mockAudioPlayerCubit.stop()).thenAnswer(
      (_) => Future.value(),
    );

    when(() => mockChangelogDialogCubit.state).thenReturn(
      const ChangelogDialogState(
        status: ChangelogStatus.loaded,
      ),
    );

    when(() => mockPremiumSubscriptionCubit.state).thenReturn(
      const PremiumSubscriptionState(),
    );

    when(() => mockRateAppCubit.state).thenReturn(
      const RateAppState(),
    );

    when(() => mockDashboardCubit.state).thenReturn(
      const DashboardState(),
    );

    when(() => mockDashboardCubit.fetchPlans()).thenAnswer(
      (_) => Future.value(),
    );

    when(() => mockSessionCubit.state).thenReturn(
      const SessionState(),
    );

    when(() => mockFirebaseAuthCubit.state).thenReturn(
      const FirebaseAuthState(),
    );

    when(() => mockIntroCubit.state).thenReturn(IntroState.shown);

    return pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: mockLocalConfigRepository),
          RepositoryProvider.value(value: mockAuthRepository),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<ChangelogDialogCubit>.value(
              value: mockChangelogDialogCubit,
            ),
            BlocProvider<AudioPlayerCubit>.value(value: mockAudioPlayerCubit),
            BlocProvider.value(value: mockPremiumSubscriptionCubit),
            BlocProvider.value(value: mockRateAppCubit),
            BlocProvider.value(value: mockDashboardCubit),
            BlocProvider.value(value: mockSessionCubit),
            BlocProvider.value(value: mockFirebaseAuthCubit),
            BlocProvider.value(value: mockIntroCubit),
          ],
          child: MaterialApp(
            /* builder: (context, child) {
              final data = MediaQuery.of(context);

              return MediaQuery(
                data: data.copyWith(
                  textScaler: const TextScaler.linear(2.9),
                ),
                child: child!,
              );
            }, */
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('de'),
              Locale('es'),
            ],
            theme: AppThemes.darkTheme,
            home: widget,
          ),
        ),
      ),
    );
  }
}*/
