import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../models/category.dart';

class CategoryRepository {
  CategoryRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<Category>> all() async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.tableCategories,
      orderBy: 'sort_order ASC, name COLLATE NOCASE ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<int> insert(Category category) async {
    final Database db = await _database.database;
    // New categories sort after the built-in ones.
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT MAX(sort_order) AS m FROM ${AppDatabase.tableCategories}',
    );
    final int next = ((rows.first['m'] as int?) ?? 0) + 1;
    return db.insert(
      AppDatabase.tableCategories,
      category.copyWith(sortOrder: next).toMap(),
    );
  }

  Future<void> update(Category category) async {
    final Database db = await _database.database;
    await db.update(
      AppDatabase.tableCategories,
      category.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[category.id],
    );
  }

  /// Deletes a user-made category. Products in it are left uncategorised by
  /// the ON DELETE SET NULL foreign key rather than deleted.
  Future<void> delete(int id) async {
    final Database db = await _database.database;
    await db.delete(
      AppDatabase.tableCategories,
      where: 'id = ? AND built_in = 0',
      whereArgs: <Object?>[id],
    );
  }

  /// How many products sit in each category, keyed by category id.
  Future<Map<int, int>> productCounts() async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT category_id, COUNT(*) AS c '
      'FROM ${AppDatabase.tableProducts} '
      'WHERE category_id IS NOT NULL GROUP BY category_id',
    );
    return <int, int>{
      for (final Map<String, Object?> row in rows)
        row['category_id'] as int: row['c'] as int,
    };
  }
}
