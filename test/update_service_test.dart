import 'dart:convert';

import 'package:daily_protein/core/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A client answering every request with one canned response.
MockClient _client(int status, Object? body) {
  return MockClient((http.Request request) async {
    return http.Response(
      body is String ? body : jsonEncode(body),
      status,
      headers: <String, String>{'content-type': 'application/json'},
    );
  });
}

Map<String, Object?> _release({
  String tag = 'v1.1.0',
  String url = 'https://example.test/releases/v1.1.0',
  String? notes = 'Fixes things',
  bool draft = false,
  bool prerelease = false,
}) {
  return <String, Object?>{
    'tag_name': tag,
    'html_url': url,
    'body': notes,
    'draft': draft,
    'prerelease': prerelease,
  };
}

void main() {
  group('isNewer', () {
    test('a higher version is newer', () {
      expect(UpdateService.isNewer('1.1.0', than: '1.0.0'), isTrue);
      expect(UpdateService.isNewer('2.0.0', than: '1.9.9'), isTrue);
      expect(UpdateService.isNewer('1.0.1', than: '1.0.0'), isTrue);
    });

    test('the same version is not newer', () {
      expect(UpdateService.isNewer('1.0.0', than: '1.0.0'), isFalse);
    });

    test('a lower version is not newer', () {
      expect(UpdateService.isNewer('1.0.0', than: '1.1.0'), isFalse);
      expect(UpdateService.isNewer('1.9.9', than: '2.0.0'), isFalse);
    });

    test('segments compare as numbers, not text', () {
      // The bug this guards: '10' sorts before '9' as a string.
      expect(UpdateService.isNewer('1.10.0', than: '1.9.0'), isTrue);
      expect(UpdateService.isNewer('1.9.0', than: '1.10.0'), isFalse);
    });

    test('a missing segment counts as zero', () {
      expect(UpdateService.isNewer('1.2', than: '1.2.0'), isFalse);
      expect(UpdateService.isNewer('1.2.1', than: '1.2'), isTrue);
    });

    test('a leading v and build metadata are ignored', () {
      expect(UpdateService.isNewer('v1.1.0', than: '1.0.0+5'), isTrue);
      expect(UpdateService.isNewer('v1.0.0+9', than: '1.0.0+1'), isFalse);
    });

    test('an unparseable version never reports an update', () {
      // Better to miss an update than to nag about one that does not exist.
      expect(UpdateService.isNewer('banana', than: '1.0.0'), isFalse);
      expect(UpdateService.isNewer('1.0.0', than: 'banana'), isFalse);
      expect(UpdateService.isNewer('', than: '1.0.0'), isFalse);
    });
  });

  group('check', () {
    test('reports a newer release', () async {
      final AppUpdate? update = await UpdateService(
        client: _client(200, _release()),
      ).check(currentVersion: '1.0.0');

      expect(update, isNotNull);
      expect(update!.version, '1.1.0');
      expect(update.pageUrl, 'https://example.test/releases/v1.1.0');
      expect(update.notes, 'Fixes things');
    });

    test('says nothing when the app is current', () async {
      final AppUpdate? update = await UpdateService(
        client: _client(200, _release(tag: 'v1.0.0')),
      ).check(currentVersion: '1.0.0');

      expect(update, isNull);
    });

    test('says nothing when the app is ahead of the release', () async {
      final AppUpdate? update = await UpdateService(
        client: _client(200, _release(tag: 'v0.9.0')),
      ).check(currentVersion: '1.0.0');

      expect(update, isNull);
    });

    test('ignores drafts and pre-releases', () async {
      expect(
        await UpdateService(
          client: _client(200, _release(draft: true)),
        ).check(currentVersion: '1.0.0'),
        isNull,
      );
      expect(
        await UpdateService(
          client: _client(200, _release(prerelease: true)),
        ).check(currentVersion: '1.0.0'),
        isNull,
      );
    });

    test('blank release notes become null rather than an empty block',
        () async {
      final AppUpdate? update = await UpdateService(
        client: _client(200, _release(notes: '   ')),
      ).check(currentVersion: '1.0.0');

      expect(update?.notes, isNull);
    });

    group('fails silently', () {
      test('on an error status', () async {
        // 403 is what GitHub returns when the API is rate limited.
        expect(
          await UpdateService(
            client: _client(403, <String, Object?>{'message': 'rate limited'}),
          ).check(currentVersion: '1.0.0'),
          isNull,
        );
        expect(
          await UpdateService(
            client: _client(404, <String, Object?>{}),
          ).check(currentVersion: '1.0.0'),
          isNull,
        );
      });

      test('on a malformed body', () async {
        expect(
          await UpdateService(
            client: _client(200, 'not json'),
          ).check(currentVersion: '1.0.0'),
          isNull,
        );
        expect(
          await UpdateService(
            client: _client(200, <Object?>['a list, not an object']),
          ).check(currentVersion: '1.0.0'),
          isNull,
        );
      });

      test('when the release has no tag or url', () async {
        expect(
          await UpdateService(
            client: _client(200, <String, Object?>{'html_url': 'x'}),
          ).check(currentVersion: '1.0.0'),
          isNull,
        );
        expect(
          await UpdateService(
            client: _client(200, <String, Object?>{'tag_name': 'v2.0.0'}),
          ).check(currentVersion: '1.0.0'),
          isNull,
        );
      });

      test('when the network throws', () async {
        final MockClient throwing = MockClient(
          (http.Request request) async => throw const SocketExceptionStub(),
        );

        expect(
          await UpdateService(client: throwing).check(currentVersion: '1.0.0'),
          isNull,
        );
      });

      test('when the request times out', () async {
        final MockClient slow = MockClient((http.Request request) async {
          await Future<void>.delayed(const Duration(seconds: 2));
          return http.Response(jsonEncode(_release()), 200);
        });

        final AppUpdate? update = await UpdateService(
          client: slow,
          timeout: const Duration(milliseconds: 50),
        ).check(currentVersion: '1.0.0');

        expect(update, isNull);
      });
    });
  });
}

/// Stands in for a network failure without importing dart:io.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
