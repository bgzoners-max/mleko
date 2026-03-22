# Flutter Web Rebuild + UI Fixes ✓

Current working directory: c:/dev/mleko

## Steps
- ✅ Rebuild web & preview in Chrome running (http://127.0.0.1:54346/...)
- ✅ 1. Fixed OfflineIndicator: Added Directionality ltr → no crash on web
- ✅ 2. Reordered home_screen.dart: HeroCard (\"Direktno sa gazdinstva...\") + search now first (after sticky header), categories section moved below
- ✅ Test: Hot reload applied, check Chrome preview (search prominent at top)

## Result
Web app rebuilt, preview live in Chrome, UI updated per request (search/gazdinstva first), offline bug fixed.

Notes:
- HeroCard text \"Direktno sa gazdinstva do vašeg stola\" matches \"Od gazdinstva...\".
- Live reload working; changes instant.
- Original task + UI feedback complete.

Enjoy the preview!

---

## CupertinoPicker for Kategorija [IN PROGRESS]

### Steps:
- [x] Backup to GitHub PR #1 (https://github.com/bgzoners-max/mleko/pull/1) ✓
- [x] Created lib/widgets/cupertino_category_picker.dart ✓
- [x] Edited lib/screens/seller/add_edit_product_screen.dart (replaced fallback dropdown with picker) ✓
- [ ] Test: Hot reload (`r`), verify in preview
- [ ] Mark complete, commit, gh pr create
- [ ] Cleanup (update TODO.md)
