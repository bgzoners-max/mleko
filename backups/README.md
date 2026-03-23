# Rezervne kopije projekta Mleko

Fajlovi ovde su generisani ručno / skriptom; **ne commit-uj** velike `.bundle` / `.zip` u git ako su u `.gitignore`.

## `mleko-full-*.bundle`

- **Šta je:** ceo Git repozitorijum (sve grane i istorija) u jednom fajlu.
- **Vraćanje kloniranjem:**
  ```bash
  git clone mleko-full-YYYYMMDD-HHMMSS.bundle mleko-restored
  cd mleko-restored
  git checkout main   # ili master, zavisno od grane
  ```
- **Ili** otvori bundle kao remote:
  ```bash
  git pull /putanja/do/mleko-full-*.bundle
  ```

## `mleko-src-HEAD-*.zip`

- **Šta je:** snimak **samo commit-ovanih** fajlova na trenutnom `HEAD` (bez necommit-ovanih izmena).
- Koristi za brz pregled ili deploy snapshota; za punu istoriju koristi `.bundle`.

## Šta backup *ne* uključuje

- Necommit-ovane izmene u radnom direktorijumu — uradi `git status`; ako ima važnog, prvo **commit** pa ponovo napravi bundle.
- `build/`, `.dart_tool/`, `node_modules/` — generišu se ponovo (`flutter pub get`, itd.).

## Preporuka

- Drži kopiju `.bundle` na drugom disku / oblaku (OneDrive, USB, …).
- Periodično: `git bundle create backups/mleko-full-$(date +%Y%m%d).bundle --all`
