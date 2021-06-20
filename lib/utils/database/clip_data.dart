import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ClipData {
  final int id;
  final String text;
  final int? deviceId;
  final String? createdAt;
  final double progress;
  final Map <String, double> progressMap;

  ClipData({this.id = 0, this.text = "", this.deviceId, this.createdAt, this.progress = 0, this.progressMap = const {}});

  ClipData copyWith({final int? id, final String? text, final int? deviceId, final String? createdAt, final double progress = 0.0, final Map <String, double> progressMap = const {}}) {
    return ClipData(
      id: id ?? this.id,
      text: text ?? this.text,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      progress: progress,
        progressMap: progressMap,
    );
  }

  ClipData.fromMap(Map json)
      : id = json["id"] ?? 0,
        text = json["text"],
        deviceId = json["deviceId"],
        createdAt = json["createdAt"],
        progress = json["progress"] ?? 0.00,
        progressMap = json["progressMap"] ?? {};

  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'text': text,
      'deviceId': deviceId,
      'progress': progress,
    };
    if (createdAt != null) {
      map["createdAt"] = createdAt;
    }
    return map;
  }
}

class DbClipData {
  Database? _database;
  static DbClipData? _instance;
  static final String tableName = "clip_data";

  String get createdSQL => "CREATE TABLE IF NOT EXISTS $tableName(id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT, deviceId INTEGER, createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP)";

  factory DbClipData(_database) {
    if (_instance == null) {
      _instance = DbClipData._(_database);
    }
    return _instance!;
  }

  DbClipData._(_database) {
    this._database = _database;
  }

  Future<ClipData?> get(int id) async {
    final list = await _database!.query(tableName, limit: 1, where: "id=?", whereArgs: [id]);
    if (list.length > 0) {
      return ClipData.fromMap(list[0]);
    }
    return null;
  }

  Future<int> insertClipData(ClipData clipData) async {
    Map dataMap = clipData.toMap()..remove("id")..remove("progress");
    if (dataMap['createdAt'] == null) {
      dataMap.remove("createdAt");
    }
    final int result = await _database!.insert(tableName, dataMap as Map<String, Object?>);
    return result;
  }

  // A method that retrieves all the dogs from the dogs table.
  Future<List<ClipData>> clipDataList({fromDateTime}) async {
    String? where;
    List whereArgs = [];
    if (fromDateTime != null) {
      where = "createdAt > ?";
      whereArgs = [fromDateTime];
    }
    final List<Map<String, dynamic>> maps = await _database!.query(tableName, where: where, whereArgs: whereArgs, orderBy: "id desc");

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    return List.generate(maps.length, (i) {
      return ClipData.fromMap(maps[i]);
    });
  }

  Future<void> updateClipData(ClipData clipData) async {
    await _database!.update(
      tableName,
      clipData.toMap()..remove("id")..remove("progress"),
      where: "id = ?",
      whereArgs: [clipData.id],
    );
  }

  Future<void> deleteClipData(int id) async {
    // Remove the Dog from the Database.
    await _database!.delete(
      tableName,
      // Use a `where` clause to delete a specific dog.
      where: "id = ?",
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

  Future<int> deleteByClipData({String? text}) async {
    // Remove the Dog from the Database.
    return await _database!.delete(
      tableName,
      // Use a `where` clause to delete a specific dog.
      where: "text = ?",
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [text],
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
