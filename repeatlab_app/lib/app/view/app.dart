import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:repeatlab/app/router.dart';
import 'package:repeatlab/app/view/repository_wrapper.dart';
import 'package:repeatlab/core/ui/theme.dart';
import 'package:repeatlab/core/ui/util.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/file_repository.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/data/repositories/purchases_repository.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:repeatlab/features/changelog_dialog/cubits/changelog_dialog_cubit.dart';
import 'package:repeatlab/features/home/cubit/all_songs_cubit.dart';
import 'package:repeatlab/features/home/home_page.dart';
import 'package:repeatlab/features/onboarding/view/onboarding_page.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/l10n/arb/app_localizations.dart';
import 'package:sembast/sembast.dart';
import 'package:wiredash/wiredash.dart';

class App extends StatelessWidget {
  final Database db;
  final SoLoud soloud;
  final PackageInfo packageInfo;
  final LocalConfigRepository localConfigRepository;
  // final AudioPlayer audioPlayer;

  const App({
    required this.db,
    required this.soloud,
    required this.packageInfo,
    required this.localConfigRepository,
    // required this.audioPlayer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Simply use the font family names directly since they're declared in pubspec.yaml
    final baseTextTheme = Theme.of(context).textTheme;
    final textTheme = createTextTheme(baseTextTheme, "Nunito Sans", "Oswald");
    final theme = MaterialTheme(textTheme);

    return RepositoryWrapper(
      db: db,
      soLoud: soloud,
      packageInfo: packageInfo,
      localConfigRepository: localConfigRepository,
      // audioPlayer: audioPlayer,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AllSongsCubit(
              songRepository: context.read<SongRepository>(),
              fileRepository: context.read<FileRepository>(),
              crashReportingRepository: context.read<CrashReportingRepository>(),
            )..loadSongs(),
          ),
          BlocProvider(
            lazy: false,
            create: (context) => PremiumSubscriptionCubit(
              purchasesRepository: context.read<PurchasesRepository>(),
              crashReportingRepository: context.read<CrashReportingRepository>(),
            )..init(),
          ),
          BlocProvider(
            lazy: false,
            create: (context) => ChangelogDialogCubit(
              localConfigRepository: context.read<LocalConfigRepository>(),
              packageInfo: context.read<PackageInfo>(),
            ),
          ),
        ],
        child: Wiredash(
          projectId: 'repeatlab-vvi4662',
          secret: '31TK1lGlcgAPuF4bp1fc3SlhLgtfJVop',
          child: Builder(
            builder: (context) {
              final introShown = context.watch<LocalConfigRepository>().introShown;

              return MaterialApp(
                debugShowCheckedModeBanner: false,
                themeMode: ThemeMode.dark,
                theme: theme.dark(),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                onGenerateRoute: AppRouter.generateRoute,
                home: introShown ? const HomePage() : const OnboardingPage(),
              );
            },
          ),
        ),
      ),
    );
  }
}
