import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../products/models/product.dart';
import '../models/food_entry.dart';

class EntryRepository {
  EntryRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  static const String _joinedSelect = '''
    SELECT e.*,
           p.id           AS p_id,
           p.name         AS p_name,
           p.measure_mode AS p_measure_mode,
           p.unit_label   AS p_unit_label,
           p.protein      AS p_protein,
           p.calories     AS p_calories,
           p.price        AS p_price,
           p.created_at   AS p_created_at
    FROM ${AppDatabase.tableEntries} e
    LEFT JOIN ${AppDatabase.tableProducts} p ON p.id = e.product_id
  ''';

  Future<List<FoodEntry>> forDate(String date) async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '$_joinedSelect WHERE e.date = ? ORDER BY e.created_at ASC',
      <Object?>[date],
    );
    return rows.map(_mapJoined).toList();
  }

  Future<int> insert(FoodEntry entry) async {
    final Database db = await _database.database;
    return db.insert(AppDatabase.tableEntries, entry.toMap());
  }

  Future<void> update(FoodEntry entry) async {
    final Database db = await _database.database;
    await db.update(
      AppDatabase.tableEntries,
      entry.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[entry.id],
    );
  }

  Future<void> delete(int id) async {
    final Database db = await _database.database;
    await db.delete(
      AppDatabase.tableEntries,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<DayTotals> totalsForDate(String date) async {
    final Map<String, DayTotals> totals = await totalsForRange(date, date);
    return totals[date] ?? DayTotals.empty(date);
  }

  /// Totals per day between [from] and [to] inclusive, keyed by day.
  /// Days with no entries are absent from the map.
  Future<Map<String, DayTotals>> totalsForRange(
    String from,
    String to,
  ) async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT date, '
      'SUM(protein) AS protein, '
      'SUM(calories) AS calories, '
      'SUM(cost) AS cost, '
      'COUNT(*) AS entries '
      'FROM ${AppDatabase.tableEntries} '
      'WHERE date BETWEEN ? AND ? '
      'GROUP BY date ORDER BY date ASC',
      <Object?>[from, to],
    );
    return <String, DayTotals>{
      for (final Map<String, Object?> row in rows)
        row['date'] as String: DayTotals(
          date: row['date'] as String,
          protein: (row['protein'] as num?)?.toDouble() ?? 0,
          calories: (row['calories'] as num?)?.toDouble() ?? 0,
          cost: (row['cost'] as num?)?.toDouble() ?? 0,
          entryCount: (row['entries'] as int?) ?? 0,
        ),
    };
  }

  /// Every day that has at least one entry, newest first.
  Future<List<DayTotals>> allDays() async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT date, '
      'SUM(protein) AS protein, '
      'SUM(calories) AS calories, '
      'SUM(cost) AS cost, '
      'COUNT(*) AS entries '
      'FROM ${AppDatabase.tableEntries} '
      'GROUP BY date ORDER BY date DESC',
    );
    return rows
        .map(
          (Map<String, Object?> row) => DayTotals(
            date: row['date'] as String,
            protein: (row['protein'] as num?)?.toDouble() ?? 0,
            calories: (row['calories'] as num?)?.toDouble() ?? 0,
            cost: (row['cost'] as num?)?.toDouble() ?? 0,
            entryCount: (row['entries'] as int?) ?? 0,
          ),
        )
        .toList();
  }

  Future<List<FoodEntry>> allEntries() async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '$_joinedSelect ORDER BY e.date ASC, e.created_at ASC',
    );
    return rows.map(_mapJoined).toList();
  }

  FoodEntry _mapJoined(Map<String, Object?> row) {
    Product? product;
    if (row['p_id'] != null) {
      product = Product.fromMap(<String, Object?>{
        'id': row['p_id'],
        'name': row['p_name'],
        'measure_mode': row['p_measure_mode'],
        'unit_label': row['p_unit_label'],
        'protein': row['p_protein'],
        'calories': row['p_calories'],
        'price': row['p_price'],
        'created_at': row['p_created_at'],
      });
    }
    return FoodEntry.fromMap(row, product: product);
  }
}
