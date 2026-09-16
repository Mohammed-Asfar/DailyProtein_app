import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/image_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Offers camera, gallery, and removal for a product photo.
///
/// Returns the new stored path, or a [ImageChoice.removed] marker when the
/// user clears the photo. A null result means they backed out.
class ImageChoice {
  const ImageChoice.picked(this.path)
      : removed = false,
        wantsEmoji = false;
  const ImageChoice.removed()
      : path = null,
        removed = true,
        wantsEmoji = false;

  /// The user chose "pick an emoji" instead; the caller opens that sheet.
  const ImageChoice.emoji()
      : path = null,
        removed = false,
        wantsEmoji = true;

  final String? path;
  final bool removed;
  final bool wantsEmoji;
}

class ImagePickerSheet extends StatelessWidget {
  const ImagePickerSheet({
    super.key,
    required this.hasImage,
    this.store,
  });

  final bool hasImage;

  /// Injectable so tests do not have to hit the platform picker.
  final ImageStore? store;

  static Future<ImageChoice?> show(
    BuildContext context, {
    required bool hasImage,
    ImageStore? store,
  }) {
    return showModalBottomSheet<ImageChoice>(
      context: context,
      useSafeArea: true,
      builder: (_) => ImagePickerSheet(hasImage: hasImage, store: store),
    );
  }

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final String? path = await (store ?? ImageStore()).pick(source);
      if (path == null) {
        navigator.pop();
        return;
      }
      navigator.pop(ImageChoice.picked(path));
    } on Object catch (error) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open the camera: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppIconColors icons = AppIconColors.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: 4,
              width: 44,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
            _Option(
              icon: Icons.photo_camera_rounded,
              colour: icons.chart,
              label: 'Take a photo',
              onTap: () => _pick(context, ImageSource.camera),
            ),
            _Option(
              icon: Icons.photo_library_rounded,
              colour: icons.violet,
              label: 'Choose from gallery',
              onTap: () => _pick(context, ImageSource.gallery),
            ),
            _Option(
              icon: Icons.emoji_emotions_rounded,
              colour: icons.amber,
              label: 'Pick an emoji',
              onTap: () =>
                  Navigator.of(context).pop(const ImageChoice.emoji()),
            ),
            if (hasImage)
              _Option(
                icon: Icons.delete_outline_rounded,
                colour: icons.danger,
                label: 'Remove photo',
                destructive: true,
                onTap: () =>
                    Navigator.of(context).pop(const ImageChoice.removed()),
              ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.colour,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final Color colour;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Icon(icon, size: 20, color: colour),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: destructive ? theme.colorScheme.error : null,
        ),
      ),
    );
  }
}
