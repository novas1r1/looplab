import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/data/repositories/backup/backup_repository.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/file_repository.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/data/repositories/purchases_repository.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';

class MockLocalConfigRepository extends Mock implements LocalConfigRepository {}

class MockSongRepository extends Mock implements SongRepository {}

class MockCrashReportingRepository extends Mock
    implements CrashReportingRepository {}

class MockFileRepository extends Mock implements FileRepository {}

class MockPurchasesRepository extends Mock implements PurchasesRepository {}

class MockBackupRepository extends Mock implements BackupRepository {}
