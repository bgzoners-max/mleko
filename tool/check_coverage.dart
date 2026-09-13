import 'dart:io';

void main(List<String> args) {
  String lcovPath = 'coverage/lcov.info';
  double minCoverage = 0.0;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--min-coverage=')) {
      minCoverage = double.tryParse(arg.substring('--min-coverage='.length)) ?? 0.0;
    } else if (arg == '--min-coverage' && i + 1 < args.length) {
      minCoverage = double.tryParse(args[++i]) ?? 0.0;
    } else if (arg.startsWith('--min=')) {
      minCoverage = double.tryParse(arg.substring('--min='.length)) ?? 0.0;
    } else if (arg == '--min' && i + 1 < args.length) {
      minCoverage = double.tryParse(args[++i]) ?? 0.0;
    } else if (arg.startsWith('--file=')) {
      lcovPath = arg.substring('--file='.length);
    } else if (arg == '--file' && i + 1 < args.length) {
      lcovPath = args[++i];
    }
  }

  final file = File(lcovPath);
  if (!file.existsSync()) {
    stderr.writeln('ERROR: $lcovPath not found. Run "flutter test --coverage" first.');
    exitCode = 2;
    return;
  }

  final lines = file.readAsLinesSync();
  int totalFound = 0;
  int totalHit = 0;

  String? currentFile;
  int currentFound = 0;
  int currentHit = 0;
  final fileStats = <String, ({int found, int hit})>{};

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3).trim().replaceAll('\\', '/');
      currentFound = 0;
      currentHit = 0;
    } else if (line.startsWith('LF:')) {
      currentFound = int.tryParse(line.substring(3).trim()) ?? 0;
    } else if (line.startsWith('LH:')) {
      currentHit = int.tryParse(line.substring(3).trim()) ?? 0;
    } else if (line == 'end_of_record') {
      if (currentFile != null && currentFound > 0) {
        totalFound += currentFound;
        totalHit += currentHit;
        fileStats[currentFile] = (found: currentFound, hit: currentHit);
      }
      currentFile = null;
    }
  }

  if (totalFound == 0) {
    stderr.writeln('WARNING: No lines recorded in coverage/lcov.info.');
    return;
  }

  final totalPct = (totalHit / totalFound) * 100;
  stdout.writeln('========================================');
  stdout.writeln('COVERAGE REPORT');
  stdout.writeln('========================================');
  stdout.writeln('Lines found: $totalFound');
  stdout.writeln('Lines hit:   $totalHit');
  stdout.writeln('Coverage:    ${totalPct.toStringAsFixed(2)}%');
  stdout.writeln('Threshold:   ${minCoverage.toStringAsFixed(2)}%');
  stdout.writeln('========================================');

  // Summary by directory
  final dirStats = <String, ({int found, int hit})>{};
  for (final entry in fileStats.entries) {
    final path = entry.key;
    // e.g. lib/services/communication or lib/providers
    final parts = path.split('/');
    final prefix = parts.take(3).join('/');
    final prev = dirStats[prefix] ?? (found: 0, hit: 0);
    dirStats[prefix] = (found: prev.found + entry.value.found, hit: prev.hit + entry.value.hit);
  }

  stdout.writeln('\nCoverage by folder:');
  final sortedDirs = dirStats.entries.toList()
    ..sort((a, b) => ((b.value.hit / b.value.found) - (a.value.hit / a.value.found)).toInt());
  for (final entry in sortedDirs) {
    final pct = (entry.value.hit / entry.value.found) * 100;
    stdout.writeln('  ${pct.toStringAsFixed(1).padLeft(5)}% : ${entry.key} (${entry.value.hit}/${entry.value.found})');
  }

  if (totalPct < minCoverage) {
    stderr.writeln('\nFAILED: Coverage ${totalPct.toStringAsFixed(2)}% is below threshold of ${minCoverage.toStringAsFixed(2)}%');
    exitCode = 1;
  } else {
    stdout.writeln('\nPASSED: Coverage threshold met.');
  }
}
