import 'dart:io';

final _directiveRegex =
  RegExp("^\\s*(import|export)\\s+['\\\"]([^'\\\"]+)['\\\"]");

void main() {
  if (!Directory('lib').existsSync()) {
    stderr.writeln('ERROR: lib/ directory not found.');
    exitCode = 2;
    return;
  }

  final violations = <String>[];

  final dartFiles = <File>[];
  for (final root in const ['lib', 'test', 'integration_test']) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    dartFiles.addAll(
      dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')),
    );
  }

  for (final file in dartFiles) {
    final relativePath = file.path.replaceAll('\\', '/');
    final lines = file.readAsLinesSync();

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = _directiveRegex.firstMatch(line);
      if (match == null) {
        continue;
      }

      final uri = match.group(2)!;
      if (_isForbiddenLegacyServiceImport(uri)) {
        violations.add('$relativePath:${i + 1} -> $uri');
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('OK: No legacy root service imports found.');
    return;
  }

  stderr.writeln('ERROR: Legacy root service imports are forbidden.');
  stderr.writeln('Use domain barrels, e.g. services/catalog/catalog_services.dart');
  stderr.writeln('or the umbrella barrel services/services.dart.');
  stderr.writeln('');
  for (final violation in violations) {
    stderr.writeln(' - $violation');
  }

  exitCode = 1;
}

bool _isForbiddenLegacyServiceImport(String uri) {
  final normalized = uri.replaceAll('\\', '/');

  // Support both package imports and relative imports.
  final serviceIndex = normalized.indexOf('services/');
  if (serviceIndex < 0) {
    return false;
  }

  final suffix = normalized.substring(serviceIndex);
  final rootFileMatch = RegExp(r'^services/([^/]+)\.dart$').firstMatch(suffix);
  if (rootFileMatch == null) {
    return false;
  }

  final fileName = rootFileMatch.group(1)!;

  // Allowed root umbrella barrel.
  if (fileName == 'services') {
    return false;
  }

  return true;
}
