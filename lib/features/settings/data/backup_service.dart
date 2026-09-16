import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/image_store.dart';
import '../../../core/utils/date_utils.dart';
import '../../log/models/food_entry.dart';
import '../../products/models/product.dart';

class BackupResult {
  const BackupResult.success(this.message)
      : ok = true,
        cancelled = false;
  const BackupResult.failure(this.message)
      : ok = false,
        cancelled = false;
  const BackupResult.cancelled()
      : ok = false,
        cancelled = true,
        message = '';

  final bool ok;
  final bool cancelled;
  final String message;
}

/// Exports and restores the whole database as a single JSON file.
class BackupService {
  BackupService({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  static const String _formatTag = 'daily_protein_backup';
  static const int _formatVersion = 2;

  /// Opens the system save dialog and writes a JSON backup to the chosen
  /// location.
  Future<BackupResult> exportToFile() async {
    try {
      final Database db = await _database.database;
      final List<Map<String, Object?>> products =
          await db.query(AppDatabase.tableProducts);
      final List<Map<String, Object?>> entries =
          await db.query(AppDatabase.tableEntries);
      final List<Map<String, Object?>> categories =
          await db.query(AppDatabase.tableCategories);

      // Photos live on disk, not in the database, and are not portable to
      // another device. They are dropped from the backup rather than
      // exported as broken paths; everything else restores intact.
      final List<Map<String, Object?>> portableProducts = products
          .map((Map<String, Object?> row) => <String, Object?>{
                ...row,
                'image_path': null,
              })
          .toList();

      final Map<String, Object?> payload = <String, Object?>{
        'format': _formatTag,
        'version': _formatVersion,
        'exported_at': DateTime.now().toIso8601String(),
        'categories': categories,
        'products': portableProducts,
        'entries': entries,
      };

      final Uint8List bytes = Uint8List.fromList(
        utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
      );

      final Uri? saved = await FilePicker.saveFile(
        fileName: 'daily_protein_${DayKey.today}.json',
        bytes: bytes,
        mimeType: 'application/json',
        dialogTitle: 'Save Daily Protein backup',
      );

      if (saved == null) return const BackupResult.cancelled();

      return BackupResult.success(
        'Exported ${products.length} products and ${entries.length} entries',
      );
    } on Object catch (error) {
      return BackupResult.failure('Export failed: $error');
    }
  }

  /// Replaces all current data with the contents of a picked backup file.
  Future<BackupResult> importFromFile() async {
    try {
      final PlatformFile? picked = await FilePicker.pickFile(
        type: FileType.any,
        dialogTitle: 'Choose a Daily Protein backup',
      );
      if (picked == null) return const BackupResult.cancelled();

      final String raw = utf8.decode(await picked.readAsBytes());
      final Object? decoded = jsonDecode(raw);

      if (decoded is! Map<String, Object?>) {
        return const BackupResult.failure('That file is not a valid backup');
      }
      if (decoded['format'] != _formatTag) {
        return const BackupResult.failure(
          'That file is not a Daily Protein backup',
        );
      }

      final List<Object?> products =
          (decoded['products'] as List<Object?>?) ?? <Object?>[];
      final List<Object?> entries =
          (decoded['entries'] as List<Object?>?) ?? <Object?>[];
      // Absent in version 1 backups, which predate categories.
      final List<Object?> categories =
          (decoded['categories'] as List<Object?>?) ?? <Object?>[];

      final Database db = await _database.database;
      await db.transaction((Transaction txn) async {
        await txn.delete(AppDatabase.tableEntries);
        await txn.delete(AppDatabase.tableProducts);
        if (categories.isNotEmpty) {
          await txn.delete(AppDatabase.tableCategories);
          for (final Object? row in categories) {
            if (row is! Map<String, Object?>) continue;
            await txn.insert(AppDatabase.tableCategories, row);
          }
        }

        for (final Object? row in products) {
          if (row is! Map<String, Object?>) continue;
          // Round-trip through the model so a malformed row throws here and
          // rolls the transaction back instead of writing junk.
          final Product product = Product.fromMap(row);
          await txn.insert(AppDatabase.tableProducts, <String, Object?>{
            ...product.toMap(),
            'id': row['id'],
          });
        }
        for (final Object? row in entries) {
          if (row is! Map<String, Object?>) continue;
          final FoodEntry entry = FoodEntry.fromMap(row);
          await txn.insert(AppDatabase.tableEntries, <String, Object?>{
            ...entry.toMap(),
            'id': row['id'],
          });
        }
      });

      return BackupResult.success(
        'Restored ${products.length} products and ${entries.length} entries',
      );
    } on Object catch (error) {
      return BackupResult.failure('Import failed: $error');
    }
  }

  Future<BackupResult> clearAllData() async {
    try {
      // Photos are files, so clearing the tables alone would leave them
      // orphaned on disk for good.
      final Database db = await _database.database;
      final List<Map<String, Object?>> rows = await db.query(
        AppDatabase.tableProducts,
        columns: <String>['image_path'],
        where: 'image_path IS NOT NULL',
      );
      final ImageStore store = ImageStore();
      for (final Map<String, Object?> row in rows) {
        await store.delete(row['image_path'] as String?);
      }

      await _database.clearAll();
      return const BackupResult.success('All data cleared');
    } on Object catch (error) {
      return BackupResult.failure('Could not clear data: $error');
    }
  }
}
