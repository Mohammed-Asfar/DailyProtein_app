import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/update_service.dart';
import '../../../core/theme/app_spacing.dart';

/// The installed version, read from the package at runtime.
///
/// Shows nothing until it resolves rather than a placeholder that would flash
/// a wrong number.
class AppVersionLabel extends StatefulWidget {
  const AppVersionLabel({super.key});

  @override
  State<AppVersionLabel> createState() => _AppVersionLabelState();
}

class _AppVersionLabelState extends State<AppVersionLabel> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return FutureBuilder<PackageInfo>(
      future: _info,
      builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
        final PackageInfo? info = snapshot.data;
        return Text(
          info == null ? '' : 'Version ${info.version}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}

/// Tells the user a newer release exists and offers to open it.
///
/// The app cannot install an APK over itself outside the Play Store, so the
/// action opens the release page and Android takes over from there.
Future<void> showUpdateDialog(BuildContext context, AppUpdate update) async {
  final bool? open = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      final ThemeData theme = Theme.of(context);

      return AlertDialog(
        title: Text('Version ${update.version} is available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Opening the release page downloads the APK. Android will ask '
              'for permission to install it.',
            ),
            if (update.notes != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              // Release notes are author-written and can run long, so they
              // scroll rather than pushing the buttons off screen. The cap
              // is a share of the screen, not a fixed 160px, which on a
              // tall phone left the notes looking cut off for no reason.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.3,
                ),
                child: ShaderMask(
                  // Fades the last few lines so a scrollable block reads as
                  // continuing rather than as text that got truncated.
                  shaderCallback: (Rect bounds) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const <double>[0, 0.85, 1],
                    colors: <Color>[
                      theme.colorScheme.onSurface,
                      theme.colorScheme.onSurface,
                      theme.colorScheme.onSurface.withValues(alpha: 0),
                    ],
                  ).createShader(bounds),
                  child: SingleChildScrollView(
                    child: Text(
                      update.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Later'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Download'),
          ),
        ],
      );
    },
  );

  if (open != true) return;
  await launchUrl(
    Uri.parse(update.pageUrl),
    mode: LaunchMode.externalApplication,
  );
}
