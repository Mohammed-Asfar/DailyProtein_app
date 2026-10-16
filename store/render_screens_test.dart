// Renders the real screens with sample data for the Play Store listing.
//
//   flutter test --update-goldens store/render_screens_test.dart
//   python store/compose.py
//
// Not part of the normal suite: it lives outside test/ and only writes
// images, asserting nothing.

import 'dart:io';

import 'package:daily_protein/core/widgets/floating_nav_bar.dart';
import 'package:daily_protein/features/history/screens/history_screen.dart';
import 'package:daily_protein/features/home/screens/home_screen.dart';
import 'package:daily_protein/features/log/data/entry_repository.dart';
import 'package:daily_protein/features/log/data/log_controller.dart';
import 'package:daily_protein/features/log/models/food_entry.dart';
import 'package:daily_protein/features/products/data/category_controller.dart';
import 'package:daily_protein/features/products/data/category_repository.dart';
import 'package:daily_protein/features/products/data/product_controller.dart';
import 'package:daily_protein/features/products/data/product_repository.dart';
import 'package:daily_protein/features/products/data/starter_foods.dart';
import 'package:daily_protein/features/products/models/category.dart';
import 'package:daily_protein/features/products/models/product.dart';
import 'package:daily_protein/features/products/screens/products_screen.dart';
import 'package:daily_protein/features/settings/data/settings_controller.dart';
import 'package:daily_protein/features/settings/screens/settings_screen.dart';
import 'package:daily_protein/core/theme/app_theme.dart';
import 'package:daily_protein/core/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<String> _categoryNames = <String>[
  'Fruits', 'Vegetables', 'Grains', 'Proteins',
  'Dairy', 'Snacks', 'Drinks', 'Other',
];
const List<List<String>> _categorySeed = <List<String>>[
  <String>['apple', 'flame'], <String>['leaf', 'leaf'],
  <String>['grain', 'amber'], <String>['protein', 'chart'],
  <String>['dairy', 'cyan'], <String>['snack', 'violet'],
  <String>['drink', 'chart'], <String>['other', 'leaf'],
];

final List<Category> _categories = <Category>[
  for (int i = 0; i < _categoryNames.length; i++)
    Category(
      id: i + 1,
      name: _categoryNames[i],
      icon: _categorySeed[i][0],
      colour: _categorySeed[i][1],
      builtIn: true,
      sortOrder: i,
    ),
];

