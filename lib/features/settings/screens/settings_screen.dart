import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/settings_row.dart';
import '../../log/data/log_controller.dart';
import '../../products/data/product_controller.dart';
import '../data/backup_service.dart';
import '../data/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SettingsController settings = context.watch<SettingsController>();
    final AppIconColors icons = AppIconColors.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.navBarClearance,
          ),
          children: <Widget>[
            Text(
              'Settings',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Personalise your targets and data',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SettingsGroup(
              title: 'Goals & Preferences',
              rows: <Widget>[
                SettingsRow(
                  icon: Icons.fitness_center_rounded,
                  iconColor: icons.flame,
                  title: 'Daily Protein Goal',
                  value: Fmt.grams(settings.proteinGoal),
                  onTap: () => _editNumber(
                    context,
                    title: 'Daily protein goal',
                    suffix: 'g',
                    initial: settings.proteinGoal,
                    onSave: settings.setProteinGoal,
                  ),
                ),
                SettingsRow(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: icons.amber,
                  title: 'Daily Calorie Goal',
                  value: Fmt.kcal(settings.calorieGoal),
                  onTap: () => _editNumber(
                    context,
                    title: 'Daily calorie goal',
                    suffix: 'kcal',
                    initial: settings.calorieGoal,
                    onSave: settings.setCalorieGoal,
                  ),
                ),
                SettingsRow(
                  icon: Icons.payments_rounded,
                  iconColor: icons.leaf,
                  title: 'Currency',
                  value: settings.currencySymbol,
                  onTap: () => _editCurrency(context, settings),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SettingsGroup(
              title: 'App Settings',
              rows: <Widget>[
                SettingsRow(
                  icon: _themeIcon(settings.themeMode),
                  iconColor: icons.violet,
                  title: 'Appearance',
                  value: _themeLabel(settings.themeMode),
                  onTap: () => _editTheme(context, settings),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SettingsGroup(
              title: 'Data & Privacy',
              rows: <Widget>[
                SettingsRow(
                  icon: Icons.ios_share_rounded,
                  iconColor: icons.chart,
                  title: 'Export Data',
                  subtitle: 'Save products and logs as a JSON file',
                  onTap: () => _runBackup(
                    context,
                    () => BackupService().exportToFile(),
                  ),
                ),
                SettingsRow(
                  icon: Icons.download_rounded,
                  iconColor: icons.cyan,
                  title: 'Import Data',
                  subtitle: 'Replace everything with a backup file',
                  onTap: () => _confirmImport(context),
                ),
                SettingsRow(
                  icon: Icons.delete_outline_rounded,
                  iconColor: icons.danger,
                  title: 'Clear All Data',
                  subtitle: 'Delete every product and log on this device',
                  destructive: true,
                  onTap: () => _confirmClear(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: Column(
                children: <Widget>[
                  Text(
                    'Daily Protein',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Version 1.0.0',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'Follow system',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  IconData _themeIcon(ThemeMode mode) => switch (mode) {
        ThemeMode.system => Icons.brightness_auto_outlined,
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
      };

  /// Appearance is now a row rather than an inline radio list, so the
  /// choice moves into a small dialog.
  Future<void> _editTheme(
    BuildContext context,
    SettingsController settings,
  ) async {
    final ThemeMode? picked = await showDialog<ThemeMode>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: const Text('Appearance'),
        children: <Widget>[
          for (final ThemeMode mode in ThemeMode.values)
            RadioListTile<ThemeMode>(
              value: mode,
              // ignore: deprecated_member_use
              groupValue: settings.themeMode,
              // ignore: deprecated_member_use
              onChanged: (ThemeMode? selected) =>
                  Navigator.of(context).pop(selected),
              title: Text(_themeLabel(mode)),
              secondary: Icon(_themeIcon(mode)),
            ),
        ],
      ),
    );
    if (picked != null) settings.setThemeMode(picked);
  }

  Future<void> _editNumber(
    BuildContext context, {
    required String title,
    required String suffix,
    required double initial,
    required ValueChanged<double> onSave,
  }) async {
    final TextEditingController controller =
        TextEditingController(text: Fmt.number(initial, decimals: 0));

    final double? result = await showDialog<double>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(suffixText: suffix),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () {
              final double? parsed = double.tryParse(
                controller.text.trim().replaceAll(',', '.'),
              );
              Navigator.of(context).pop(parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (result != null && result > 0) onSave(result);
  }

  Future<void> _editCurrency(
    BuildContext context,
    SettingsController settings,
  ) async {
    const List<String> symbols = <String>[r'₹', r'$', '€', '£', '¥', 'AED'];
    final String? picked = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: const Text('Currency symbol'),
        children: <Widget>[
          for (final String symbol in symbols)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(symbol),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  symbol,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
        ],
      ),
    );
    if (picked != null) settings.setCurrencySymbol(picked);
  }

  Future<void> _confirmImport(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Import backup?'),
        content: const Text(
          'This replaces every product and log currently on this device with '
          'the contents of the backup file. Export first if you want to keep '
          'what you have.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Choose file'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _runBackup(context, () => BackupService().importFromFile());
  }

  Future<void> _confirmClear(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'Every product and every logged day will be deleted. This cannot be '
          'undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size(96, 44),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _runBackup(context, () => BackupService().clearAllData());
  }

  /// Runs a backup operation, refreshes the in-memory state and reports
  /// the outcome.
  Future<void> _runBackup(
    BuildContext context,
    Future<BackupResult> Function() action,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final ProductController products = context.read<ProductController>();
    final LogController log = context.read<LogController>();

    final BackupResult result = await action();
    if (result.cancelled) return;

    await products.load();
    await log.load();

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(result.message)));
  }
}
