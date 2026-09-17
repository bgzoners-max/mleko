import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:mleko/services/core/logger_service.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Sprečava `google_fonts` da pokušava da preuzme fontove sa mreže u testovima
  // i time baca non-fatal Exception greške u test logove.
  GoogleFonts.config.allowRuntimeFetching = false;
  
  // Utišaj bučne debug logove tokom testova
  LoggerService.enableConsoleLogging = false;
  
  await testMain();
}
