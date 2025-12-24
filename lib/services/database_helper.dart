import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'chat_app_cache.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE image_cache (
        url TEXT PRIMARY KEY,
        local_path TEXT,
        timestamp INTEGER
      )
    ''');
  }

  Future<void> insertImage(String url, String localPath) async {
    final db = await database;
    await db.insert('image_cache', {
      'url': url,
      'local_path': localPath,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getLocalPath(String url) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'image_cache',
      where: 'url = ?',
      whereArgs: [url],
    );

    if (maps.isNotEmpty) {
      return maps.first['local_path'] as String;
    }
    return null;
  }
}
