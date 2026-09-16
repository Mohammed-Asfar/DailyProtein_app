import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../log/data/log_controller.dart';
import '../../products/data/product_controller.dart';
import '../data/backup_service.dart';
import '../data/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.navBarClearance,
        ),
        children: <Widget>[
          const SectionHeader(title: 'Daily goals'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                _GoalRow(
                  icon: Icons.fitness_center,
                  title: 'Protein goal',
                  value: Fmt.grams(settings.proteinGoal),
                  onTap: () => _editNumber(
                    context,
                    title: 'Daily protein goal',
                    suffix: 'g',
                    initial: settings.proteinGoal,
                    onSave: settings.setProteinGoal,
                  ),
                ),
                const Divider(height: 1),
                _GoalRow(
                  icon: Icons.local_fire_department_outlined,
                  title: 'Calorie goal',
                  value: Fmt.kcal(settings.calorieGoal),
                  onTap: () => _editNumber(
                    context,
                    title: 'Daily calorie goal',
                    suffix: 'kcal',
                    initial: settings.calorieGoal,
                    onSave: settings.setCalorieGoal,
                  ),
                ),
                const Divider(height: 1),
                _GoalRow(
                  icon: Icons.attach_money,
                  title: 'Currency symbol',
                  value: settings.currencySymbol,
                  onTap: () => _editCurrency(context, settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Appearance'),
          AppCard(
            child: RadioGroup<ThemeMode>(
              groupValue: settings.themeMode,
              onChanged: (ThemeMode? selected) {
                if (selected != null) settings.setThemeMode(selected);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final ThemeMode mode in ThemeMode.values)
                    RadioListTile<ThemeMode>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: mode,
                      title: Text(_themeLabel(mode)),
                      secondary: Icon(_themeIcon(mode)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Backup'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                _ActionRow(
                  icon: Icons.upload_file,
                  title: 'Export data',
                  subtitle: 'Save all products and logs as a JSON file',
                  onTap: () => _runBackup(
                    context,
                    () => BackupService().exportToFile(),
                  ),
                ),
                const Divider(height: 1),
                _ActionRow(
                  icon: Icons.download,
                  title: 'Import data',
                  subtitle: 'Replace everything with a backup file',
                  onTap: () => _confirmImport(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Danger zone'),
          AppCard(
            child: _ActionRow(
              icon: Icons.delete_forever_outlined,
              title: 'Clear all data',
              subtitle: 'Delete every product and log on this device',
              destructive: true,
              onTap: () => _confirmClear(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Text(
              'Daily Protein',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
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

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      trailing: Text(
        value,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color =
        destructive ? theme.colorScheme.error : theme.colorScheme.primary;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: destructive ? TextStyle(color: color) : null,
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      isThreeLine: false,
    );
  }
}