/// The starter catalogue, with prices on the everyday items so the cost
/// figures have something to show.
final List<Product> _products = () {
  const Map<String, double> prices = <String, double>{
    'Egg': 7, 'Chicken Breast': 32, 'Paneer': 45, 'Milk': 6,
    'Whey Scoop': 60, 'Greek Yogurt': 25, 'Toor Dal (cooked)': 8,
  };
  final List<Product> list = <Product>[];
  for (int i = 0; i < StarterFood.all.length; i++) {
    final StarterFood food = StarterFood.all[i];
    final Product p = food.toProduct(
      categoryId: _categoryNames.indexOf(food.categoryName) + 1,
    );
    list.add(p.copyWith(id: i + 1, price: () => prices[p.name]));
  }
  return list
    ..sort((Product a, Product b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}();

Product _p(String name) => _products.firstWhere(
      (Product p) => p.name == name,
      orElse: () => _products.first,
    );

FoodEntry _entry(int id, String name, double qty, Meal meal) {
  final Product p = _p(name);
  return FoodEntry(
    id: id,
    productId: p.id!,
    date: DayKey.today,
    quantity: qty,
    protein: p.proteinFor(qty),
    calories: p.caloriesFor(qty),
    cost: p.costFor(qty),
    meal: meal,
    createdAt: DateTime.now(),
    product: p,
  );
}

final List<FoodEntry> _today = <FoodEntry>[
  _entry(1, 'Egg', 3, Meal.breakfast),
  _entry(2, 'Milk', 250, Meal.breakfast),
  _entry(3, 'Chicken Breast', 150, Meal.lunch),
  _entry(4, 'Toor Dal (cooked)', 200, Meal.lunch),
  _entry(5, 'Whey Scoop', 1, Meal.snack),
];

/// A believable week: mostly near the goal, one short day.
const List<double> _week = <double>[118, 96, 124, 131, 88, 121, 0];

class _Entries extends EntryRepository {
  @override
  Future<List<FoodEntry>> forDate(String date) async =>
      date == DayKey.today ? _today : <FoodEntry>[];

  DayTotals _todayTotals() => DayTotals(
        date: DayKey.today,
        protein: _today.fold(0, (double s, FoodEntry e) => s + e.protein),
        calories: _today.fold(0, (double s, FoodEntry e) => s + e.calories),
        cost: _today.fold(0, (double s, FoodEntry e) => s + e.cost),
        entryCount: _today.length,
      );

  @override
  Future<DayTotals> totalsForDate(String date) async =>
      date == DayKey.today ? _todayTotals() : DayTotals.empty(date);

  Map<String, DayTotals> _history() {
    final List<String> days = DayKey.lastDays(_week.length);
    return <String, DayTotals>{
      for (int i = 0; i < days.length - 1; i++)
        days[i]: DayTotals(
          date: days[i],
          protein: _week[i],
          calories: _week[i] * 15,
          cost: _week[i] * 1.1,
          entryCount: 5,
        ),
      DayKey.today: _todayTotals(),
    };
  }

  @override
  Future<Map<String, DayTotals>> totalsForRange(String from, String to) async =>
      _history();

  @override
  Future<List<DayTotals>> allDays() async =>
      _history().values.toList().reversed.toList();
}

class _Products extends ProductRepository {
  @override
  Future<List<Product>> all() async => _products;
}

class _Categories extends CategoryRepository {
  @override
  Future<List<Category>> all() async => _categories;

  @override
  Future<Map<int, int>> productCounts() async => <int, int>{
        for (final Category c in _categories)
          c.id!: _products.where((Product p) => p.categoryId == c.id).length,
      };
}

Future<void> _loadFonts() async {
  final String sdk = Platform.environment['FLUTTER_ROOT']!;
  final String fonts = '$sdk/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String path) async =>
      ByteData.sublistView(await File(path).readAsBytes());

  final FontLoader roboto = FontLoader('Roboto');
  for (final String w in <String>['regular', 'medium', 'bold', 'black']) {
    roboto.addFont(read('$fonts/roboto-$w.ttf'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')
        ..addFont(read('$fonts/materialicons-regular.otf')))
      .load();
  // Fallback for the product emoji. Windows' font, as the renderer here
  // cannot draw the bitmap emoji Android ships.
  final File emoji = File('C:/Windows/Fonts/seguiemj.ttf');
  if (emoji.existsSync()) {
    await (FontLoader('Emoji')..addFont(read(emoji.path))).load();
  }
}

/// The layout of AppShell in app.dart, rebuilt so each tab can be shown
/// directly. Keep in step with it.
Widget _shell(int index, Widget page) {
  return Scaffold(
    body: page,
    floatingActionButtonLocation: FloatingNavBar.centerLocation,
    floatingActionButton: index == 0
        ? Builder(
            builder: (BuildContext context) =>
                FloatingNavBar.buildCenterButton(context, onPressed: () {}),
          )
        : null,
    bottomNavigationBar: FloatingNavBar(
      currentIndex: index,
      onSelected: (_) {},
      hasCenter: index == 0,
      items: const <NavItem>[
        NavItem(icon: Icons.today_outlined, selectedIcon: Icons.today_rounded, label: 'Today'),
        NavItem(icon: Icons.insights_outlined, selectedIcon: Icons.insights_rounded, label: 'History'),
        NavItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2_rounded, label: 'Products'),
        NavItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings_rounded, label: 'Settings'),
      ],
    ),
  );
}

void main() {
  setUpAll(_loadFonts);

  final Map<String, Widget Function()> screens = <String, Widget Function()>{
    '1_today': () => _shell(0, const HomeScreen()),
    '2_history': () => _shell(1, HistoryScreen(repository: _Entries())),
    '3_products': () => _shell(2, const ProductsScreen()),
    '4_settings': () => _shell(3, const SettingsScreen()),
  };

  for (final MapEntry<String, Widget Function()> screen in screens.entries) {
    testWidgets(screen.key, (WidgetTester tester) async {
      // 360 x 760 logical at 3x: 1080 x 2280, a typical modern phone.
      tester.view.physicalSize = const Size(1080, 2280);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues(<String, Object>{
        'theme_mode': 'dark',
        'daily_protein_goal': 120.0,
        'daily_calorie_goal': 2200.0,
        'onboarding_complete': true,
      });
      final SettingsController settings = SettingsController();
      final ProductController products =
          ProductController(repository: _Products());
      final CategoryController categories =
          CategoryController(repository: _Categories());
      final LogController log = LogController(repository: _Entries());
      await tester.runAsync(() async {
        await settings.load();
        await products.load();
        await categories.load();
        await log.load();
      });

      const Key frame = ValueKey<String>('frame');
      await tester.pumpWidget(
        MultiProvider(
          providers: <ChangeNotifierProvider<ChangeNotifier>>[
            ChangeNotifierProvider<SettingsController>.value(value: settings),
            ChangeNotifierProvider<ProductController>.value(value: products),
            ChangeNotifierProvider<CategoryController>.value(value: categories),
            ChangeNotifierProvider<LogController>.value(value: log),
          ],
          child: RepaintBoundary(
            key: frame,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              // Emoji fallback only here; on a phone the system supplies it.
              theme: AppTheme.dark.copyWith(
                textTheme: AppTheme.dark.textTheme
                    .apply(fontFamilyFallback: <String>['Emoji']),
              ),
              home: screen.value(),
            ),
          ),
        ),
      );
      // History and the version label resolve futures off the test clock.
      for (int i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(
              const Duration(milliseconds: 50),
            ));
        await tester.pump(const Duration(seconds: 1));
      }

      await expectLater(
        find.byKey(frame),
        matchesGoldenFile('raw/${screen.key}.png'),
      );
    });
  }
}
