/// Prevodi tehničke greške pri autentifikaciji u jasne poruke na srpskom jeziku.
String formatAuthError(Object error) {
  final msg = error.toString().toLowerCase();
  if (msg.contains('email not confirmed') || msg.contains('not confirmed')) {
    return 'Email adresa još nije potvrđena. Kliknite na link za aktivaciju u mejlu (proverite i Spam/Nepoželjno) ili pošaljite novi link ispod.';
  }
  if (msg.contains('invalid login') ||
      msg.contains('invalid') ||
      msg.contains('wrong') ||
      msg.contains('credentials') ||
      msg.contains('user not found') ||
      msg.contains('email already') ||
      msg.contains('already registered')) {
    return 'Pogrešan email ili lozinka.';
  }
  if (msg.contains('network') ||
      msg.contains('socketexception') ||
      msg.contains('connection') ||
      msg.contains('failed to fetch') ||
      msg.contains('xmlhttprequest')) {
    return 'Nema internet veze. Proveri konekciju i pokušaj ponovo.';
  }
  if (msg.contains('too many') || msg.contains('rate limit')) {
    return 'Previše pokušaja. Sačekaj nekoliko minuta i pokušaj ponovo.';
  }
  if (msg.contains('cancel') ||
      msg.contains('aborted') ||
      msg.contains('closed') ||
      msg.contains('interrupted')) {
    return 'Prijava putem Google-a je prekinuta.';
  }
  return 'Prijava nije uspela. Pokušaj ponovo.';
}
