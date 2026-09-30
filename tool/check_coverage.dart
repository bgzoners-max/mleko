import 'dart:io';

/// Per-folder coverage gates for critical business logic.
/// If a folder's coverage drops below its threshold, CI will fail.
///
/// Ove vrednosti su RATCHET (zupčanik): postavljene su na trenutno izmereni
/// nivo (ili malo ispod) da CI ostane zelen, a cilj je da se podižu
/// postepeno kako se dodaju testovi. Nemojte ih podizati iznad izmerene
/// vrednosti — CI ce pasti dok se testovi ne dodaju.
///
/// `lib/utils` je aspiracioni cilj (45%): trenutno se preskace jer nijedan
/// fajl u tom folderu nije ukljucen u coverage, pa podizanje ne blokira build.
const Map<String, double> folderGates = {
  'lib/services/orders': 20.0,
  'lib/utils': 45.0,
};

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
    ..sort((a, b) =>
        (b.value.hit / b.value.found).compareTo(a.value.hit / a.value.found));
  for (final entry in sortedDirs) {
    final pct = (entry.value.hit / entry.value.found) * 100;
    final gateMarker = folderGates.containsKey(entry.key) ? ' [gate: ${folderGates[entry.key]}%]' : '';
    stdout.writeln('  ${pct.toStringAsFixed(1).padLeft(5)}% : ${entry.key} (${entry.value.hit}/${entry.value.found})$gateMarker');
  }

  // ── Per-folder gate checks ──
  bool gatesFailed = false;
  stdout.writeln('\n── Per-folder gates ──');
  for (final gate in folderGates.entries) {
    final stats = dirStats[gate.key];
    if (stats == null || stats.found == 0) {
      stdout.writeln('  SKIP  ${gate.key} — no coverage data (${gate.value}% required)');
      continue;
    }
    final pct = (stats.hit / stats.found) * 100;
    if (pct < gate.value) {
      stderr.writeln('  FAIL  ${gate.key}: ${pct.toStringAsFixed(2)}% < ${gate.value}% threshold');
      gatesFailed = true;
    } else {
      stdout.writeln('  PASS  ${gate.key}: ${pct.toStringAsFixed(2)}% >= ${gate.value}%');
    }
  }

  // ── Save coverage summary JSON for CI artifact ──
  _saveSummaryJson(totalPct, minCoverage, dirStats);

  // ── Final verdict ──
  if (totalPct < minCoverage) {
    stderr.writeln('\nFAILED: Coverage ${totalPct.toStringAsFixed(2)}% is below threshold of ${minCoverage.toStringAsFixed(2)}%');
    exitCode = 1;
  } else if (gatesFailed) {
    stderr.writeln('\nFAILED: One or more per-folder coverage gates not met.');
    exitCode = 1;
  } else {
    stdout.writeln('\nPASSED: Coverage threshold met.');
  }
}

void _saveSummaryJson(double totalPct, double threshold, Map<String, ({int found, int hit})> dirStats) {
  try {
    final buffer = StringBuffer();
    buffer.writeln('{');
    buffer.writeln('  "totalCoverage": ${totalPct.toStringAsFixed(2)},');
    buffer.writeln('  "threshold": ${threshold.toStringAsFixed(2)},');
    buffer.writeln('  "folders": {');
    final entries = dirStats.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final pct = (e.value.hit / e.value.found) * 100;
      final comma = i < entries.length - 1 ? ',' : '';
      buffer.writeln('    "${e.key}": {"found": ${e.value.found}, "hit": ${e.value.hit}, "coverage": ${pct.toStringAsFixed(2)}}$comma');
    }
    buffer.writeln('  }');
    buffer.writeln('}');
    File('coverage/coverage_summary.json').writeAsStringSync(buffer.toString());
    stdout.writeln('\nSaved coverage/coverage_summary.json');
  } catch (e) {
    stderr.writeln('WARNING: Could not save coverage summary: $e');
  }
}
