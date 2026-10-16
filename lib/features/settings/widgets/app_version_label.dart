import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
