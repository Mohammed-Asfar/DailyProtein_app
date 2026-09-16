import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../log/data/log_controller.dart';
import '../../settings/data/settings_controller.dart';
import '../data/product_controller.dart';
import '../models/product.dart';
import '../widgets/product_tile.dart';
import 'product_form_screen.dart';

/// The product catalogue: everything the user can log.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _search = TextEditingController();

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
    if (!mounted) return;
    await context.read<LogController>().load();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ProductController controller = context.watch<ProductController>();
    final String currency = context.watch<SettingsController>().currencySymbol;
    final List<Product> products = controller.search(_search.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Add product',
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (!controller.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search products',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                        ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Builder(
              builder: (BuildContext context) {
                if (controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No products yet',
                    message:
                        'Add the foods you eat with their protein content. '
                        'Then logging a meal is just picking a product and '
                        'a quantity.',
                    actionLabel: 'Add product',
                    onAction: () => _openForm(),
                  );
                }
                if (products.isEmpty) {
                  return Center(
                    child: Text(
                      'No product matches "${_search.text}"',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.navBarClearance,
                  ),
                  itemCount: products.length,
                  separatorBuilder: (BuildContext _, int _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (BuildContext context, int index) {
                    final Product product = products[index];
                    return ProductTile(
                      product: product,
                      currencySymbol: currency,
                      onTap: () => _openForm(existing: product),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onSelected: (String action) {
                          if (action == 'edit') {
                            _openForm(existing: product);
                          } else if (action == 'delete') {
                            _confirmDelete(product);
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
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
                                style:
                                    TextStyle(color: theme.colorScheme.error),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
