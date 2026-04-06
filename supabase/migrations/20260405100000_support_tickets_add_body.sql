-- Dodaj body kolonu ako ne postoji (fix za tabelu kreiranu bez nje)
ALTER TABLE support_tickets ADD COLUMN IF NOT EXISTS body text;

-- Postavi CHECK constraint ako ne postoji
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.constraint_column_usage
    WHERE table_name = 'support_tickets' AND column_name = 'body'
  ) THEN
    ALTER TABLE support_tickets ADD CONSTRAINT support_tickets_body_length
      CHECK (char_length(body) BETWEEN 10 AND 5000);
  END IF;
END
$$;
