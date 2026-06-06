import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:repeatlab/data/repositories/backup/backup_repository.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/file_repository.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/data/repositories/purchases_repository.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:sembast/sembast.dart';

class RepositoryWrapper extends StatelessWidget {
  final Widget child;
  final Database db;
  final SoLoud soLoud;
  final PackageInfo packageInfo;
  final LocalConfigRepository localConfigRepository;
  // final AudioPlayer audioPlayer;

  const RepositoryWrapper({
    required this.db,
    required this.child,
    required this.soLoud,
    required this.packageInfo,
    required this.localConfigRepository,
    // required this.audioPlayer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => FileRepository(
            filePicker: FilePickerWrapper(),
          ),
        ),
        RepositoryProvider(
          create: (context) => SongRepository(
            db: db,
            soLoud: soLoud,
          )..getAllSongs(),
        ),
        RepositoryProvider(
          create: (context) => packageInfo,
        ),

        RepositoryProvider(
          create: (context) => const CrashReportingRepository(),
        ),
        RepositoryProvider(
          create: (context) => const PurchasesRepository(),
        ),
        RepositoryProvider.value(value: localConfigRepository),
        RepositoryProvider(
          create: (context) => BackupRepository(
            db: db,
            songRepository: context.read<SongRepository>(),
            packageInfo: packageInfo,
          ),
        ),
        // RepositoryProvider(
        //   create: (context) => audioPlayer,
        // ),
      ],
      child: child,
    );
  }
}

class FilePickerWrapper {
  Future<FilePickerResult?> pickFiles({
    required FileType type,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    return await FilePicker.pickFiles(
      type: type,
      allowedExtensions: allowedExtensions,
      allowMultiple: allowMultiple,
    );
  }

  Future<String?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required FileType type,
    List<String>? allowedExtensions,
  }) async {
    return await FilePicker.saveFile(
      fileName: fileName,
    );
  }
}
