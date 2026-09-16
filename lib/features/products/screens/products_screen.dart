import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../log/data/log_controller.dart';
import '../../settings/data/settings_controller.dart';
import '../../../core/services/image_store.dart';
import '../../../core/theme/app_colors.dart';
import '../data/category_controller.dart';
import '../data/product_controller.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../../../core/widgets/section_header.dart';
import '../widgets/product_tile.dart';
import '../widgets/starter_foods_section.dart';
import 'product_form_screen.dart';

/// The product catalogue: everything the user can log.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _search = TextEditingController();

  /// Null means "All"; otherwise the category being filtered to.
  int? _categoryFilter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm({Product? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<Product>(
        builder: (_) => ProductFormScreen(existing: existing),
      ),
    );
  }

  Future<void> _confirmDelete(Product product) async {
    final ProductController controller = context.read<ProductController>();
    final int count = await controller.entryCount(product.id!);
    if (!mounted) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Delete ${product.name}?'),
        content: Text(
          count == 0
              ? 'This product is not used in any log yet.'
              : 'This will also remove $count logged '
                  '${count == 1 ? 'entry' : 'entries'} from your history.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await controller.delete(product.id!);
    // The row is gone, so nothing can reference its photo any more.
    await ImageStore().delete(product.imagePath);
    if (!mounted) return;
    await context.read<CategoryController>().refreshCounts();
    if (!mounted) return;
    await context.read<LogController>().load();
  }

  Widget _emptyState() => EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No products yet',
        message: 'Add the foods you eat with their protein content, or tap '
            'one of the popular foods above.',
        actionLabel: 'Add product',
        onAction: () => _openForm(),
      );

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ProductController controller = context.watch<ProductController>();
    final String currency = context.watch<SettingsController>().currencySymbol;
    final CategoryController categories = context.watch<CategoryController>();
    final AppIconColors icons = AppIconColors.of(context);

    final List<Product> products = controller
        .search(_search.text)
        .where((Product p) =>
            _categoryFilter == null || p.categoryId == _categoryFilter)
        .toList();

    // Categories worth offering: the ones the user has products in.
    final List<Category> used = categories.categories
        .where((Category c) => categories.countFor(c.id) > 0)
        .toList();

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Products',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Your foods and their nutrition',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _AddCustomButton(onTap: () => _openForm()),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _SearchField(
              controller: _search,
              onChanged: () => setState(() {}),
            ),
            if (used.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    _FilterChip(
                      label: 'All',
                      selected: _categoryFilter == null,
                      onTap: () => setState(() => _categoryFilter = null),
                    ),
                    for (final Category category in used)
                      _FilterChip(
                        label: category.name,
                        icon: category.iconData,
                        colour: category.resolveColour(icons),
                        selected: _categoryFilter == category.id,
                        onTap: () =>
                            setState(() => _categoryFilter = category.id),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            const StarterFoodsSection(),
            const SizedBox(height: AppSpacing.xl),
            if (controller.isLoading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.isEmpty)
              _emptyState()
            else ...<Widget>[
              SectionHeader(
                title: 'Your products',
                trailing: '${products.length}',
              ),
              if (products.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: Text(
                      _search.text.isEmpty
                          ? 'Nothing in this category yet'
                          : 'No product matches "${_search.text}"',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                for (final Product product in products)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ProductTile(
                      product: product,
                      currencySymbol: currency,
                      category: categories.byId(product.categoryId),
                      onTap: () => _openForm(existing: product),
                      trailing: _ProductMenu(
                        onEdit: () => _openForm(existing: product),
                        onDelete: () => _confirmDelete(product),
                      ),
                    ),
                  ),
            ],
            const SizedBox(height: AppSpacing.xl),
            _CantFindCard(onAdd: () => _openForm()),
          ],
        ),
      ),
    );
  }
}

/// Pill button in the header, matching the design's "Add Custom".
class _AddCustomButton extends StatelessWidget {
  const _AddCustomButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primary.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.add_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Add Custom',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded search field, styled apart from the app-wide input theme.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      borderSide: BorderSide(color: theme.colorScheme.outline),
    );

    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        hintText: 'Search for a food',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  controller.clear();
                  onChanged();
                },
              ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.6,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}

/// Edit and delete menu on a product row.
class _ProductMenu extends StatelessWidget {
  const _ProductMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onSelected: (String action) {
        if (action == 'edit') {
          onEdit();
        } else if (action == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.error,
            ),
            title: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }
}

/// Footer prompt from the design, for foods the starter list does not cover.
class _CantFindCard extends StatelessWidget {
  const _CantFindCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Text('🥗', style: TextStyle(fontSize: 34)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Can't find a food?",
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Add your own with its protein and calories.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _AddCustomButton(onTap: onAdd),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Category filter pill above the product list.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.colour,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? colour;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color tint = colour ?? theme.colorScheme.primary;
    final Color foreground =
        selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: selected ? tint : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(
                color: selected ? tint : theme.colorScheme.outline,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 15, color: selected ? foreground : tint),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
