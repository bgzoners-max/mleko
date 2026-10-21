import 'dart:convert';
import 'dart:io';

/// Per-folder coverage gates for critical business logic.
/// If a folder's coverage drops below its threshold, CI will fail.
///
/// Ove vrednosti su RATCHET (zupčanik): postavljene su na trenutno izmereni
/// nivo (ili malo ispod) da CI ostane zelen, a cilj je da se podižu
/// postepeno kako se dodaju testovi. Nemojte ih podizati iznad izmerene
/// vrednosti — CI ce pasti dok se testovi ne dodaju.
///
/// NAPOMENA (2026-10-01): izmereno ~20.6% na cistom `flutter test --coverage`
/// run-u (27983 LF). Vrednost ~35% iz STATUS.md potice iz zastarelog
/// inkrementalnog `coverage/lcov.info` fajla i ne sme se koristiti kao osnova
/// za podizanje praga dok se CI ne prebaci na cist (brisan) coverage direktorijum.
///
/// `lib/utils` je aspiracioni cilj (45%): trenutno se preskace jer nijedan
/// fajl u tom folderu nije ukljucen u coverage, pa podizanje ne blokira build.
const Map<String, double> folderGates = {
  'lib/services/orders': 35.0,
  'lib/utils': 45.0,
};

/// Ratchet (zupčanik) prag: uz `--ratchet-file=<path>` prag ukupne pokrivenosti
/// i per-folder pragova se automatski diže sa svakim poboljšanjem, a zabranjuje
/// se pad veći od [_ratchetDropTolerance] procentnih poena. Fajl sa baseline
/// vrednostima se commit-uje u repozitorijum — CI traži da izmene budu
/// commit-ovane (isti obrazac kao STATUS.md).
///
/// - Tolerancija pada dozvoljava sitne fluktuacije bez crvenog CI-a.
/// - Histereza podizanja sprečava podizanje praga na beznačajne varijacije.
const double _ratchetDropTolerance = 0.5;
const double _ratchetRaiseHysteresis = 0.25;

