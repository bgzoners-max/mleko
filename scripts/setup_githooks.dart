import 'dart:io';

/// Postavlja pre-commit githook tako da pokreće `.githooks/pre-commit`
/// pre svakog `git commit` u ovom repozitorijumu.
///
/// Pokretanje: `dart run scripts/setup_githooks.dart`
/// Ponovno pokreni posle kloniranja repozitorijuma ili resetovanja .git/hooks.
void main() {
  final hooksDir = Directory('.githooks');
  final gitHooksDir = Directory('.git/hooks');

  if (!hooksDir.existsSync()) {
    stderr.writeln('ERROR: .githooks/ direktorijum nije pronađen.');
    exitCode = 1;
    return;
  }

  final preCommitSource = File('${hooksDir.path}/pre-commit');
  if (!preCommitSource.existsSync()) {
    stderr.writeln('ERROR: .githooks/pre-commit nije pronađen.');
    exitCode = 1;
    return;
  }

  if (!gitHooksDir.existsSync()) {
    stderr.writeln('ERROR: .git/hooks/ direktorijum nije pronađen (nije git repo?).');
    exitCode = 1;
    return;
  }

  final preCommitTarget = File('${gitHooksDir.path}/pre-commit');

  try {
    // Kopiraj sadržaj u .git/hooks/pre-commit (Windows ne podržava
    // simboličke linkove; na Unixu je bitno da je fajl izvršavan —
    // `chmod +x .git/hooks/pre-commit` ako je potrebno).
    preCommitTarget.writeAsBytesSync(preCommitSource.readAsBytesSync());
    stdout
      ..writeln('OK: pre-commit githook postavljen u .git/hooks/pre-commit')
      ..writeln('    Pokreće se automatski pre svakog git commit-a.');
  } catch (e) {
    stderr.writeln('ERROR: nije moguće upisati .git/hooks/pre-commit: $e');
    exitCode = 1;
  }
}
