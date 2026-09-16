import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the sqflite connection and schema. Repositories talk to this,
/// nothing opens its own database.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String tableProducts = 'products';
  static const String tableEntries = 'entries';

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final String path = p.join(await getDatabasesPath(), 'daily_protein.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $tableProducts (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            name          TEXT    NOT NULL,
            measure_mode  TEXT    NOT NULL,
            unit_label    TEXT    NOT NULL,
            protein       REAL    NOT NULL,
            calories      REAL,
            price         REAL,
            created_at    INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $tableEntries (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            date       TEXT    NOT NULL,
            quantity   REAL    NOT NULL,
            protein    REAL    NOT NULL,
            calories   REAL    NOT NULL,
            cost       REAL    NOT NULL,
            meal       TEXT    NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (product_id) REFERENCES $tableProducts (id)
              ON DELETE CASCADE
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_entries_date ON $tableEntries (date)',
        );
      },
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Wipes user data. Used by the import flow before restoring a backup.
  Future<void> clearAll() async {
    final Database db = await database;
    await db.delete(tableEntries);
    await db.delete(tableProducts);
  }
}
