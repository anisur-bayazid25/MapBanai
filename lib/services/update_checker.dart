import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Result of an update check. Null from [UpdateChecker.checkForUpdate] means
/// the check failed (network/parse) or the app is already up to date.
class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;

  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    this.releaseNotes = '',
  });
}

/// Checks the GitHub Releases feed of this repository for a newer version
/// than the installed one. Never throws: any failure returns null so the
/// caller can safely ignore the result.
class UpdateChecker {
  static const String repo = 'anisur-bayazid25/MapBanai';

  static const Duration _timeout = Duration(seconds: 15);

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.github.com/repos/$repo/releases/latest'))
          .timeout(_timeout);
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = (body['tag_name'] as String?) ?? '';
      final version = tag.replaceFirst(RegExp(r'^v'), '');
      if (version.isEmpty) return null;

      String? downloadUrl;
      final assets = body['assets'] as List<dynamic>? ?? const [];
      for (final asset in assets) {
        if (asset is Map<String, dynamic> &&
            ((asset['name'] as String?) ?? '').endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'] as String?;
          break;
        }
      }
      if (downloadUrl == null) return null;

      final current = await PackageInfo.fromPlatform();
      if (compareVersions(current.version, version) >= 0) return null;

      return UpdateInfo(
        version: version,
        downloadUrl: downloadUrl,
        releaseNotes: (body['body'] as String?) ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Compares two version strings as integer arrays, ignoring build numbers
  /// and pre-release suffixes. Returns -1, 0 or 1 when [a] is older than,
  /// equal to, or newer than [b].
  static int compareVersions(String a, String b) {
    final pa = _parseVersion(a);
    final pb = _parseVersion(b);
    final length = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < length; i++) {
      final da = i < pa.length ? pa[i] : 0;
      final db = i < pb.length ? pb[i] : 0;
      if (da != db) return da < db ? -1 : 1;
    }
    return 0;
  }

  static List<int> _parseVersion(String value) {
    final core = value.split('+').first.split('-').first;
    final parts = <int>[];
    for (final segment in core.split('.')) {
      final number = int.tryParse(segment);
      if (number == null) break;
      parts.add(number);
    }
    return parts.isEmpty ? const [0] : parts;
  }
}
