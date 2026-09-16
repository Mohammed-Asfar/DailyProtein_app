import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../models/product.dart';

class ProductRepository {
  ProductRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<Product>> all() async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.tableProducts,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> byId(int id) async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.tableProducts,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<int> insert(Product product) async {
    final Database db = await _database.database;
    return db.insert(AppDatabase.tableProducts, product.toMap());
  }

  Future<void> update(Product product) async {
    final Database db = await _database.database;
    await db.update(
      AppDatabase.tableProducts,
      product.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[product.id],
    );
  }

  /// Deletes the product and, through the foreign key cascade, its entries.
  Future<void> delete(int id) async {
    final Database db = await _database.database;
    await db.delete(
      AppDatabase.tableProducts,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Number of logged entries pointing at a product, so the UI can warn
  /// before a delete cascades.
  Future<int> entryCount(int productId) async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${AppDatabase.tableEntries} '
      'WHERE product_id = ?',
      <Object?>[productId],
    );
    return (rows.first['c'] as int?) ?? 0;
  }
}
