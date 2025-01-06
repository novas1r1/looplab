import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:repeatlab/app/view/repository_wrapper.dart';
import 'package:repeatlab/core/ui/theme.dart';
import 'package:repeatlab/core/ui/util.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/file_repository.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:repeatlab/features/home/cubit/all_songs_cubit.dart';
import 'package:repeatlab/features/home/home_page.dart';
import 'package:repeatlab/l10n/l10n.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wiredash/wiredash.dart';

class App extends StatelessWidget {
  final Database db;
  final SoLoud soloud;
  final PackageInfo packageInfo;
  final SharedPreferences sharedPreferences;

  const App({
    required this.db,
    required this.soloud,
    required this.packageInfo,
    required this.sharedPreferences,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // final brightness = View.of(context).platformDispatcher.platformBrightness;
    // set to dark mode
    // Use with Google Fonts package to use downloadable fonts
    final textTheme = createTextTheme(context, "Nunito Sans", "Oswald");
    final theme = MaterialTheme(textTheme);

    return RepositoryWrapper(
      db: db,
      soLoud: soloud,
      packageInfo: packageInfo,
      sharedPreferences: sharedPreferences,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AllSongsCubit(
              songRepository: context.read<SongRepository>(),
              fileRepository: context.read<FileRepository>(),
              crashReportingRepository:
                  context.read<CrashReportingRepository>(),
            )..loadSongs(),
          ),
        ],
        child: Wiredash(
          projectId: 'repeatlab-vvi4662',
          secret: '31TK1lGlcgAPuF4bp1fc3SlhLgtfJVop',
          child: MaterialApp(
            theme: theme.dark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomePage(),
          ),
        ),
      ),
    );
  }
}
