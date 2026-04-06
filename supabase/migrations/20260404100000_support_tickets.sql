-- Support tickets: korisnici šalju tikete adminu
CREATE SEQUENCE IF NOT EXISTS support_ticket_seq START 1;

CREATE TABLE IF NOT EXISTS support_tickets (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_number   text        UNIQUE NOT NULL
                              DEFAULT 'MLK-' || to_char(now(), 'YYYY') || '-' || lpad(nextval('support_ticket_seq')::text, 5, '0'),
  user_id         uuid        REFERENCES auth.users(id) ON DELETE SET NULL,
  user_email      text,
  user_name       text,
  category        text        NOT NULL CHECK (category IN ('bug', 'pitanje', 'sugestija', 'ostalo')),
  subject         text        NOT NULL CHECK (char_length(subject) BETWEEN 5 AND 150),
  body            text        NOT NULL CHECK (char_length(body) BETWEEN 10 AND 5000),
  status          text        NOT NULL DEFAULT 'otvoren'
                              CHECK (status IN ('otvoren', 'u_obradi', 'zatvoren')),
  admin_note      text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

-- Automatski updated_at
CREATE OR REPLACE FUNCTION update_support_ticket_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS trg_support_tickets_updated_at ON support_tickets;
CREATE TRIGGER trg_support_tickets_updated_at
  BEFORE UPDATE ON support_tickets
  FOR EACH ROW EXECUTE FUNCTION update_support_ticket_updated_at();

-- RLS
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

-- Korisnik može da ubaci vlastiti tiket
DROP POLICY IF EXISTS "insert_own_ticket" ON support_tickets;
CREATE POLICY "insert_own_ticket" ON support_tickets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Korisnik može da čita vlastite tikete
DROP POLICY IF EXISTS "select_own_tickets" ON support_tickets;
CREATE POLICY "select_own_tickets" ON support_tickets
  FOR SELECT USING (auth.uid() = user_id);

-- Indeksi
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_created_at ON support_tickets(created_at DESC);
