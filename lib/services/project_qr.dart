import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:mapbanai/services/project_package.dart';

/// QR payloads for project transfer.
///
/// A QR code cannot carry a large .mbproj file, so two formats exist,
/// both wrapped in the versioned envelope:
///
///   MAPBANAI-PROJECT-V1:<base64url(zlib(json))>
///
///  * `inline`   — the complete project definition (metadata + project +
///                 forms + layers) compressed into the QR. Only produced
///                 when it fits the safe QR budget; otherwise the exporter
///                 refuses with [ProjectTooLargeForQrException] and the UI
///                 falls back to the bootstrap code.
///  * `bootstrap` — project identity + package checksum + transfer hint
///                  (e.g. "get the .mbproj file and open it with MapBanai").
///                  Always small enough.
///
/// Never contains passwords, tokens or private credentials.
class ProjectQr {
  ProjectQr._();

  static const String envelopePrefix = 'MAPBANAI-PROJECT-V1:';
  static const int supportedVersion = 1;

  /// Safe payload budget: QR v40-L holds 2953 binary bytes; base64url
  /// inflates by 4/3 and zlib is a best-effort compression, so keep a
  /// generous safety margin below the hard limit.
  static const int maxInlinePayloadChars = 1800;

  /// Builds the *inline* QR payload for a project. Throws
  /// [ProjectTooLargeForQrException] when the definition cannot be encoded
  /// safely; callers should then show a bootstrap QR instead.
  static String encodeInline(ProjectPackageData data) {
    final payload = <String, dynamic>{
      'v': supportedVersion,
      'mode': 'inline',
      'project_id': data.meta.projectId,
      'project_name': data.meta.projectName,
      'project_version': data.meta.projectVersion,
      'exported_at': data.exportedAt,
      'project': {
        'project': data.project,
        'settings': data.settings,
        'layers': data.layers,
        'forms': data.forms,
      },
    };
    final encoded = _encodeObject(payload);
    if (encoded.length > maxInlinePayloadChars) {
      throw const ProjectTooLargeForQrException();
    }
    return '${ProjectQr.envelopePrefix}$encoded';
  }

  /// Builds the *bootstrap* QR payload (identity/checksum only). Always
  /// encodable. `checksum` is the SHA-256 of the accompanying .mbproj if
  /// known (e.g. right after an export while the bytes are in memory).
  static String encodeBootstrap({
    required String projectId,
    required String projectName,
    required int projectVersion,
    String checksum = '',
    String transfer = 'mbproj',
  }) {
    final payload = <String, dynamic>{
      'v': supportedVersion,
      'mode': 'bootstrap',
      'project_id': projectId,
      'project_name': projectName,
      'project_version': projectVersion,
      'checksum': checksum,
      'transfer': transfer,
    };
    return '${ProjectQr.envelopePrefix}${_encodeObject(payload)}';
  }

  /// Checksum helper reused by bootstrap QRs generated during export.
  static String sha256HexBytes(Uint8List bytes) => sha256.convert(bytes).toString();

  /// Parses and validates a QR payload string. Throws [FormatException] on
  /// anything suspicious (bad prefix, unknown version, bad base64/zlib,
  /// malformed JSON, missing identity fields, unsupported mode).
  static Map<String, dynamic> decode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Not a MapBanai project code');
    }
    final isEnvelope = trimmed.startsWith(envelopePrefix);
    final knownHttpPrefix = trimmed.startsWith('http');
    if (!isEnvelope && !knownHttpPrefix) {
      // Maybe the user pasted the entire mapbanai:// link or a raw URL.
      final asLink = Uri.tryParse(trimmed);
      if (asLink != null && asLink.scheme == 'mapbanai' && asLink.host == 'project') {
        final qr = asLink.queryParameters['qr'];
        if (qr != null && qr.isNotEmpty) {
          return decode(qr);
        }
      }
      if (trimmed.toLowerCase().endsWith('.mbproj') && knownHttpPrefix) {
        throw const FormatException('This is an online project link. '
            'Online project downloads are not supported yet — ask the '
            'sender for the project file or a project QR code.');
      }
      throw const FormatException('Not a MapBanai project code');
    }
    final body = isEnvelope ? trimmed.substring(envelopePrefix.length) : trimmed;
    final List<int> compressed;
    try {
      compressed = base64Url.decode(body);
    } catch (_) {
      throw const FormatException('Malformed MapBanai project code');
    }
    final List<int> inflated;
    try {
      inflated = zlib.decode(compressed);
    } catch (_) {
      throw const FormatException('Malformed MapBanai project code');
    }
    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(utf8.decode(inflated, allowMalformed: false));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Malformed MapBanai project code');
      }
      json = Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw const FormatException('Malformed MapBanai project code');
    }
    if (json['v'] != supportedVersion) {
      throw FormatException('Unsupported project code version');
    }
    final mode = (json['mode'] ?? '').toString();
    if (mode != 'inline' && mode != 'bootstrap') {
      throw const FormatException('Unknown project code type');
    }
    final id = (json['project_id'] ?? '').toString().trim();
    final name = (json['project_name'] ?? '').toString().trim();
    if (id.isEmpty || name.isEmpty) {
      throw const FormatException('Incomplete project code');
    }
    if (mode == 'inline') {
      final project = json['project'];
      if (project is! Map<String, dynamic> ||
          project.isEmpty ||
          project['project'] is! Map ||
          project['forms'] is! List) {
        throw const FormatException('Project code carries no project data');
      }
    }
    return json;
  }

  /// Parses a payload string like [decode] but returns null instead of
  /// throwing. Converts the `mapbanai://...?qr=` link and https URL forms.
  static Map<String, dynamic>? parse(String raw) {
    try {
      return decode(raw);
    } on FormatException {
      return null;
    }
  }

  /// Converts a validated inline payload into a [ProjectPackageData] ready
  /// for the importer. Morally equivalent to parsing the extracted package
  /// files, but without a zip envelope.
  static ProjectPackageData inlineToData(Map<String, dynamic> payload) {
    if (payload['mode'] != 'inline') {
      throw const FormatException('Not an inline project code');
    }
    final container = payload['project'] as Map<String, dynamic>;
    final project = container['project'];
    final settings = container['settings'];
    final layers = container['layers'];
    final forms = container['forms'];
    if (project is! Map<String, dynamic> ||
        settings is! Map<String, dynamic> ||
        layers is! Map<String, dynamic> ||
        forms is! List) {
      throw const FormatException('Incomplete inline project code');
    }
    final meta = ProjectPackageMeta.fromJson({
      'project_id': payload['project_id'] ?? project['project_id'],
      'project_name': payload['project_name'] ?? project['name'],
      'project_version': payload['project_version'] ?? project['project_version'],
      'created_at': project['created_at'],
      'exported_at': payload['exported_at'],
    });
    return ProjectPackageData.from(
      meta,
      Map<String, dynamic>.from(project),
      Map<String, dynamic>.from(settings),
      Map<String, dynamic>.from(layers),
      (forms as List)
          .whereType<Map>()
          .map((f) => Map<String, dynamic>.from(f))
          .toList(),
      exportedAt: meta.exportedAt,
    );
  }

  static String _encodeObject(Map<String, dynamic> payload) {
    final raw = utf8.encode(jsonEncode(payload));
    return base64Url.encode(zlib.encode(raw));
  }
}

class ProjectTooLargeForQrException implements Exception {
  const ProjectTooLargeForQrException();

  @override
  String toString() => 'Project is too large for direct QR transfer.';
}