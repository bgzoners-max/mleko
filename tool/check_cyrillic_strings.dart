// check_cyrillic_strings.dart
import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('lib/ directory not found');
    exit(1);
  }

  final cyrillicRegExp = RegExp(r'[\u0400-\u04FF]');
  bool hasErrors = false;

  final dartFiles = libDir
      .listSync(recursive: true)
      .where((e) => e is File && e.path.endsWith('.dart'));

  for (final file in dartFiles) {
    final lines = (file as File).readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      if (cyrillicRegExp.hasMatch(lines[i])) {
        if (file.path.endsWith('classified_ad_model.dart')) {
          continue;
        }

        stderr.writeln('${file.path}:${i + 1}: Pronađeni su ćirilični karakteri:');
        stderr.writeln('  ${lines[i].trim()}');
        hasErrors = true;
      }
    }
  }

  if (hasErrors) {
    stderr.writeln('\nGREŠKA: Pronađeni su ćirilični karakteri u lib/ direktorijumu.');
    stderr.writeln('Svi stringovi i komentari u kodu treba da budu isključivo na latinici.');
    exit(1);
  } else {
    stdout.writeln('Provera uspešna. Nema neplaniranih ćiriličnih karaktera.');
    exit(0);
  }
}
