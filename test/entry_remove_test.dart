import 'package:daily_protein/features/log/data/log_controller.dart';
import 'package:daily_protein/features/log/models/food_entry.dart';
import 'package:daily_protein/features/log/screens/add_food_sheet.dart';
import 'package:daily_protein/features/products/data/product_controller.dart';
import 'package:daily_protein/features/products/models/product.dart';
import 'package:daily_protein/features/settings/data/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

final Product _egg = Product(
  id: 1,
  name: 'Egg',
  measureMode: MeasureMode.perUnit,
  unitLabel: 'egg',
  protein: 6,
  createdAt: DateTime(2026),
);

final FoodEntry _entry = FoodEntry(
  id: 1,
  productId: 1,
  date: '2026-10-16',
  quantity: 2,
  protein: 12,
  calories: 0,
  cost: 0,
  meal: Meal.breakfast,
  createdAt: DateTime(2026),
  product: _egg,
);

Widget _host({FoodEntry? editing, VoidCallback? onDelete}) {
  return MultiProvider(
    providers: <ChangeNotifierProvider<ChangeNotifier>>[
      ChangeNotifierProvider<SettingsController>(
        create: (_) => SettingsController(),
      ),
      ChangeNotifierProvider<ProductController>(
        create: (_) => ProductController(),
      ),
      ChangeNotifierProvider<LogController>(create: (_) => LogController()),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => AddFoodSheet.show(
            context,
            date: '2026-10-16',
            editing: editing,
            onDelete: onDelete,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('editing an entry offers Remove, which closes and deletes', (
    WidgetTester tester,
  ) async {
    int removed = 0;
    await tester.pumpWidget(
      _host(editing: _entry, onDelete: () => removed++),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Remove'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(removed, 1);
    expect(find.byType(AddFoodSheet), findsNothing);
  });

  testWidgets('a new entry has no Remove button', (WidgetTester tester) async {
    await tester.pumpWidget(_host(onDelete: () {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Remove'), findsNothing);
  });
}
