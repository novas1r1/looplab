import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:looplab/app/view/repository_wrapper.dart';
import 'package:looplab/data/repositories/song_repository.dart';
import 'package:looplab/home/cubit/songs_cubit.dart';
import 'package:looplab/home/home_page.dart';
import 'package:looplab/l10n/l10n.dart';
import 'package:sembast/sembast.dart';

class App extends StatelessWidget {
  final Database db;

  const App({required this.db, super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryWrapper(
      db: db,
      child: BlocProvider(
        create: (context) => SongsCubit(
          songRepository: context.read<SongRepository>(),
        ),
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
