-- ============================================================================
-- NOTE: Ovo je JEDNOKRATNI podatkovni „data fix" (ne šema!) koji podešava
-- edge_config za produkciju. `anon_key` u Supabase-uz je PUBLIKOVAN ključ (ide
-- direktno u web klijent), pa njegovo prisustvo u repozitorijumu NIJE curenje
-- tajne — ali je održavanje čistije ako se buduće promene konfiguracije rade
-- kroz Dashboard/seed umesto kroz migraciju koja se izvršava i lokalno.
-- Migraciju NE BRISATI (Supabase prati primenjene migracije po nazivu fajla).
-- ============================================================================
-- Updateuj Edge Config za produkciju - ispravka push notifikacija
UPDATE public.edge_config
SET value = 'https://wvqtujpurhzraptorcvl.supabase.co'
WHERE key = 'functions_base_url';

-- Edge Function verify_jwt=true zahteva pravi JWT ključ, ne publishable format
UPDATE public.edge_config
SET value = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2cXR1anB1cmh6cmFwdG9yY3ZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIwODEyNDEsImV4cCI6MjA4NzY1NzI0MX0.UcZtf4geUoMJXCk3Ma87481XDQ_2plQvgWZKXxLA8ns'
WHERE key = 'anon_key';
