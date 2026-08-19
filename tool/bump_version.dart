import 'dart:io';

/// Bumps the app version in pubspec.yaml (and the mirrored AppInfo.version in
/// lib/models/app_info.dart).
///
/// Usage:
///   dart run tool/bump_version.dart [major|minor|patch] [--dry-run]
///
/// Examples:
///   dart run tool/bump_version.dart patch   # 2.1.0+1 -> 2.1.1+2
///   dart run tool/bump_version.dart minor   # 2.1.0+1 -> 2.2.0+2
///   dart run tool/bump_version.dart major   # 2.1.0+1 -> 3.0.0+2
///
/// The patch part is the default. The build number after '+' is always
/// incremented by 1. Exits non-zero when the version cannot be parsed or
/// written.
Future<void> main(List<String> args) async {
  final part = args.where((a) => !a.startsWith('--')).firstOrNull ?? 'patch';
  final dryRun = args.contains('--dry-run');

  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('bump_version: pubspec.yaml not found');
    exitCode = 1;
    return;
  }

  final lines = pubspec.readAsLinesSync();
  final versionLine = lines.indexWhere(
    (line) => line.startsWith('version:') &&
        RegExp(r'version:\s*\d+\.\d+\.\d+').hasMatch(line),
  );
  if (versionLine < 0) {
    stderr.writeln('bump_version: no "version: x.y.z" line found in pubspec');
    exitCode = 1;
    return;
  }

  final match = RegExp(r'(\d+)\.(\d+)\.(\d+)\+?(\d+)?')
      .firstMatch(lines[versionLine]);
  if (match == null) {
    stderr.writeln('bump_version: could not parse version line');
    exitCode = 1;
    return;
  }

  var major = int.parse(match.group(1)!);
  var minor = int.parse(match.group(2)!);
  var patch = int.parse(match.group(3)!);
  var build = int.tryParse(match.group(4) ?? '') ?? 0;

  switch (part) {
    case 'major':
      major++;
      minor = 0;
      patch = 0;
      break;
    case 'minor':
      minor++;
      patch = 0;
      break;
    case 'patch':
      patch++;
      break;
    default:
      stderr.writeln('bump_version: unknown part "$part" (major|minor|patch)');
      exitCode = 1;
      return;
  }
  build++;

  final newVersion = '$major.$minor.$patch+$build';
  final prefix = lines[versionLine].split('version:').first;
  lines[versionLine] = '${prefix}version: $newVersion';

  final appInfo = File('lib/models/app_info.dart');
  final infoLines = appInfo.readAsLinesSync();
  final infoIndex = infoLines.indexWhere(
    (line) => line.contains("static const String version = '"),
  );
  if (infoIndex >= 0) {
    final indent = infoLines[infoIndex].split("static const").first;
    infoLines[infoIndex] =
        "${indent}static const String version = '$newVersion';";
  } else {
    stderr.writeln('bump_version: warning: AppInfo.version not found');
  }

  if (dryRun) {
    stdout.writeln('would bump to $newVersion');
    return;
  }

  pubspec.writeAsStringSync('${lines.join('\n')}\n');
  appInfo.writeAsStringSync('${infoLines.join('\n')}\n');
  stdout.writeln('bumped to $newVersion');
}
