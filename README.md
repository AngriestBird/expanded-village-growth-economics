# Expanded Village Growth + Economics (EVGE)

![Expanded Village Growth + Economics](https://i.imgur.com/37J9Kn4.png)

EVGE replaces default OpenTTD growth with a cargo-based model.
Towns start being managed once they export passengers, then they need the right mix of cargo to keep growing.
This makes local industry and route planning matter much more than just population pumping.

## Documentation and player notes

- Docs site: <https://angriestbird.github.io/expanded-village-growth-economics/>
- GitHub: <https://github.com/AngriestBird/expanded-village-growth-economics>
- Forum topic: <https://www.tt-forums.net/viewtopic.php?f=65&t=87052>
- BaNaNaS: <https://bananas.openttd.org/package/game-script/52455649>

## Quick links

- [Full manual](readme.txt)
- [GitHub Pages documentation](https://angriestbird.github.io/expanded-village-growth-economics/)
- [How town growth works](docs/town-growth.md)
- [Goal stat guide](docs/goal-stats.md)
- [Settings playbook](docs/settings-guide.md)

## Project layout

- `main.nut` is a loader that boots the actual script from `src/main.nut`.
- Core GameScript logic now lives under `src/` (for example, `src/town.nut`, `src/cargo.nut`, `src/info.nut`).

## Requirements

- OpenTTD 14.x or newer.
- GS SuperLib v. 40, ToyLib v. 2, Script Communication for GS v. 45 (also available through OTTD Online Content).
- Industry sets: most common NewGRFs are supported, from base sets to FIRS, ECS, YETI, NAIS, FIRS Forked, and more.
  - unsupported sets still work with generated category fallbacks.

## Testing your build

Build and install quickly on Linux with:

```bash
python3 make_tar.py --install
```

## Translations

Available languages:

- English
- French
- Slovak
- Czech
- Simplified Chinese
- Polish
- Galician
- German
- Japanese
- Traditional Chinese
- Russian
- Ukrainian

To update translation text, edit `lang/english.txt` and sync matching placeholders in the other language files.

## License

Expanded Village Growth + Economics is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, version 2 of the License
(see file license.txt).

## Credits

See [CREDITS.md](CREDITS.md).
