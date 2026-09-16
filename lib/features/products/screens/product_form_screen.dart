import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../settings/data/settings_controller.dart';
import '../data/product_controller.dart';
import '../models/product.dart';

/// Create or edit a product. Returns the saved [Product] via pop.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.existing});

  final Product? existing;

  bool get isEditing => existing != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _unit;
  late final TextEditingController _protein;
  late final TextEditingController _calories;
  late final TextEditingController _price;

  late MeasureMode _mode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final Product? existing = widget.existing;
    _mode = existing?.measureMode ?? MeasureMode.perUnit;
    _name = TextEditingController(text: existing?.name ?? '');
    _unit = TextEditingController(
      text: existing != null && existing.measureMode == MeasureMode.perUnit
          ? existing.unitLabel
          : 'piece',
    );
    _protein = TextEditingController(
      text: existing != null ? Fmt.number(existing.protein, decimals: 2) : '',
    );
    _calories = TextEditingController(
      text: existing?.calories != null
          ? Fmt.number(existing!.calories!, decimals: 2)
          : '',
    );
    _price = TextEditingController(
      text: existing?.price != null
          ? Fmt.number(existing!.price!, decimals: 2)
          : '',
    );
    _name.addListener(_refreshPreview);
    _protein.addListener(_refreshPreview);
    _unit.addListener(_refreshPreview);
  }

  void _refreshPreview() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _protein.dispose();
    _calories.dispose();
    _price.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  String get _basisLabel =>
      _mode == MeasureMode.perUnit ? _unitLabelOrDefault : '100 g';

  String get _unitLabelOrDefault {
    final String text = _unit.text.trim();
    return text.isEmpty ? 'piece' : text;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final ProductController controller = context.read<ProductController>();
    final Product product = Product(
      id: widget.existing?.id,
      name: _name.text.trim(),
      measureMode: _mode,
      unitLabel: _mode == MeasureMode.perUnit ? _unitLabelOrDefault : '100 g',
      protein: _parse(_protein) ?? 0,
      calories: _parse(_calories),
      price: _parse(_price),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    Product saved = product;
    if (widget.isEditing) {
      await controller.update(product);
    } else {
      saved = await controller.add(product);
    }

    if (!mounted) return;
    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String currency = context.watch<SettingsController>().currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit product' : 'New product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: <Widget>[
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Product name',
                hintText: 'Egg, Paneer, Whey scoop',
                prefixIcon: Icon(Icons.restaurant_menu),
              ),
              validator: (String? value) =>
                  (value == null || value.trim().isEmpty)
                      ? 'Give the product a name'
                      : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'How do you measure it?',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ModeSelector(
              mode: _mode,
              onChanged: (MeasureMode mode) => setState(() => _mode = mode),
            ),
            if (_mode == MeasureMode.perUnit) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _unit,
                decoration: const InputDecoration(
                  labelText: 'Unit name',
                  hintText: 'piece, egg, scoop, cup, glass',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Nutrition per $_basisLabel',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            _NumberField(
              controller: _protein,
              label: 'Protein',
              suffix: 'g',
              icon: Icons.fitness_center,
              validator: (String? value) {
                final double? parsed = _parse(_protein);
                if (parsed == null) return 'Enter the protein amount';
                if (parsed < 0) return 'Cannot be negative';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _NumberField(
              controller: _calories,
              label: 'Calories (optional)',
              suffix: 'kcal',
              icon: Icons.local_fire_department_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            _NumberField(
              controller: _price,
              label: 'Price (optional)',
              suffix: currency,
              icon: Icons.sell_outlined,
            ),
            const SizedBox(height: AppSpacing.xl),
            _LivePreview(
              name: _name.text.trim(),
              mode: _mode,
              unitLabel: _unitLabelOrDefault,
              protein: _parse(_protein),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.lg),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isEditing ? 'Save changes' : 'Add product'),
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final MeasureMode mode;
  final ValueChanged<MeasureMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (final MeasureMode option in MeasureMode.values) ...<Widget>[
          Expanded(
            child: _ModeCard(
              selected: option == mode,
              title: option == MeasureMode.perUnit ? 'Per piece' : 'Per 100 g',
              subtitle: option == MeasureMode.perUnit
                  ? 'Countable, like eggs'
                  : 'Weighed, like chicken',
              icon: option == MeasureMode.perUnit
                  ? Icons.egg_outlined
                  : Icons.scale_outlined,
              onTap: () => onChanged(option),
            ),
          ),
          if (option != MeasureMode.values.last)
            const SizedBox(width: AppSpacing.md),
        ],
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color border =
        selected ? theme.colorScheme.primary : theme.colorScheme.outline;
    return Material(
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
            border: Border.all(color: border, width: selected ? 1.6 : 1),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                icon,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? theme.colorScheme.primary : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.icon,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final IconData icon;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixText: suffix,
      ),
      validator: validator,
    );
  }
}

/// Shows what the entered numbers mean in practice, e.g. "3 eggs = 18 g".
class _LivePreview extends StatelessWidget {
  const _LivePreview({
    required this.name,
    required this.mode,
    required this.unitLabel,
    required this.protein,
  });

  final String name;
  final MeasureMode mode;
  final String unitLabel;
  final double? protein;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (protein == null || protein! <= 0) {
      return const SizedBox.shrink();
    }

    final String label = name.isEmpty ? 'This product' : name;
    final List<double> samples = mode == MeasureMode.perUnit
        ? <double>[1, 2, 3]
        : <double>[50, 100, 200];

    return AppCard(
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Auto-calculated',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final double sample in samples)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                mode == MeasureMode.perUnit
                    ? '$label x ${Fmt.number(sample, decimals: 0)} $unitLabel'
                        '  =  ${Fmt.grams(protein! * sample)} protein'
                    : '${Fmt.number(sample, decimals: 0)} g of $label  =  '
                        '${Fmt.grams(protein! * sample / 100)} protein',
                style: theme.textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}
