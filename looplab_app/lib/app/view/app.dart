import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:looplab/app/view/repository_wrapper.dart';
import 'package:looplab/core/ui/theme.dart';
import 'package:looplab/core/ui/util.dart';
import 'package:looplab/data/repositories/song_repository.dart';
import 'package:looplab/home/cubit/all_songs_cubit.dart';
import 'package:looplab/home/home_page.dart';
import 'package:looplab/l10n/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sembast/sembast.dart';

class App extends StatelessWidget {
  final Database db;
  final SoLoud soloud;
  final PackageInfo packageInfo;

  const App({
    required this.db,
    required this.soloud,
    required this.packageInfo,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // final brightness = View.of(context).platformDispatcher.platformBrightness;

    // Use with Google Fonts package to use downloadable fonts
    final TextTheme textTheme =
        createTextTheme(context, "Nunito Sans", "Oswald");
    final MaterialTheme theme = MaterialTheme(textTheme);

    return RepositoryWrapper(
      db: db,
      soLoud: soloud,
      packageInfo: packageInfo,
      child: BlocProvider(
        create: (context) => AllSongsCubit(
          songRepository: context.read<SongRepository>(),
        )..loadSongs(),
        child: MaterialApp(
          theme: theme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomePage(),
        ),
      ),
    );
  }
}
