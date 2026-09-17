import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/services/update_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/settings_row.dart';
import '../../log/data/log_controller.dart';
import '../../products/data/product_controller.dart';
import '../data/backup_service.dart';
import '../data/settings_controller.dart';
import '../widgets/update_banner.dart';

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
            // Only while an update is waiting: dismissing the dialog with
            // Later should not mean losing track of it.
            if (settings.pendingUpdate != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              _UpdateBanner(
                update: settings.pendingUpdate!,
                onTap: () => showUpdateDialog(
                  context,
                  settings.pendingUpdate!,
                ),
              ),
            ],
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
                SettingsRow(
                  icon: Icons.notifications_active_outlined,
                  iconColor: icons.cyan,
                  title: 'Update Notifications',
                  subtitle: 'Look for a new version on launch',
                  trailing: Switch(
                    value: settings.checkForUpdates,
                    onChanged: settings.setCheckForUpdates,
                  ),
                  onTap: () =>
                      settings.setCheckForUpdates(!settings.checkForUpdates),
                ),
                SettingsRow(
                  icon: Icons.system_update_rounded,
                  iconColor: icons.chart,
                  title: 'Check for Updates',
                  subtitle: 'Look now and download the latest version',
                  onTap: () => _checkForUpdates(context),
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
            const SizedBox(height: AppSpacing.xl),
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
                  // Read from the package rather than written here: a
                  // hardcoded string drifts from pubspec, and the update
                  // check compares against this number.
                  const AppVersionLabel(),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Developed by ',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Asfar',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: icons.primaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Checks on demand, from the Settings row.
  ///
  /// Unlike the silent check on launch, this one always reports back: the
  /// user asked, so "you are up to date" and "that did not work" are both
  /// answers worth giving.
  Future<void> _checkForUpdates(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final SettingsController settings = context.read<SettingsController>();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final AppUpdate? update = await UpdateService().check();
    navigator.pop();

    if (!context.mounted) return;

    // Clears a stale banner as well as raising a new one.
    settings.setPendingUpdate(update);

    if (update == null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('You are on the latest version.')),
      );
      return;
    }

    await showUpdateDialog(context, update);
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

/// Sits at the top of Settings while an update is waiting to be installed.
class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({required this.update, required this.onTap});

  final AppUpdate update;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.system_update_rounded,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Version ${update.version} is available',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'Tap to download and install',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
