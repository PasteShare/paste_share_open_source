import 'dart:convert';

import 'package:sqflite/sqflite.dart';

class ConnectedDevice {
  final int id;
  final String? deviceId;
  final String? ip;
  final String? name;
  final Map? json;
  final String? createdAt;
  final String? lastOnlineAt;
  final bool isOnline;

  ConnectedDevice({this.id = 0, this.json, this.name, this.deviceId, this.ip, this.lastOnlineAt, this.createdAt, this.isOnline = false});

  ConnectedDevice copyWith({final int? id, final String? deviceId, final String? ip, final String? name, final Map? json, final String? createdAt, final String? lastOnlineAt, final bool? isOnline}) {
    return ConnectedDevice(id: id ?? this.id, json: json ?? this.json, name: name ?? this.name, deviceId: deviceId ?? this.deviceId, ip: ip ?? this.ip, lastOnlineAt: lastOnlineAt ?? this.lastOnlineAt, createdAt: createdAt ?? this.createdAt, isOnline: isOnline ?? this.isOnline);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'json': json,
      "name": name,
      "deviceId": deviceId,
      "ip": ip,
      "createdAt": createdAt,
      "lastOnlineAt": lastOnlineAt,
      "isOnline": isOnline,
    };
  }

  ConnectedDevice.fromMap(Map json)
      : id = json['id'],
        deviceId = json['deviceId'],
        ip = json['ip'],
        name = json['name'],
        json = json['json'] is Map ? json['json'] : jsonDecode(json['json']),
        createdAt = json['createdAt'],
        lastOnlineAt = json['lastOnlineAt'],
        isOnline = json['isOnline'] ?? false;
}

class DbConnectedDevice {
  Database? _database;
  static DbConnectedDevice? _instance;
  static final String tableName = "connected_device";
  //  ON UPDATE CURRENT_TIMESTAMP
  String get createdSQL => "CREATE TABLE IF NOT EXISTS $tableName (id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(255), deviceId VARCHAR(255) UNIQUE NOT NULL, ip VARCHAR(128) NOT NULL, json TEXT NOT NULL,lastOnlineAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP, createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP)";

  factory DbConnectedDevice(_database) {
    if (_instance == null) {
      _instance = DbConnectedDevice._(_database);
    }
    return _instance!;
  }

  DbConnectedDevice._(_database) {
    this._database = _database;
  }

  Future<ConnectedDevice?> get(int id) async {
    final list = await _database!.query(tableName, limit: 1, where: "id=?", whereArgs: [id]);
    if (list.length > 0) {
      return ConnectedDevice.fromMap({...list[0], "json": jsonDecode(list[0]["json"] as String)});
    }
    return null;
  }

  Future<int> insert({String ip = "", String? name = "", Map? json = const {}, String? deviceId = ""}) {
    return _database!.insert(tableName, {"ip": ip, "json": jsonEncode(json), "deviceId": deviceId, "name": name});
  }

  // A method that retrieves all the dogs from the dogs table.
  Future<List<ConnectedDevice>> list() async {
    // Query the table for all The Dogs.
    final List<Map<String, dynamic>> maps = await _database!.query(tableName, orderBy: "id desc");

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    return List.generate(maps.length, (i) {
      return ConnectedDevice.fromMap(maps[i]);
    });
  }

  Future<void> update(ConnectedDevice data) async {
    await _database!.update(
      tableName,
      data.toMap()
        ..remove("isOnline")
        ..["json"] = jsonEncode(data.json)
        ..remove("id")
        ..["lastOnlineAt"] = DateTime.now().toUtc().toString().replaceFirst(" ", "T"),
      where: "id = ?",
      whereArgs: [data.id],
    );
  }

  Future<void> delete(int id) async {
    // Remove the Dog from the Database.
    await _database!.delete(
      tableName,
      // Use a `where` clause to delete a specific dog.
      where: "id = ?",
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

  Future<void> clear() async {
    // Remove the Dog from the Database.
    await _database!.delete(
      tableName,
      // Use a `where` clause to delete a specific dog.
      where: "1",
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: null,
    );
  }
}
