import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:looplab/data/repositories/file_repository.dart';
import 'package:looplab/data/repositories/song_repository.dart';
import 'package:sembast/sembast.dart';

class RepositoryWrapper extends StatelessWidget {
  const RepositoryWrapper({
    required this.db,
    required this.child,
    super.key,
  });
  final Widget child;
  final Database db;

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
          create: (context) => SongRepository(db: db)..getAllSongs(),
        ),
      ],
      child: child,
    );
  }
}
