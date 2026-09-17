import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/update_downloader.dart';
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

/// Tells the user a newer release exists and offers to install it.
Future<void> showUpdateDialog(BuildContext context, AppUpdate update) {
  return showDialog<void>(
    context: context,
    // The download runs inside the dialog, so it must not vanish on a stray
    // tap part way through.
    barrierDismissible: true,
    builder: (BuildContext context) => _UpdateDialog(update: update),
  );
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.update});

  final AppUpdate update;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  final UpdateDownloader _downloader = UpdateDownloader();

  bool _downloading = false;
  double? _progress;

  Future<void> _install() async {
    setState(() {
      _downloading = true;
      _progress = 0;
    });

    final DownloadResult result = await _downloader.download(
      widget.update,
      onProgress: (double? value) {
        if (mounted) setState(() => _progress = value);
      },
    );

    if (!mounted) return;

    if (result.succeeded) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _downloading = false;
      _progress = null;
    });

    if (result.outcome == DownloadOutcome.cancelled) return;

    // Falling back to the browser keeps the update reachable when the
    // in-app path fails, which it can for reasons the user cannot fix here.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'The download failed.'),
        action: SnackBarAction(
          label: 'Open page',
          onPressed: () => _openReleasePage(),
        ),
      ),
    );
  }

  Future<void> _openReleasePage() async {
    await launchUrl(
      Uri.parse(widget.update.pageUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  void _cancel() {
    _downloader.cancel();
    setState(() {
      _downloading = false;
      _progress = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppUpdate update = widget.update;

    return AlertDialog(
      title: Text('Version ${update.version} is available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            update.canInstallInApp
                ? 'The app can download and install this for you. Android '
                    'will ask for permission to install it.'
                : 'Opening the release page downloads the APK. Android will '
                    'ask for permission to install it.',
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
          if (_downloading) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              child: LinearProgressIndicator(value: _progress, minHeight: 6),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _progress == null
                  ? 'Downloading…'
                  : 'Downloading ${(_progress! * 100).round()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      actions: _downloading
          ? <Widget>[
              TextButton(onPressed: _cancel, child: const Text('Cancel')),
            ]
          : <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Later'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(96, 44),
                ),
                onPressed:
                    update.canInstallInApp ? _install : _openReleasePage,
                child: Text(
                  update.canInstallInApp ? 'Download' : 'Open page',
                ),
              ),
            ],
    );
  }
}
