import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// A release newer than the one installed.
class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.pageUrl,
    this.notes,
  });

  /// Version of the release, without the leading `v`.
  final String version;

  /// The release page, opened in a browser. An APK cannot install itself
  /// from outside the Play Store without the user granting permission, so
  /// the download is deliberately left to them.
  final String pageUrl;

  final String? notes;
}

/// Checks GitHub Releases for a build newer than the installed one.
///
/// The app is otherwise offline, so every failure here is silent: no network,
/// a rate-limited API or a malformed response all return null rather than
/// surfacing an error the user can do nothing about.
class UpdateService {
  UpdateService({http.Client? client, this.timeout = const Duration(seconds: 5)})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// Kept short: this runs on launch, and a slow network must never be the
  /// reason the app feels slow to start.
  final Duration timeout;

  static const String _owner = 'Mohammed-Asfar';
  static const String _repo = 'DailyProtein_app';

  static final Uri _latestRelease = Uri.parse(
    'https://api.github.com/repos/$_owner/$_repo/releases/latest',
  );

  /// Returns the newer release, or null if the app is current or the check
  /// could not be completed.
  Future<AppUpdate?> check({String? currentVersion}) async {
    try {
      final String installed =
          currentVersion ?? (await PackageInfo.fromPlatform()).version;

      final http.Response response = await _client
          .get(_latestRelease, headers: const <String, String>{
            'Accept': 'application/vnd.github+json',
          })
          .timeout(timeout);

      if (response.statusCode != 200) return null;

      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      // Draft and pre-release builds are not offered to users.
      if (decoded['draft'] == true || decoded['prerelease'] == true) {
        return null;
      }

      final String? tag = decoded['tag_name'] as String?;
      final String? url = decoded['html_url'] as String?;
      if (tag == null || url == null) return null;

      final String latest = normalise(tag);
      if (!isNewer(latest, than: installed)) return null;

      final String? notes = decoded['body'] as String?;
      return AppUpdate(
        version: latest,
        pageUrl: url,
        notes: notes == null || notes.trim().isEmpty ? null : notes.trim(),
      );
    } on Object {
      // Deliberately broad: a failed update check must never break launch.
      return null;
    }
  }

  /// Strips a leading `v` and any build metadata, so `v1.2.0+3` and `1.2.0`
  /// compare equal.
  static String normalise(String version) {
    String value = version.trim();
    if (value.startsWith('v') || value.startsWith('V')) {
      value = value.substring(1);
    }
    final int plus = value.indexOf('+');
    return plus == -1 ? value : value.substring(0, plus);
  }

  /// Compares dotted numeric versions segment by segment.
  ///
  /// Missing segments count as zero, so `1.2` and `1.2.0` are equal. A
  /// segment that is not a number makes the comparison unsafe, and the
  /// answer is false — better to miss an update than to nag about one that
  /// does not exist.
  static bool isNewer(String candidate, {required String than}) {
    final List<int>? a = _segments(normalise(candidate));
    final List<int>? b = _segments(normalise(than));
    if (a == null || b == null) return false;

    final int length = a.length > b.length ? a.length : b.length;
    for (int i = 0; i < length; i++) {
      final int left = i < a.length ? a[i] : 0;
      final int right = i < b.length ? b[i] : 0;
      if (left != right) return left > right;
    }
    return false;
  }

  static List<int>? _segments(String version) {
    if (version.isEmpty) return null;
    final List<int> parts = <int>[];
    for (final String piece in version.split('.')) {
      final int? value = int.tryParse(piece.trim());
      if (value == null || value < 0) return null;
      parts.add(value);
    }
    return parts;
  }
}
