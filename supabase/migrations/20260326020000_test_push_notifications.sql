-- Test push notifikacija
-- Ova skriptura pronalazi korisnika sa registrovanim tokenom i kreira test notifikaciju

DO $$
DECLARE
  test_user_id UUID;
  token_count INT;
BEGIN
  -- Pronađi bilo kog korisnika sa registrovanim FCM tokenom
  SELECT user_id INTO test_user_id
  FROM user_push_tokens
  LIMIT 1;

  -- Prebroj ukupne tokene
  SELECT COUNT(*) INTO token_count FROM user_push_tokens;

  IF test_user_id IS NOT NULL THEN
    RAISE NOTICE 'Pronađen korisnik sa tokenom: %', test_user_id;
    RAISE NOTICE 'Ukupni tokeni u sistemu: %', token_count;

    -- Kreiraj test notifikaciju
    INSERT INTO notifications (user_id, type, title, body)
    VALUES (
      test_user_id,
      'test_notification',
      '🧪 Test Notifikacija',
      'Ovo je test poruka. Ako vidite ovu notifikaciju, sistem radi!'
    );

    RAISE NOTICE 'Test notifikacija kreirana za korisnika: %', test_user_id;
  ELSE
    RAISE WARNING 'Nema korisnika sa registrovanim tokenom. Prvo musites da se prijave korisnici.';
  END IF;
END $$;

-- Prikaži sve registrovane tokene
SELECT
  user_id,
  platform,
  LEFT(token, 30) || '...' as token_preview,
  COUNT(*) OVER (PARTITION BY user_id) as tokens_per_user
FROM user_push_tokens
LIMIT 10;