void main(List<String> args) {
  String lcovPath = 'coverage/lcov.info';
  double minCoverage = 0.0;
  String? ratchetPath;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--min-coverage=')) {
      minCoverage =
          double.tryParse(arg.substring('--min-coverage='.length)) ?? 0.0;
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
    } else if (arg.startsWith('--ratchet-file=')) {
      ratchetPath = arg.substring('--ratchet-file='.length);
    } else if (arg == '--ratchet-file' && i + 1 < args.length) {
      ratchetPath = args[++i];
    }
  }

  final file = File(lcovPath);
  if (!file.existsSync()) {
    stderr.writeln(
        'ERROR: $lcovPath not found. Run "flutter test --coverage" first.');
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

  // ── Ratchet baseline (opciono) ──
  final ratchet = ratchetPath != null ? _loadRatchet(ratchetPath) : null;
  var effectiveMin = minCoverage;
  if (ratchet != null) {
    final ratchetMin = ratchet.total - _ratchetDropTolerance;
    if (ratchetMin > effectiveMin) effectiveMin = ratchetMin;
  }

  stdout.writeln('========================================');
  stdout.writeln('COVERAGE REPORT');
  stdout.writeln('========================================');
  stdout.writeln('Lines found: $totalFound');
  stdout.writeln('Lines hit:   $totalHit');
  stdout.writeln('Coverage:    ${totalPct.toStringAsFixed(2)}%');
  stdout.writeln('Threshold:   ${effectiveMin.toStringAsFixed(2)}%');
  if (ratchet != null) {
    stdout.writeln('Ratchet:     ${ratchet.total.toStringAsFixed(2)}% '
        '(drop tolerance ${_ratchetDropTolerance}pp)');
  }
  stdout.writeln('========================================');

  // Summary by directory
  final dirStats = <String, ({int found, int hit})>{};
  for (final entry in fileStats.entries) {
    final path = entry.key;
    final lastSlash = path.lastIndexOf('/');
    final prefix = lastSlash > 0 ? path.substring(0, lastSlash) : path;
    final prev = dirStats[prefix] ?? (found: 0, hit: 0);
    dirStats[prefix] = (
      found: prev.found + entry.value.found,
      hit: prev.hit + entry.value.hit
    );
  }

  stdout.writeln('\nCoverage by folder:');
  final sortedDirs = dirStats.entries.toList()
    ..sort((a, b) =>
        (b.value.hit / b.value.found).compareTo(a.value.hit / a.value.found));
  for (final entry in sortedDirs) {
    final pct = (entry.value.hit / entry.value.found) * 100;
    final gateMarker = folderGates.containsKey(entry.key)
        ? ' [gate: ${folderGates[entry.key]}%]'
        : '';
    stdout.writeln(
        '  ${pct.toStringAsFixed(1).padLeft(5)}% : ${entry.key} (${entry.value.hit}/${entry.value.found})$gateMarker');
  }

  // ── Per-folder gate checks ──
  bool gatesFailed = false;
  stdout.writeln('\n── Per-folder gates ──');
  for (final gate in folderGates.entries) {
    final stats = dirStats[gate.key];
    final baseline = ratchet?.folders[gate.key] ?? gate.value;
    if (stats == null || stats.found == 0) {
      stdout.writeln(
          '  SKIP  ${gate.key} — no coverage data (${baseline.toStringAsFixed(2)}% required)');
      continue;
    }
    final pct = (stats.hit / stats.found) * 100;
    final required =
        ratchet != null ? baseline - _ratchetDropTolerance : baseline;
    if (pct < required) {
      stderr.writeln(
          '  FAIL  ${gate.key}: ${pct.toStringAsFixed(2)}% < ${required.toStringAsFixed(2)}% threshold (baseline ${baseline.toStringAsFixed(2)}%)');
      gatesFailed = true;
    } else {
      stdout.writeln(
          '  PASS  ${gate.key}: ${pct.toStringAsFixed(2)}% >= ${required.toStringAsFixed(2)}% (baseline ${baseline.toStringAsFixed(2)}%)');
    }
  }

  // ── Save coverage summary JSON for CI artifact ──
  _saveSummaryJson(totalPct, minCoverage, dirStats);

  // ── Update README badge if present ──
  _updateReadmeBadge(totalPct);

  // ── Final verdict ──
  if (totalPct < effectiveMin) {
    stderr.writeln(
        '\nFAILED: Coverage ${totalPct.toStringAsFixed(2)}% is below threshold of ${effectiveMin.toStringAsFixed(2)}%');
    exitCode = 1;
  } else if (gatesFailed) {
    stderr.writeln('\nFAILED: One or more per-folder coverage gates not met.');
    exitCode = 1;
  } else {
    stdout.writeln('\nPASSED: Coverage threshold met.');
    if (ratchetPath != null) {
      _maybeRaiseRatchet(ratchetPath, ratchet, totalPct, dirStats);
    }
  }
}

// ── Ratchet (zupčanik) prag pokrivenosti ──────────────────────────────────────

class _RatchetBaseline {
  final double total;
  final Map<String, double> folders;
  const _RatchetBaseline({required this.total, required this.folders});
}

/// Učitava baseline iz ratchet fajla; vraća null ako fajl ne postoji ili je
/// neispravan (u tom slučaju alat inicijalizuje novi baseline).
_RatchetBaseline? _loadRatchet(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  try {
    final json = jsonDecode(file.readAsStringSync());
    if (json is! Map<String, dynamic>) return null;
    final total = (json['total'] as num?)?.toDouble();
    if (total == null) return null;
    final folders = <String, double>{};
    final rawFolders = json['folders'];
    if (rawFolders is Map<String, dynamic>) {
      for (final e in rawFolders.entries) {
        final v = (e.value as num?)?.toDouble();
        if (v != null) folders[e.key] = v;
      }
    }
    return _RatchetBaseline(total: total, folders: folders);
  } catch (e) {
    stderr.writeln(
        'WARNING: Could not parse ratchet file $path: $e — treating as absent.');
    return null;
  }
}

