import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:looplab/app/view/repository_wrapper.dart';
import 'package:looplab/data/repositories/song_repository.dart';
import 'package:looplab/home/cubit/all_songs_cubit.dart';
import 'package:looplab/home/home_page.dart';
import 'package:looplab/l10n/l10n.dart';
import 'package:sembast/sembast.dart';

class App extends StatelessWidget {
  final Database db;
  final SoLoud soloud;

  const App({required this.db, required this.soloud, super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryWrapper(
      db: db,
      soLoud: soloud,
      child: BlocProvider(
        create: (context) => AllSongsCubit(
          songRepository: context.read<SongRepository>(),
        )..loadSongs(),
        child: MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomePage(),
        ),
      ),
    );
  }
}
