import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Grid of food emoji, for giving a product a picture without a photo.
class EmojiPickerSheet extends StatelessWidget {
  const EmojiPickerSheet({super.key, this.selected});

  final String? selected;

  /// Returns the chosen emoji, or an empty string to clear it. Null means
  /// the user backed out.
  static Future<String?> show(BuildContext context, {String? selected}) {
    return showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => EmojiPickerSheet(selected: selected),
    );
  }

  /// Grouped so related foods sit together rather than in one long run.
  static const Map<String, List<String>> _groups = <String, List<String>>{
    'Protein': <String>[
      '🥚', '🍗', '🍖', '🥩', '🐟', '🦐', '🧀', '🥜', '🫘', '🍤',
    ],
    'Grains': <String>[
      '🍚', '🍞', '🫓', '🥖', '🥐', '🍜', '🍝', '🥣', '🌾', '🥯',
    ],
    'Vegetables': <String>[
      '🥦', '🥬', '🥕', '🌽', '🥔', '🍅', '🧅', '🧄', '🍆', '🫑',
    ],
    'Fruits': <String>[
      '🍌', '🍎', '🍊', '🍇', '🍓', '🥭', '🍍', '🥝', '🍑', '🍉',
    ],
    'Dairy': <String>[
      '🥛', '🍶', '🧈', '🍦', '🥧', '🍮',
    ],
    'Drinks': <String>[
      '☕', '🍵', '🥤', '🧃', '🧋', '🍹',
    ],
    'Snacks': <String>[
      '🍪', '🍫', '🍿', '🥨', '🍩', '🧁', '🍬', '🥗', '🌮', '🍕',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
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
                      'Choose an emoji',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (selected != null && selected!.isNotEmpty)
                    TextButton(
                      // An empty string clears it, which is distinct from
                      // null, meaning the user backed out.
                      onPressed: () => Navigator.of(context).pop(''),
                      child: const Text('Remove'),
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
                  for (final MapEntry<String, List<String>> group
                      in _groups.entries) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        group.key,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: <Widget>[
                        for (final String emoji in group.value)
                          _EmojiButton(
                            emoji: emoji,
                            selected: emoji == selected,
                            onTap: () => Navigator.of(context).pop(emoji),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        height: 48,
        width: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
