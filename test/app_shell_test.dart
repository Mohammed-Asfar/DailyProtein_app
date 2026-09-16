import 'package:daily_protein/app.dart';
import 'package:daily_protein/core/widgets/floating_nav_bar.dart';
import 'package:daily_protein/features/log/data/log_controller.dart';
import 'package:daily_protein/features/products/data/product_controller.dart';
import 'package:daily_protein/features/settings/data/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Controllers that report as loaded and empty without touching sqflite,
/// which is unavailable in a plain widget test.
class _FakeProducts extends ProductController {
  @override
  Future<void> load() async {}
}

class _FakeLog extends LogController {
  @override
  Future<void> load() async {}
}

class _FakeSettings extends SettingsController {
  @override
  Future<void> load() async {}
}

Widget _shell() {
  return MultiProvider(
    providers: <ChangeNotifierProvider<ChangeNotifier>>[
      ChangeNotifierProvider<SettingsController>(
        create: (_) => _FakeSettings(),
      ),
      ChangeNotifierProvider<ProductController>(
        create: (_) => _FakeProducts(),
      ),
      ChangeNotifierProvider<LogController>(create: (_) => _FakeLog()),
    ],
    child: const DailyProteinApp(),
  );
}

/// Matches only the nav bar's own add button. Scoped to [FloatingNavBar]
/// because the Products screen has its own unrelated `+` in the app bar.
final Finder _navAddButton = find.descendant(
  of: find.byType(FloatingNavBar),
  matching: find.byIcon(Icons.add),
);

void main() {
  testWidgets('the add button shows on Today and nowhere else', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_shell());
    await tester.pump();

    // Today is the landing tab.
    expect(_navAddButton, findsOneWidget);

    for (final String tab in <String>['History', 'Products', 'Settings']) {
      await tester.tap(find.text(tab));
      await tester.pump();
      expect(
        _navAddButton,
        findsNothing,
        reason: 'the add button should not appear on $tab',
      );
    }

    // Returning to Today brings it back.
    await tester.tap(find.text('Today'));
    await tester.pump();
    expect(_navAddButton, findsOneWidget);
  });
}
