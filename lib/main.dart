import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/log/data/log_controller.dart';
import 'features/products/data/category_controller.dart';
import 'features/products/data/product_controller.dart';
import 'features/settings/data/settings_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<SettingsController>(
          create: (_) => SettingsController(),
        ),
        ChangeNotifierProvider<ProductController>(
          create: (_) => ProductController(),
        ),
        ChangeNotifierProvider<CategoryController>(
          create: (_) => CategoryController(),
        ),
        ChangeNotifierProvider<LogController>(
          create: (_) => LogController(),
        ),
      ],
      child: const AppBootstrap(),
    ),
  );
}
