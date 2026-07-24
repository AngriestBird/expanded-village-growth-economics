# Agent notes for this repo

- This is an OpenTTD GameScript project written in Squirrel (`.nut`).

## Repo map

- `main.nut`: loader that boots the script from `src/main.nut`
- `info.nut`: script registration metadata (`desc`, supported versions, deps); must stay at the repo root or OpenTTD won't load the script
- `src/cargo.nut`: cargo handling and category mapping
- `src/industry.nut`: industry discovery and utility
- `src/town.nut`: town growth core logic
- `src/company.nut`: company-related logic
- `src/subsidies.nut`: subsidy generation
- `src/taxes.nut`: infrastructure tax feature
- `src/story.nut`: StoryBook pages and intro text
- `src/strings.nut`: localized string IDs and settings labels
- `src/version.nut`: version and save compatibility numbers
- `lang/`: translation files
- `tools/check_lang.py`: translation validator
- `make_tar.py`: packaging script for release tarballs

## Common workflow

- For language changes, edit `lang/english.txt` first and keep other languages aligned by key.
- Do not hand-edit generated or ignored artifacts (`*.tar`).
- The manual lives in `readme.txt` only. The Pages workflow generates `docs/src/pages/readme.md` from it at deploy; do not create or hand-edit that file.
- Keep changes minimal and scoped to the requested behavior.

## Website and docs iteration

- The docs site now uses Astro + Bun in `docs/`.
- Website docs are in `docs/` and published via `.github/workflows/pages.yml`.
- The manual for the website is generated from `readme.txt` into `docs/src/pages/readme.md` during deployment.
- Visual updates should be made through Astro docs files in `docs/src/layouts`, `docs/src/styles`, and `docs/astro.config.mjs`, while content updates live in `docs/src/pages/`.
- Use a standard, readable palette for UI updates before introducing custom color systems.
- Keep website/UX work on a dedicated branch so it does not mix with gameplay logic changes.

## Validation

Run before finishing:

```bash
python3 tools/check_lang.py
python3 make_tar.py
```

CI runs both steps on push/PR.

## Version/release notes

- Bump `src/version.nut` before release work; keep `readme.txt`/`changelog.txt` and packaged version references consistent with it.
