import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'update_service.dart';

/// How a download ended.
enum DownloadOutcome {
  /// The installer was handed the file. Whether the user goes through with
  /// it is between them and Android.
  handedToInstaller,

  /// The user cancelled part way.
  cancelled,

  /// Anything else: no network, a bad response, no room on the device.
  failed,
}

/// Result of a download attempt, with a message worth showing.
class DownloadResult {
  const DownloadResult(this.outcome, [this.message]);

  final DownloadOutcome outcome;
  final String? message;

  bool get succeeded => outcome == DownloadOutcome.handedToInstaller;
}

/// Downloads a release APK and hands it to the system installer.
///
/// Kept apart from [UpdateService], which only answers "is there something
/// newer": this one writes to disk and leaves the app, so its failures are
/// worth reporting rather than swallowing.
class UpdateDownloader {
  UpdateDownloader({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  bool _cancelled = false;

  /// Stops an in-flight download. The partial file is removed.
  void cancel() => _cancelled = true;

  /// Fetches [update]'s APK, reporting progress from 0 to 1, then opens it.
  ///
  /// Progress is only meaningful when the release reports an asset size;
  /// without one the callback receives null so the UI can show an
  /// indeterminate bar rather than a dishonest percentage.
  Future<DownloadResult> download(
    AppUpdate update, {
    required void Function(double? progress) onProgress,
  }) async {
    final String? url = update.apkUrl;
    if (url == null) {
      return const DownloadResult(
        DownloadOutcome.failed,
        'This release has no APK attached.',
      );
    }

    _cancelled = false;
    File? file;

    try {
      final http.Request request = http.Request('GET', Uri.parse(url));
      final http.StreamedResponse response = await _client.send(request);

      if (response.statusCode != 200) {
        return DownloadResult(
          DownloadOutcome.failed,
          'The download failed (${response.statusCode}).',
        );
      }

      // Prefer the length the server reports: a release's recorded asset
      // size can be stale if the file was replaced.
      final int? total = response.contentLength ?? update.apkSize;

      final Directory dir = await getTemporaryDirectory();
      file = File('${dir.path}/DailyProtein-${update.version}.apk');
      if (file.existsSync()) await file.delete();

      final IOSink sink = file.openWrite();
      int received = 0;

      try {
        await for (final List<int> chunk in response.stream) {
          if (_cancelled) {
            await sink.close();
            await file.delete();
            return const DownloadResult(DownloadOutcome.cancelled);
          }
          sink.add(chunk);
          received += chunk.length;
          onProgress(total == null || total <= 0 ? null : received / total);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      // A truncated file would fail to install with a confusing message, so
      // check before handing it over.
      if (total != null && total > 0 && received != total) {
        await file.delete();
        return const DownloadResult(
          DownloadOutcome.failed,
          'The download was incomplete. Please try again.',
        );
      }

      final OpenResult opened = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );

      if (opened.type == ResultType.done) {
        return const DownloadResult(DownloadOutcome.handedToInstaller);
      }

      return DownloadResult(
        DownloadOutcome.failed,
        // Most often this is the install-unknown-apps permission, which the
        // user has to grant in system settings.
        'Could not open the installer. ${opened.message}',
      );
    } on Object catch (error) {
      if (file != null && file.existsSync()) {
        await file.delete();
      }
      if (_cancelled) return const DownloadResult(DownloadOutcome.cancelled);
      return DownloadResult(
        DownloadOutcome.failed,
        'The download failed: $error',
      );
    }
  }
}
