import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance =
      DatabaseService._init();
  static Database? _database;

  final Map<String, List<Map<String, dynamic>>> _cache = {};

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vitals.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vitals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT,
        value REAL,
        timestamp INTEGER
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_type_time ON vitals(type, timestamp)',
    );
  }

  Future<void> insertBatch(
    List<Map<String, dynamic>> data,
  ) async {
    final db = await database;
    final batch = db.batch();

    for (var e in data) {
      batch.insert('vitals', e);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getVitals(
    String type,
  ) async {
    if (_cache.containsKey(type)) {
      return _cache[type]!;
    }

    final db = await database;

    final result = await db.query(
      'vitals',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'timestamp ASC',
    );

    _cache[type] = result;
    return result;
  }

  Future<void> deleteOldData() async {
    final db = await instance.database;

    final limit = DateTime.now()
        .subtract(const Duration(days: 3))
        .millisecondsSinceEpoch;

    await db.delete(
      'vitals',
      where: 'timestamp < ?',
      whereArgs: [limit],
    );
  }
}
