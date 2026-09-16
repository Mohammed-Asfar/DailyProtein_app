import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../products/data/product_controller.dart';
import '../../products/models/product.dart';
import '../../products/screens/product_form_screen.dart';
import '../../products/widgets/product_tile.dart';
import '../../settings/data/settings_controller.dart';
import '../data/log_controller.dart';
import '../models/food_entry.dart';

/// Two-step bottom sheet: pick a product, then set the quantity while the
/// protein total updates live.
class AddFoodSheet extends StatefulWidget {
  const AddFoodSheet({super.key, required this.date, this.editing});

  final String date;

  /// When set, the sheet edits an existing entry instead of creating one.
  final FoodEntry? editing;

  static Future<void> show(
    BuildContext context, {
    required String date,
    FoodEntry? editing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddFoodSheet(date: date, editing: editing),
    );
  }

  @override
  State<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<AddFoodSheet> {
  final TextEditingController _search = TextEditingController();
  final TextEditingController _quantity = TextEditingController();

  Product? _selected;
  Meal _meal = Meal.snack;

  @override
  void initState() {
    super.initState();
    final FoodEntry? editing = widget.editing;
    if (editing != null) {
      _selected = editing.product;
      _meal = editing.meal;
      _quantity.text = Fmt.number(editing.quantity, decimals: 2);
    } else {
      _meal = _guessMeal();
    }
    _quantity.addListener(() => setState(() {}));
    _search.addListener(() => setState(() {}));
  }

  /// Picks a sensible default meal from the clock so most logs need no change.
  Meal _guessMeal() {
    final int hour = DateTime.now().hour;
    if (hour < 11) return Meal.breakfast;
    if (hour < 16) return Meal.lunch;
    if (hour < 22) return Meal.dinner;
    return Meal.snack;
  }

  @override
  void dispose() {
    _search.dispose();
    _quantity.dispose();
    super.dispose();
  }

  double? get _parsedQuantity =>
      double.tryParse(_quantity.text.trim().replaceAll(',', '.'));

  bool get _canSave {
    final double? qty = _parsedQuantity;
    return _selected != null && qty != null && qty > 0;
  }

  Future<void> _save() async {
    final Product product = _selected!;
    final double quantity = _parsedQuantity!;
    final LogController log = context.read<LogController>();
    final FoodEntry? editing = widget.editing;

    if (editing != null) {
      await log.updateEntry(
        editing.copyWith(
          productId: product.id,
          quantity: quantity,
          protein: product.proteinFor(quantity),
          calories: product.caloriesFor(quantity),
          cost: product.costFor(quantity),
          meal: _meal,
          product: product,
        ),
      );
    } else {
      await log.addFood(
        product: product,
        quantity: quantity,
        meal: _meal,
        date: widget.date,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _createProduct() async {
    final Product? created = await Navigator.of(context).push(
      MaterialPageRoute<Product>(builder: (_) => const ProductFormScreen()),
    );
    if (created != null && mounted) {
      setState(() => _selected = created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ProductController products = context.watch<ProductController>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (BuildContext context, ScrollController scrollController) {
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.editing != null
                                ? 'Edit food'
                                : _selected == null
                                    ? 'Pick a product'
                                    : 'How much?',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            DayKey.label(widget.date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selected != null && widget.editing == null)
                      TextButton.icon(
                        onPressed: () => setState(() => _selected = null),
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('Change'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _selected == null
                    ? _ProductPicker(
                        scrollController: scrollController,
                        products: products,
                        search: _search,
                        onSelect: (Product p) => setState(() => _selected = p),
                        onCreate: _createProduct,
                      )
                    : _QuantityStep(
                        scrollController: scrollController,
                        product: _selected!,
                        quantity: _quantity,
                        parsedQuantity: _parsedQuantity,
                        meal: _meal,
                        onMealChanged: (Meal m) => setState(() => _meal = m),
                      ),
              ),
              if (_selected != null)
                SafeArea(
                  minimum: const EdgeInsets.all(AppSpacing.lg),
                  child: FilledButton(
                    onPressed: _canSave ? _save : null,
                    child: Text(
                      widget.editing != null ? 'Save changes' : 'Add to log',
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductPicker extends StatelessWidget {
  const _ProductPicker({
    required this.scrollController,
    required this.products,
    required this.search,
    required this.onSelect,
    required this.onCreate,
  });

  final ScrollController scrollController;
  final ProductController products;
  final TextEditingController search;
  final ValueChanged<Product> onSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final String currency = context.watch<SettingsController>().currencySymbol;

    if (products.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No products yet',
        message: 'Create a product first, then you can log it in one tap.',
        actionLabel: 'Create a product',
        onAction: onCreate,
      );
    }

    final List<Product> results = products.search(search.text);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: TextField(
            controller: search,
            autofocus: false,
            decoration: const InputDecoration(
              hintText: 'Search products',
              prefixIcon: Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            itemCount: results.length + 1,
            separatorBuilder: (BuildContext _, int _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (BuildContext context, int index) {
              if (index == results.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: OutlinedButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add),
                    label: const Text('New product'),
                  ),
                );
              }
              final Product product = results[index];
              return ProductTile(
                product: product,
                currencySymbol: currency,
                onTap: () => onSelect(product),
                trailing: Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuantityStep extends StatelessWidget {
  const _QuantityStep({
    required this.scrollController,
    required this.product,
    required this.quantity,
    required this.parsedQuantity,
    required this.meal,
    required this.onMealChanged,
  });

  final ScrollController scrollController;
  final Product product;
  final TextEditingController quantity;
  final double? parsedQuantity;
  final Meal meal;
  final ValueChanged<Meal> onMealChanged;

  List<double> get _presets => product.measureMode == MeasureMode.perUnit
      ? <double>[1, 2, 3, 4, 6]
      : <double>[50, 100, 150, 200, 250];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String currency = context.watch<SettingsController>().currencySymbol;
    final double qty = parsedQuantity ?? 0;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            children: <Widget>[
              Text(
                product.name,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${Fmt.grams(product.protein)} protein '
                '${product.measureMode.basisSuffix(product.unitLabel)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // The live auto-calculated result.
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: product.proteinFor(qty),
                ),
                duration: const Duration(milliseconds: 250),
                builder: (BuildContext context, double value, _) => Text(
                  Fmt.grams(value),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Text(
                'protein',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              if (product.calories != null || product.price != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.lg,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    if (product.calories != null)
                      // Accented so the energy figure separates from the
                      // money one beside it.
                      Text(
                        Fmt.kcal(product.caloriesFor(qty)),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (product.price != null)
                      Text(
                        Fmt.money(product.costFor(qty), currency),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: <Widget>[
            _StepButton(
              icon: Icons.remove,
              onTap: () => _step(-1),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: quantity,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  suffixText: product.quantityUnit,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _StepButton(
              icon: Icons.add,
              onTap: () => _step(1),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          children: <Widget>[
            for (final double preset in _presets)
              ActionChip(
                label: Text(
                  '${Fmt.number(preset, decimals: 0)} '
                  '${product.quantityUnit}',
                ),
                onPressed: () => quantity.text =
                    Fmt.number(preset, decimals: 0),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Meal',
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: <Widget>[
            for (final Meal option in Meal.values)
              ChoiceChip(
                label: Text(option.label),
                selected: option == meal,
                onSelected: (_) => onMealChanged(option),
              ),
          ],
        ),
      ],
    );
  }

  /// Nudges the quantity by one preset step, keeping it at or above zero.
  void _step(int direction) {
    final double step = product.measureMode == MeasureMode.perUnit ? 1 : 25;
    final double current =
        double.tryParse(quantity.text.trim().replaceAll(',', '.')) ?? 0;
    final double next = (current + direction * step).clamp(0, 100000);
    quantity.text = Fmt.number(next, decimals: 2);
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Ink(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}
