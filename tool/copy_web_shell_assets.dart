import 'dart:io';

Future<void> main() async {
  final sourceDir = Directory('web');
  final buildDir = Directory('build/web');

  if (!sourceDir.existsSync()) {
    stderr.writeln('Source web directory not found: ${sourceDir.path}');
    exitCode = 1;
    return;
  }

  if (!buildDir.existsSync()) {
    stderr.writeln('Build output directory not found: ${buildDir.path}');
    stderr.writeln('Run `flutter build web` before copying web shell assets.');
    exitCode = 1;
    return;
  }

  final filesToCopy = <String>[
    'favicon.png',
    'manifest.json',
    'robots.txt',
    'sitemap.xml',
    'politika-privatnosti.html',
    'uslovi-koriscenja.html',
    '.well-known/assetlinks.json',
  ];

  for (final relativePath in filesToCopy) {
    final sourceFile = File('${sourceDir.path}/$relativePath');
    if (!sourceFile.existsSync()) {
      stderr.writeln('Missing source file: ${sourceFile.path}');
      exitCode = 1;
      return;
    }

    final targetFile = File('${buildDir.path}/$relativePath');
    targetFile.parent.createSync(recursive: true);
    sourceFile.copySync(targetFile.path);
    stdout.writeln('Copied $relativePath');
  }

  final sourceIcons = Directory('${sourceDir.path}/icons');
  if (!sourceIcons.existsSync()) {
    stderr.writeln('Missing source directory: ${sourceIcons.path}');
    exitCode = 1;
    return;
  }

  final targetIcons = Directory('${buildDir.path}/icons');
  if (targetIcons.existsSync()) {
    targetIcons.deleteSync(recursive: true);
  }
  targetIcons.createSync(recursive: true);

  for (final entity in sourceIcons.listSync(recursive: true)) {
    if (entity is! File) continue;
    final relativePath = entity.path.substring(sourceIcons.path.length + 1);
    final targetFile = File('${targetIcons.path}/$relativePath');
    targetFile.parent.createSync(recursive: true);
    entity.copySync(targetFile.path);
    stdout.writeln('Copied icons/$relativePath');
  }

  stdout.writeln('Web shell assets copied to ${buildDir.path}');
}
