import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/floating_nav_bar.dart';
import 'features/history/screens/history_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/log/data/log_controller.dart';
import 'features/log/screens/add_food_sheet.dart';
import 'features/products/data/category_controller.dart';
import 'features/products/data/product_controller.dart';
import 'features/products/screens/products_screen.dart';
import 'features/settings/data/settings_controller.dart';
import 'features/settings/screens/settings_screen.dart';

class DailyProteinApp extends StatelessWidget {
  const DailyProteinApp({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();

    return MaterialApp(
      title: 'Daily Protein',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      home: const AppShell(),
    );
  }
}

/// Bottom-navigation shell holding the four top-level destinations.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  /// Jumps to Home showing the given day, used when a history row is tapped.
  Future<void> _openDay(String date) async {
    await context.read<LogController>().setDate(date);
    if (mounted) setState(() => _index = 0);
  }

  /// Centre button. Logs against whichever day Home is currently showing, so
  /// adding while browsing a past day lands on that day rather than today.
  void _addFood() {
    AddFoodSheet.show(context, date: context.read<LogController>().date);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const HomeScreen(),
      HistoryScreen(onOpenDay: _openDay),
      const ProductsScreen(),
      const SettingsScreen(),
    ];

    // Only offered on Today, where logging happens. Elsewhere the button
    // would be an action with no relationship to the screen.
    final bool showAdd = _index == 0;

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      // The bar notches around the button but does not draw it; the
      // Scaffold docks it into the notch.
      floatingActionButtonLocation: FloatingNavBar.centerLocation,
      floatingActionButton: showAdd
          ? FloatingNavBar.buildCenterButton(
              context,
              onPressed: _addFood,
              tooltip: 'Add food',
            )
          : null,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _index,
        onSelected: (int index) => setState(() => _index = index),
        hasCenter: showAdd,
        items: const <NavItem>[
          NavItem(
            icon: Icons.today_outlined,
            selectedIcon: Icons.today_rounded,
            label: 'Today',
          ),
          NavItem(
            icon: Icons.insights_outlined,
            selectedIcon: Icons.insights_rounded,
            label: 'History',
          ),
          NavItem(
            icon: Icons.inventory_2_outlined,
            selectedIcon: Icons.inventory_2_rounded,
            label: 'Products',
          ),
          NavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings_rounded,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Loads the controllers before the first frame so no screen flashes empty.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _ready = _load();
  }

  Future<void> _load() async {
    // Read every controller up front so no lookup happens after an await.
    final SettingsController settings = context.read<SettingsController>();
    final ProductController products = context.read<ProductController>();
    final CategoryController categories = context.read<CategoryController>();
    final LogController log = context.read<LogController>();

    await settings.load();
    await categories.load();
    await products.load();
    // First launch only: an empty catalogue gets the common foods so there
    // is something to log straight away.
    await products.seedIfEmpty(categories.categories);
    await categories.refreshCounts();
    await log.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return const DailyProteinApp();
      },
    );
  }
}
