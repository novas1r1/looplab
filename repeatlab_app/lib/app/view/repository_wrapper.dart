import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/file_repository.dart';
import 'package:repeatlab/data/repositories/paywall_service.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RepositoryWrapper extends StatelessWidget {
  final Widget child;
  final Database db;
  final SoLoud soLoud;
  final PackageInfo packageInfo;
  final SharedPreferences sharedPreferences;

  const RepositoryWrapper({
    required this.db,
    required this.child,
    required this.soLoud,
    required this.packageInfo,
    required this.sharedPreferences,
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
          create: (context) => SongRepository(
            db: db,
            soLoud: soLoud,
          )..getAllSongs(),
        ),
        RepositoryProvider(
          create: (context) => packageInfo,
        ),
        RepositoryProvider(
          create: (context) => sharedPreferences,
        ),
        RepositoryProvider(
          create: (context) => const CrashReportingRepository(),
        ),
        RepositoryProvider(
          create: (context) => const PaywallRepository(),
        ),
      ],
      child: child,
    );
  }
}
