import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:looplab/data/repositories/file_repository.dart';
import 'package:looplab/data/repositories/song_repository.dart';
import 'package:sembast/sembast.dart';

class RepositoryWrapper extends StatelessWidget {
  final Widget child;
  final Database db;
  final SoLoud soLoud;

  const RepositoryWrapper({
    required this.db,
    required this.child,
    required this.soLoud,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => FileRepository(
            filePicker: FilePicker.platform,
          ),
        ),
        RepositoryProvider(
          create: (context) =>
              SongRepository(db: db, soLoud: soLoud)..getAllSongs(),
        ),
      ],
      child: child,
    );
  }
}
