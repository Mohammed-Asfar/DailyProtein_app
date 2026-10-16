import 'package:daily_protein/features/log/data/entry_repository.dart';
import 'package:daily_protein/features/log/data/log_controller.dart';
import 'package:daily_protein/features/log/models/food_entry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fails every query, standing in for a database that will not open.
class _BrokenEntries extends EntryRepository {
  @override
  Future<List<FoodEntry>> forDate(String date) async =>
      throw StateError('database unavailable');
}

void main() {
  test('a failed load still ends the loading state', () async {
    final LogController log = LogController(repository: _BrokenEntries());

    await expectLater(log.load(), throwsStateError);

    // Before the fix this stayed true and Today spun forever.
    expect(log.isLoading, isFalse);
  });
}
