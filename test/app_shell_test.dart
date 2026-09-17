import 'package:daily_protein/app.dart';
import 'package:daily_protein/core/widgets/floating_nav_bar.dart';
import 'package:daily_protein/features/log/data/log_controller.dart';
import 'package:daily_protein/features/products/data/category_controller.dart';
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

class _FakeCategories extends CategoryController {
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

  // This suite exercises the shell, which only appears once onboarding is
  // behind the user. Without this the app shows the welcome flow instead.
  @override
  bool get hasOnboarded => true;
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
      ChangeNotifierProvider<CategoryController>(
        create: (_) => _FakeCategories(),
      ),
      ChangeNotifierProvider<LogController>(create: (_) => _FakeLog()),
    ],
    child: const DailyProteinApp(),
  );
}

/// Matches only the shell's docked add button. Scoped to the
/// [FloatingActionButton] because the Products screen has its own
/// unrelated `+` in the app bar, which is a plain icon button.
final Finder _navAddButton = find.descendant(
  of: find.byType(FloatingActionButton),
  matching: find.byIcon(Icons.add_rounded),
);

/// Taps a nav destination by label, scoped to the bar: every screen stays
/// mounted in the shell's IndexedStack, so a bare text finder can match a
/// screen's own copy of the word instead of the tab.
Finder _tab(String label) => find.descendant(
      of: find.byType(FloatingNavBar),
      matching: find.text(label),
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
      await tester.tap(_tab(tab));
      // One frame to rebuild the shell, then time for the Scaffold to run
      // the button's exit animation — it unmounts the button at the end of
      // that, not on the rebuild. pumpAndSettle cannot be used here:
      // History and Products spin on a future that never resolves in tests.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(
        _navAddButton,
        findsNothing,
        reason: 'the add button should not appear on $tab',
      );
    }

    // Returning to Today brings it back.
    await tester.tap(_tab('Today'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(_navAddButton, findsOneWidget);
  });
}
