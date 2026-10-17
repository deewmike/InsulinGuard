import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

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
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'insulina.db');

    return await openDatabase(
      path,
      version: 3, // Aggiornata la versione
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE somministrazioni(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            time TEXT,
            dosage TEXT,
            insulinType TEXT,  -- nuovo campo per il tipo di insulina
            isTaken INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          // Aggiunge il campo insulinType se non esiste già
          await db.execute("ALTER TABLE somministrazioni ADD COLUMN insulinType TEXT");
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> getSomministrazioni() async {
    final db = await database;
    return await db.query('somministrazioni');
  }

  Future<void> insertSomministrazione(String date, String time, String meal, String dosage, String insulinType) async {
    final db = await database;
    await db.insert('somministrazioni', {
      'date': date,
      'time': time,
      'dosage': dosage,
      'insulinType': insulinType,  // salva anche il tipo di insulina
      'isTaken': 0,
    });
  }

  Future<void> markAsTaken(int id) async {
    final db = await database;
    await db.update(
      'somministrazioni',
      {'isTaken': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSomministrazione(int id) async {
    final db = await database;
    await db.delete(
      'somministrazioni',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<void> updateSomministrazione(int id, String date, String time, String dosage, String insulinType) async {
    final db = await database;
    await db.update(
      'somministrazioni',
      {
        'date': date,
        'time': time,
        'dosage': dosage,
        'insulinType': insulinType,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  Future<Map<String, dynamic>?> getNextSomministrazione() async {
    final db = await database;
    final now = DateTime.now();
    final formattedNowDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT * FROM somministrazioni 
      WHERE isTaken = 0 
      AND (date > ? OR (date = ? AND time >= ?))
      ORDER BY date ASC, time ASC 
      LIMIT 1
    ''', [formattedNowDate, formattedNowDate, "${now.hour}:${now.minute}"]);

    return result.isNotEmpty ? result.first : null;
  }
}
