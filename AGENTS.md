# Agent notes for this repo

- This is an OpenTTD GameScript project written in Squirrel (`.nut`).

## Repo map

- `main.nut`: game-script entry and wiring
- `cargo.nut`: cargo handling and category mapping
- `industry.nut`: industry discovery and utility
- `town.nut`: town growth core logic
- `company.nut`: company-related logic
- `subsidies.nut`: subsidy generation
- `taxes.nut`: infrastructure tax feature
- `story.nut`: StoryBook pages and intro text
- `strings.nut`: localized string IDs and settings labels
- `info.nut`: metadata for NewGRF metadata (`desc`, supported versions, deps)
- `version.nut`: version and save compatibility numbers
- `lang/`: translation files
- `tools/check_lang.py`: translation validator
- `make_tar.py`: packaging script for release tarballs

## Common workflow

- For language changes, edit `lang/english.txt` first and keep other languages aligned by key.
- Do not hand-edit generated or ignored artifacts (`*.tar`).
- The manual lives in `readme.txt` only. The Pages workflow generates `docs/readme.md` from it at deploy; do not create or edit that file by hand.
- Keep changes minimal and scoped to the requested behavior.

## Validation

Run before finishing:

```bash
python3 tools/check_lang.py
python3 make_tar.py
```

CI runs both steps on push/PR.

## Version/release notes

- Bump `version.nut` before release work; keep `readme.txt`/`changelog.txt` and packaged version references consistent with it.
