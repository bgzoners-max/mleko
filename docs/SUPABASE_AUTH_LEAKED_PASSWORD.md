# Leaked password protection (Supabase Auth)

**Lint:** „Leaked Password Protection Disabled“ — Supabase može da odbije lozinke koje se pojavljuju u poznatim curenjima (Have I Been Pwned).

## Brzo rešenje (preporuka)

1. **Supabase Dashboard** → **Authentication** → **Providers** / **Settings** (zavisi od UI verzije).
2. Pronađi **Password** / **Password policy** / **Security**.
3. Uključi opciju tipa **Prevent use of leaked passwords** / **Have I Been Pwned**.
4. Sačuvaj.

**Napomena:** Ova mogućnost je na nekim planovima vezana za **Pro** (ili viši). Na Free planu opcija možda ne postoji — tada je jedino rešenje nadogradnja plana ili prihvatanje rizika dok ne upgrade-uješ.

## Provera

- Registracija ili promena lozinke sa poznato slabom / curenom lozinkom (npr. `password123`) treba da **padne** sa jasnom porukom.

## Management API (opciono)

Ako želiš automatizaciju, prvo **GET** trenutnog oblika podešavanja:

```bash
curl -sS -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  "https://api.supabase.com/v1/projects/$PROJECT_REF/auth"
```

Odgovor poseti [Supabase Management API](https://supabase.com/docs/reference/api/introduction) ili podršci — tačan ključ u JSON-u za „leaked passwords“ može varirati; **PATCH** telo mora da prati oblik koji vrati **GET**, ne generički npr. `password_policy.prevent_leaked_passwords` osim ako GET to potvrdi.

Na Windows PowerShell:

```powershell
$env:SUPABASE_ACCESS_TOKEN = "<token>"
$env:PROJECT_REF = "<ref>"
curl.exe -sS -H "Authorization: Bearer $($env:SUPABASE_ACCESS_TOKEN)" `
  "https://api.supabase.com/v1/projects/$($env:PROJECT_REF)/auth"
```

## Dodatno (UX)

- U Flutter/web prikaži poruku korisniku kada Auth vrati grešku za slabu/curenu lozinku (mapiranje `AuthApiException` / poruke sa backenda).
