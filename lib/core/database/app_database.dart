import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the sqflite connection and schema. Repositories talk to this,
/// nothing opens its own database.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String tableProducts = 'products';
  static const String tableEntries = 'entries';
  static const String tableCategories = 'categories';

  /// Bump on any schema change and add a matching step in [_upgrade].
  static const int schemaVersion = 3;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final String path = p.join(await getDatabasesPath(), 'daily_protein.db');
    return openDatabase(
      path,
      version: schemaVersion,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $tableCategories (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            name       TEXT    NOT NULL,
            icon       TEXT    NOT NULL,
            colour     TEXT    NOT NULL,
            built_in   INTEGER NOT NULL DEFAULT 0,
            sort_order INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE $tableProducts (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            name          TEXT    NOT NULL,
            measure_mode  TEXT    NOT NULL,
            unit_label    TEXT    NOT NULL,
            protein       REAL    NOT NULL,
            calories      REAL,
            price         REAL,
            category_id   INTEGER,
            image_path    TEXT,
            emoji         TEXT,
            created_at    INTEGER NOT NULL,
            FOREIGN KEY (category_id) REFERENCES $tableCategories (id)
              ON DELETE SET NULL
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
        await db.execute(
          'CREATE INDEX idx_products_category ON $tableProducts (category_id)',
        );
        await _seedCategories(db);
      },
      onUpgrade: _upgrade,
    );
  }

  /// Adds categories and product imagery. Existing rows keep their data:
  /// the new columns are nullable, so every product simply starts
  /// uncategorised with no image.
  static Future<void> _upgrade(Database db, int from, int to) async {
    if (from < 2) {
      await db.execute("""
        CREATE TABLE $tableCategories (
          id         INTEGER PRIMARY KEY AUTOINCREMENT,
          name       TEXT    NOT NULL,
          icon       TEXT    NOT NULL,
          colour     TEXT    NOT NULL,
          built_in   INTEGER NOT NULL DEFAULT 0,
          sort_order INTEGER NOT NULL DEFAULT 0
        )
      """);
      await db.execute(
        'ALTER TABLE $tableProducts ADD COLUMN category_id INTEGER',
      );
      await db.execute(
        'ALTER TABLE $tableProducts ADD COLUMN image_path TEXT',
      );
      await db.execute(
        'CREATE INDEX idx_products_category ON $tableProducts (category_id)',
      );
      await _seedCategories(db);
    }
    if (from < 3) {
      await db.execute(
        'ALTER TABLE $tableProducts ADD COLUMN emoji TEXT',
      );
    }
  }

  /// The built-in categories. Named here rather than in a model so a fresh
  /// install and an upgrade cannot drift apart.
  static Future<void> _seedCategories(Database db) async {
    const List<List<String>> seed = <List<String>>[
      <String>['Fruits', 'apple', 'flame'],
      <String>['Vegetables', 'leaf', 'leaf'],
      <String>['Grains', 'grain', 'amber'],
      <String>['Proteins', 'protein', 'chart'],
      <String>['Dairy', 'dairy', 'cyan'],
      <String>['Snacks', 'snack', 'violet'],
      <String>['Drinks', 'drink', 'chart'],
      <String>['Other', 'other', 'leaf'],
    ];
    final Batch batch = db.batch();
    for (int i = 0; i < seed.length; i++) {
      batch.insert(tableCategories, <String, Object?>{
        'name': seed[i][0],
        'icon': seed[i][1],
        'colour': seed[i][2],
        'built_in': 1,
        'sort_order': i,
      });
    }
    await batch.commit(noResult: true);
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
