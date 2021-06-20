import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart'; // as sqfliteMobile;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

import 'clip_data.dart';
import 'device.dart';

export 'device.dart';
export 'clip_data.dart';

class DbUtils {
  Database? _database;
  static DbUtils? _instance;
  final String databaseName = "database.db";
  final _currentVersion = 1;
  late DbClipData clipData;
  late DbConnectedDevice connectedDevice;

  factory DbUtils() {
    if (_instance == null) {
      _instance = DbUtils._();
    }
    return _instance!;
  }

  DbUtils._();

  init() async {
    if (kIsWeb) {
      return;
    }
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _database = await databaseFactory.openDatabase(
      join(await getDatabasesPath(), databaseName),
      options: OpenDatabaseOptions(
        version: _currentVersion,
        onCreate: (db, version) async {
          _onCreate(db);
        },
      ),
    );
    clipData = DbClipData(_database);
    connectedDevice = DbConnectedDevice(_database);
  }

  _onCreate(db) async {
    // Run the CREATE TABLE statement on the database.
    await db.execute(
      DbClipData(db).createdSQL,
    );
    await db.execute(
      DbConnectedDevice(db).createdSQL,
    );
  }

  Future<void> clear() async {
    // Remove the Dog from the Database.
    await _database!.delete(
      DbClipData.tableName,
      // Use a `where` clause to delete a specific dog.
      where: "1",
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: null,
    );
    await _database!.delete(
      DbConnectedDevice.tableName,
      // Use a `where` clause to delete a specific dog.
      where: "1",
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: null,
    );
  }
}
