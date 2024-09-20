import 'package:flutter/material.dart';
import 'package:looplab/app/app.dart';
import 'package:looplab/bootstrap.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
// make sure it exists
  await dir.create(recursive: true);
// build the database path
  final dbPath = join(dir.path, 'my_database_dev.db');
// open the database
  final db = await databaseFactoryIo.openDatabase(dbPath);

  await bootstrap(() => App(db: db));
}
