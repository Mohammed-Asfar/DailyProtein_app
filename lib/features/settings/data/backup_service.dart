import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
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
  static const int _formatVersion = 1;

  /// Opens the system save dialog and writes a JSON backup to the chosen
  /// location.
  Future<BackupResult> exportToFile() async {
    try {
      final Database db = await _database.database;
      final List<Map<String, Object?>> products =
          await db.query(AppDatabase.tableProducts);
      final List<Map<String, Object?>> entries =
          await db.query(AppDatabase.tableEntries);

      final Map<String, Object?> payload = <String, Object?>{
        'format': _formatTag,
        'version': _formatVersion,
        'exported_at': DateTime.now().toIso8601String(),
        'products': products,
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

      final Database db = await _database.database;
      await db.transaction((Transaction txn) async {
        await txn.delete(AppDatabase.tableEntries);
        await txn.delete(AppDatabase.tableProducts);

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
      await _database.clearAll();
      return const BackupResult.success('All data cleared');
    } on Object catch (error) {
      return BackupResult.failure('Could not clear data: $error');
    }
  }
}
