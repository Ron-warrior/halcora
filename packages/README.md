# packages — thin wrappers, no compilation

One directory per package, each a `PKGBUILD`. The rule for every one of them:
**download an upstream tree at a pinned commit, install its files, compile
nothing.**

## The set

- `tessera-lookandfeel-win` — the Windows layout. Wraps `Fluent-kde`:
  its Plasma global theme, Aurorae decoration, Kvantum style and colour schemes,
  plus `Fluent-icon-theme` and a cursor set, installed as
  `org.tessera.lookandfeel.win`.
- `tessera-lookandfeel-macos` — the macOS layout. Wraps `WhiteSur-kde` the same
  way, plus `WhiteSur-icon-theme`, `WhiteSur-cursors`, and optionally
  `WhiteSur-gtk-theme`, installed as `org.tessera.lookandfeel.macos`.
- `tessera-theme-hyperos` — the authored skin, worn by both layouts. Plasma
  style, colour schemes (light and dark), Aurorae decoration, Kvantum style,
  Inter references. Derived from `Fluent-kde`, so GPL-3.0 (ADR-4).
- `tessera-fonts` — Inter (OFL-1.1). Nothing else. MiSans is never packaged.
- `tessera-branding` — os-release, Plymouth, SDDM theme, Calamares branding,
  wallpapers (our own, not Xiaomi's).
- `tessera-defaults` — `/etc/skel`: Plasma defaults, window rules, the
  deliberately-untouched keybinds, first-run state.
- `tessera-layout` — installs `scripts/tessera-layout` to `/usr/local/bin` plus
  a `.desktop` entry in Settings.
- `tessera-migrate` — the Windows import tool and its Calamares module
  (phase 4).

## The pinning convention

`source=` points at `https://github.com/<owner>/<repo>/archive/<commit>.tar.gz`,
never at a branch or a tag. `scripts/fetch-themes.sh` prints the current HEAD of
each upstream so a version bump is a copy-paste, and `pkgver` carries the short
commit so the built package says what it actually contains.

This is AnduinOS's technique, adopted wholesale because it is correct: a package
that tracks a branch breaks its own reproducibility, and upstream themes are
actively developed (all of the ones we use were pushed within months of this
being written).

## Build order

Themes first, then `tessera-branding`, then `tessera-defaults`, then
`tessera-layout`. `iso/profile/packages.x86_64` expects all of them plus
`tessera-theme-hyperos` to exist in our repository before an image will build.

## Repository

A local pacman repository, built with `repo-add`, served over HTTP or from a
mounted path. Not yet set up; standing it up is the last step of phase 1.

## Not yet written

Every `PKGBUILD`. They are the next real artefact after Phase 0's design verdict,
and they are deliberately not guessed at here — the install step of each upstream
theme (`install.sh` conventions, which subdirectories to keep) has to be read
from the source rather than assumed. See `docs/ROADMAP.md`, phase 1.
