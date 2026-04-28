import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pretvara tehničke greške u poruke za korisnika na srpskom.
String friendlyError(Object e) {
  final msg = e.toString().toLowerCase();

  if (e is TimeoutException ||
      msg.contains('timeout') ||
      msg.contains('timed out')) {
    return 'Zahtev je trajao predugo. Proveri internet vezu i pokušaj ponovo.';
  }

  if (msg.contains('network') ||
      msg.contains('socket') ||
      msg.contains('connection') ||
      msg.contains('failed host lookup') ||
      msg.contains('no route to host')) {
    return 'Nema internet veze. Proveri konekciju i pokušaj ponovo.';
  }

  if (e is StorageException) {
    final smsg = e.message.toLowerCase();
    if (smsg.contains('payload too large') ||
        smsg.contains('too large') ||
        smsg.contains('file size') ||
        e.statusCode == '413') {
      return 'Fajl je prevelik za upload. Maksimalna veličina je 10 MB.';
    }
    if (smsg.contains('not found') || e.statusCode == '404') {
      return 'Fajl nije pronađen.';
    }
    if (smsg.contains('unauthorized') ||
        smsg.contains('not authenticated') ||
        e.statusCode == '401' ||
        e.statusCode == '403') {
      return 'Nemaš dozvolu za ovu akciju. Prijavi se ponovo.';
    }
    return 'Greška pri radu sa fajlovima. Pokušaj ponovo.';
  }

  if (e is PostgrestException) {
    final pmsg = e.message.toLowerCase();
    if (pmsg.contains('duplicate') || pmsg.contains('unique')) {
      return 'Unos već postoji.';
    }
    if (pmsg.contains('foreign key') || pmsg.contains('violates')) {
      return 'Podatak je vezan za drugi zapis i ne može se obrisati.';
    }
    if (pmsg.contains('not found') || e.code == '404') {
      return 'Traženi podatak nije pronađen.';
    }
    if (pmsg.contains('unauthorized') ||
        pmsg.contains('not authenticated') ||
        e.code == '401' ||
        e.code == '403') {
      return 'Nemaš dozvolu za ovu akciju. Prijavi se ponovo.';
    }
    if (pmsg.contains('aggregate')) {
      return 'Greška pri učitavanju podataka. Pokušaj ponovo.';
    }
    return 'Greška pri radu sa podacima. Pokušaj ponovo.';
  }

  if (msg.contains('permission') || msg.contains('unauthorized')) {
    return 'Nemaš dozvolu za ovu akciju.';
  }

  if (msg.contains('not found') || msg.contains('404')) {
    return 'Traženi podatak nije pronađen.';
  }

  return 'Nešto je pošlo naopako. Pokušaj ponovo.';
}

/// Limit za upload fajlova (10 MB).
const int maxUploadBytes = 10 * 1024 * 1024;

/// Vraća poruku ako je fajl prevelik, ili null ako je OK.
String? checkFileSize(List<int> bytes) {
  if (bytes.length > maxUploadBytes) {
    final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
    return 'Slika je prevelika ($mb MB). Maksimalna veličina je 10 MB.';
  }
  return null;
}