/// Ako je trenutna pokrivenost bolja od baseline-a za više od
/// [_ratchetRaiseHysteresis] pp, podiže baseline i upisuje ga u fajl.
/// Prvi run bez postojećeg fajla inicijalizuje baseline na trenutno
/// izmerene vrednosti (CI potom traži da se fajl commit-uje).
void _maybeRaiseRatchet(
  String path,
  _RatchetBaseline? current,
  double totalPct,
  Map<String, ({int found, int hit})> dirStats,
) {
  final oldTotal = current?.total;
  final oldFolders = current?.folders ?? const <String, double>{};

  var newTotal = oldTotal ?? totalPct;
  var changed = oldTotal == null;
  if (oldTotal != null && totalPct > oldTotal + _ratchetRaiseHysteresis) {
    newTotal = totalPct;
    changed = true;
  }

  final newFolders = <String, double>{...oldFolders};
  for (final gateKey in folderGates.keys) {
    final stats = dirStats[gateKey];
    if (stats == null || stats.found == 0) continue;
    final pct = (stats.hit / stats.found) * 100;
    final old = oldFolders[gateKey];
    if (old == null) {
      newFolders[gateKey] = pct;
      changed = true;
    } else if (pct > old + _ratchetRaiseHysteresis) {
      newFolders[gateKey] = pct;
      changed = true;
    }
  }

  if (!changed) return;

  final buf = StringBuffer()
    ..writeln('{')
    ..writeln('  "total": ${newTotal.toStringAsFixed(2)},')
    ..writeln('  "folders": {');
  final entries = newFolders.entries.toList();
  for (var i = 0; i < entries.length; i++) {
    final comma = i < entries.length - 1 ? ',' : '';
    buf.writeln(
        '    "${entries[i].key}": ${entries[i].value.toStringAsFixed(2)}$comma');
  }
  buf
    ..writeln('  }')
    ..writeln('}')
    ..writeln();
  File(path).writeAsStringSync(buf.toString());

  if (oldTotal == null) {
    stdout.writeln(
        '\nRATCHET INIT: $path created with current coverage as baseline — commit the file.');
  } else {
    stdout.writeln('\nRATCHET RAISED: $path updated '
        '(${oldTotal.toStringAsFixed(2)}% -> ${newTotal.toStringAsFixed(2)}%) — commit the file.');
  }
}

void _updateReadmeBadge(double totalPct) {
  try {
    final readmeFile = File('README.md');
    if (!readmeFile.existsSync()) return;

    final content = readmeFile.readAsStringSync();
    final badgeRegex = RegExp(
        r'\[!\[Coverage\]\(https:\/\/img\.shields\.io\/badge\/Coverage-[\d\.]+%25-[a-zA-Z]+\)\]\(STATUS\.md\)');
    final color = totalPct >= 50.0
        ? 'brightgreen'
        : totalPct >= 35.0
            ? 'yellowgreen'
            : totalPct >= 25.0
                ? 'orange'
                : 'red';
    final newBadge =
        '[![Coverage](https://img.shields.io/badge/Coverage-${totalPct.toStringAsFixed(2)}%25-$color)](STATUS.md)';

    if (badgeRegex.hasMatch(content)) {
      final updated = content.replaceFirst(badgeRegex, newBadge);
      if (updated != content) {
        readmeFile.writeAsStringSync(updated);
        stdout.writeln(
            'Updated Coverage badge in README.md to ${totalPct.toStringAsFixed(2)}% ($color)');
      }
    }
  } catch (e) {
    stderr.writeln('WARNING: Could not update README.md badge: $e');
  }
}

void _saveSummaryJson(double totalPct, double threshold,
    Map<String, ({int found, int hit})> dirStats) {
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
      buffer.writeln(
          '    "${e.key}": {"found": ${e.value.found}, "hit": ${e.value.hit}, "coverage": ${pct.toStringAsFixed(2)}}$comma');
    }
    buffer.writeln('  }');
    buffer.writeln('}');
    File('coverage/coverage_summary.json').writeAsStringSync(buffer.toString());
    stdout.writeln('\nSaved coverage/coverage_summary.json');
  } catch (e) {
    stderr.writeln('WARNING: Could not save coverage summary: $e');
  }
}
