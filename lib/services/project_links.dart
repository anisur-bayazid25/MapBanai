/// Project link / URI architecture.
///
/// Recognized forms (v1):
///
///   mapbanai://project/import?file=<content-uri>&name=<hint>
///   mapbanai://project/import?qr=<url-encoded MAPBANAI-PROJECT-V1:...>
///   mapbanai://project/<external-project-id>
///   https://<host>/<path>.mbproj            (future server-hosted file)
///
/// The custom scheme is an INSTRUCTION mechanism only: it never hosts or
/// downloads a project. When the file points at a content:// URI handed to
/// MapBanai by Android, the native side materializes it into the cache
/// before the import flow starts. HTTPS .mbproj URLs are recognized and
/// reported so a future build can add download support without changing
/// the format.
class ProjectLinkInfo {
  const ProjectLinkInfo({this.fileUri, this.qrPayload, this.projectId});

  final String? fileUri;
  final String? qrPayload;
  final String? projectId;

  bool get hasImportWork => fileUri != null || qrPayload != null;
}

class ProjectLinks {
  ProjectLinks._();

  static const scheme = 'mapbanai';

  /// Returns null when the string is not a recognized MapBanai link.
  static ProjectLinkInfo? parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    try {
      final uri = Uri.parse(trimmed);
      if (uri.scheme == scheme && uri.host == 'project') {
        final segments = uri.pathSegments;
        if (segments.isNotEmpty && segments.first == 'import') {
          final qr = uri.queryParameters['qr'];
          if (qr != null && qr.isNotEmpty) {
            return ProjectLinkInfo(qrPayload: qr);
          }
          final file = uri.queryParameters['file'];
          if (file != null && file.isNotEmpty) {
            return ProjectLinkInfo(fileUri: file);
          }
          return const ProjectLinkInfo();
        }
        if (segments.isNotEmpty) {
          return ProjectLinkInfo(projectId: segments.first);
        }
        return const ProjectLinkInfo();
      }
      if (uri.scheme == 'https' && trimmed.toLowerCase().endsWith('.mbproj')) {
        return ProjectLinkInfo(fileUri: trimmed);
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}