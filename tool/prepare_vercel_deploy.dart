import 'dart:io';

void main() {
  final buildWebDir = Directory('build/web');
  final apiDir = Directory('api');
  final deployDir = Directory('build/vercel-deploy');

  if (!buildWebDir.existsSync()) {
    stderr.writeln('Build output directory not found: ${buildWebDir.path}');
    stderr
        .writeln('Run `flutter build web` before preparing the Vercel bundle.');
    exitCode = 1;
    return;
  }

  if (!apiDir.existsSync()) {
    stderr.writeln('API directory not found: ${apiDir.path}');
    exitCode = 1;
    return;
  }

  if (deployDir.existsSync()) {
    deployDir.deleteSync(recursive: true);
  }
  deployDir.createSync(recursive: true);

  _copyDirectory(buildWebDir, Directory('${deployDir.path}/public'));
  _copyDirectory(apiDir, Directory('${deployDir.path}/api'));

  final filesToCopy = <String>[
    'vercel.json',
    'package.json',
    'package-lock.json',
  ];

  for (final relativePath in filesToCopy) {
    final source = File(relativePath);
    if (!source.existsSync()) {
      stderr.writeln('Missing required file: ${source.path}');
      exitCode = 1;
      return;
    }
    final target = File('${deployDir.path}/$relativePath');
    target.parent.createSync(recursive: true);
    source.copySync(target.path);
  }

  stdout.writeln('Prepared Vercel deploy bundle in ${deployDir.path}');
}

void _copyDirectory(Directory source, Directory target) {
  target.createSync(recursive: true);

  for (final entity in source.listSync(recursive: true)) {
    final relativePath = entity.path.substring(source.path.length + 1);
    if (entity is Directory) {
      Directory('${target.path}/$relativePath').createSync(recursive: true);
      continue;
    }
    if (entity is File) {
      final file = File('${target.path}/$relativePath');
      file.parent.createSync(recursive: true);
      entity.copySync(file.path);
    }
  }
}
