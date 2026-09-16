import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/category_controller.dart';
import '../models/category.dart';

/// Choosing a product's category, with an option to create a new one.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({super.key, required this.selectedId});

  final int? selectedId;

  /// Returns the chosen category id, or null for "uncategorised". The
  /// outer Future is null when the user backs out without choosing.
  static Future<int?> show(BuildContext context, {int? selectedId}) {
    return showModalBottomSheet<int?>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => CategoryPicker(selectedId: selectedId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppIconColors icons = AppIconColors.of(context);
    final CategoryController controller = context.watch<CategoryController>();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (BuildContext context, ScrollController scroll) {
        return Column(
          children: <Widget>[
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 4,
              width: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Category',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _createCategory(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: <Widget>[
                  _CategoryOption(
                    label: 'Uncategorised',
                    icon: Icons.remove_circle_outline_rounded,
                    colour: theme.colorScheme.onSurfaceVariant,
                    selected: selectedId == null,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  for (final Category category in controller.categories)
                    _CategoryOption(
                      label: category.name,
                      icon: category.iconData,
                      colour: category.resolveColour(icons),
                      selected: category.id == selectedId,
                      onTap: () => Navigator.of(context).pop(category.id),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createCategory(BuildContext context) async {
    final CategoryController controller = context.read<CategoryController>();
    final NavigatorState navigator = Navigator.of(context);
    final Category? made = await showDialog<Category>(
      context: context,
      builder: (_) => const _NewCategoryDialog(),
    );
    if (made == null) return;
    final Category saved = await controller.add(made);
    navigator.pop(saved.id);
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.label,
    required this.icon,
    required this.colour,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color colour;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.10)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                width: selected ? 1.6 : 1,
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: colour.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(icon, size: 20, color: colour),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewCategoryDialog extends StatefulWidget {
  const _NewCategoryDialog();

  @override
  State<_NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<_NewCategoryDialog> {
  final TextEditingController _name = TextEditingController();
  String _icon = Category.iconKeys.first;
  String _colour = Category.colourKeys.first;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppIconColors icons = AppIconColors.of(context);

    return AlertDialog(
      title: const Text('New category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Icon'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final String key in Category.iconKeys)
                  _Swatch(
                    selected: key == _icon,
                    onTap: () => setState(() => _icon = key),
                    child: Icon(
                      Category(name: '', icon: key, colour: _colour).iconData,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Colour'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: <Widget>[
                for (final String key in Category.colourKeys)
                  _Swatch(
                    selected: key == _colour,
                    onTap: () => setState(() => _colour = key),
                    child: Container(
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Category(name: '', icon: _icon, colour: key)
                            .resolveColour(icons),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () {
            final String name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop(
              Category(name: name, icon: _icon, colour: _colour),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        height: 40,
        width: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
