# packages — thin wrappers, no compilation

One directory per package, each a `PKGBUILD`. The rule for every one of them:
**download an upstream tree at a pinned commit, install its files, compile
nothing.**

## The set

- `halcora-lookandfeel-win` — **written, never built.** Wraps `Fluent-kde`: its
  Plasma desktop theme, Aurorae decoration, Kvantum style and wallpapers,
  installed as the Global Theme `org.halcora.lookandfeel.win`.
- `halcora-lookandfeel-macos` — **written, never built.** Wraps `WhiteSur-kde`
  the same way, installed as `org.halcora.lookandfeel.macos`.
- `halcora-icons-fluent` — **written, never built.** Fluent's icon theme, so the
  Windows layout's Global Theme stops naming an icon theme that does not exist
  (`Theme=Fluent-dark` in its `contents/defaults`). Upstream's installer builds
  three visible themes on top of hidden `.Fluent*-base` directories joined by
  relative symlinks; `cp -a` preserves those, and copying only the visible
  directories would leave every link broken.
- `halcora-icons-whitesur` — **written, never built.** The same for the macOS
  layout (`Theme=WhiteSur-dark`). It passes upstream's `-p` flag
  unconditionally, which swaps its Apple-logo icon for the KDE Plasma one —
  without it the tree contains Apple's mark. `docs/LEGAL.md` treats that flag as
  load-bearing, not cosmetic.
- `halcora-theme-hyperos` — **palette and window decoration written, style not.**
  Two colour schemes, light and dark, authored by hand from a first approximation
  of HyperOS (not device-sampled — see the header in each file), plus an Aurorae
  window decoration recoloured from Fluent's. The literals for that were read from
  upstream's own `close.svg`, so it is evidence rather than a guess. The Plasma
  style and Kvantum style that ADR-4 also describes are still to come: a desktop
  wearing these colours still has Fluent's or Breeze's shapes in its panels and
  menus.
- `halcora-fonts` — **probably unnecessary.** Inter (OFL-1.1), and nothing else;
  MiSans is never packaged. But `inter-font` is already an Arch package and is
  already in `iso/profile/packages.x86_64`, so a wrapper would be a dependency
  with our name on it and nothing else. Delete this entry rather than write it
  unless a real reason appears.
- `halcora-branding` — **written, never built, not wired in.** `os-release`, a
  Calamares branding directory with a placeholder mark, two authored vector
  wallpapers, and the store's featured listing. `settings.conf` still says
  `branding: default` on purpose: changing what the installer looks like before
  the first boot test would blur that test's result, and installing this package
  would also change `/etc/os-release`.

  **No Plymouth splash, deliberately.** One was written and then deleted: a
  splash theme is boot-critical — a mistake is a black screen where a boot message
  should be — and Plymouth's script API is not something that can be got right
  without watching it boot once. Writing it blind would have been the one place in
  this repository where an unverified guess could cost a machine its ability to
  report an error.
- `halcora-cursors-whitesur` — **written, never built.** The only package here
  that compiles anything: upstream has no install script, only a `build.sh` that
  rasterises SVGs with `rsvg-convert` and packs them with `xcursorgen`. Upstream's
  script is reimplemented rather than called, because it clones an unpinned
  helper repository and `sudo`-installs missing tools.
- `halcora-defaults` — **written, never built.** `/etc/skel/.config/kdeglobals`
  with two keys and no more: the HyperOS colour scheme (because the layout
  packages carry no palette), and double-click, stated explicitly because it is
  the first thing a Windows user notices going wrong. A bigger skel is a bigger
  thing to keep in step with Plasma.
- `halcora-layout` — **written, never built.** Installs `scripts/halcora-layout`
  to `/usr/bin`, and depends on both layout packages: a switcher offering one
  choice is not a switcher. Its launcher entry is deliberately absent until the
  first-run wizard (TASK-7) can offer it, because an icon that prints to a
  terminal nobody opened is not a feature.
- `halcora-first-run` — **written, never built.** One dialog at first login:
  Windows layout or macOS layout, then an offer to open Xiaomi's page for MiSans.
  Writes a marker before asking, because being asked again at every login is
  worse than a question that was skipped. In `/etc/skel/.config/autostart`, so it
  is per account and the user can delete it.
- `halcora-migrate` — **written, never built.** Copies Documents, Desktop,
  Downloads, Pictures, Music and Videos from a Windows profile into
  `~/Imported from Windows`. ADR-10's rules are the whole design: mount
  read-only, refuse a volume Windows did not shut down cleanly, never write to
  the Windows side. A Calamares module wrapping it is phase 4; the script works
  on its own, which is the version that can be improved without an installer
  that has never completed an install.

## The pinning convention

`source=` names an upstream tree at a **commit**, never a branch or a tag.
`scripts/fetch-themes.sh` prints the current HEAD of each upstream so a version
bump is a copy-paste, and `pkgver` carries the date and short commit so the
built package says what it actually contains.

Two forms are allowed, and the difference is the checksum:

- **git source** — `name::git+https://…/repo.git#commit=<sha>`, with
  `sha256sums=('SKIP')`. Reproducible because the commit is pinned, and no
  checksum is required. Use this when no machine has been able to run
  `updpkgsums`.
- **archive source** — `https://…/repo/archive/<sha>.tar.gz`, with a real
  `sha256sums` entry. Lighter to download. Use this once a checksum has actually
  been computed by a machine that can compute one.

The two layout packages use the git form, because this repository is maintained
from a device with no shell: writing a checksum that nothing has verified would
be worse than not having one.

## Package ids are a contract

`scripts/halcora-layout` asks for `org.halcora.lookandfeel.win` and
`org.halcora.lookandfeel.macos`. Those ids have to exist, or the switcher does
nothing. The check workflow therefore fails when a layout id in the switcher is
produced by no package, because that mistake is invisible until a user runs the
command.

The layout packages rename upstream's Global Theme to our id rather than exposing
`com.github.vinceliuice.…` directly. That is the point of the wrapper: the layout
is ours, the theme providing it is replaceable.

## What a layout package deliberately does not own

- **The palette.** `ColorScheme=` is removed from the theme's `contents/defaults`
  (docs/DESIGN.md: the palette lives only in `halcora-theme-hyperos`). Otherwise
  switching layout would also switch light/dark.
- **Cursors.** `cursorTheme=` is removed; upstream's cursor set is not shipped.
- **Colour schemes.** Upstream's `.colors` files are not installed, for the same
  reason as the palette.
- **Icons.** Not shipped yet — the icon theme line is left in place and Plasma
  falls back to system icons. Folding `Fluent-icon-theme` and `WhiteSur-cursors`
  in is follow-up work, not a silent assumption.

## Build order

Themes first, then `halcora-branding`, then `halcora-defaults`, then
`halcora-layout`. `iso/profile/packages.x86_64` expects all of them to exist in
our repository before an image will build.

## Repository

`build.sh` builds every package into a local pacman repository: it runs
`makepkg` per directory and then `repo-add`, producing `packages/repo` with
`halcora.db` and `halcora.files` in it.

    sudo pacman -S --needed base-devel
    ./packages/build.sh

It must not run as root, because `makepkg` refuses to and the layout packages
depend on that refusal — upstream's installers write to `/usr/share` when they
think they are root.

Nothing has been run through it yet, and there is no repository in the tree for
the same reason: a repository of never-built packages would be a directory of
nothing. Pointing the ISO's `pacman.conf` at it is the next piece of phase 1.

## What has not been done

Nothing here has been built. No `makepkg` run has been attempted, in CI or
anywhere else, and there is no pacman repository to build against yet. The three
`PKGBUILD`s are written from upstream's `install.sh` — which was read, not
guessed at — but "read the installer carefully" and "the package builds" are
different claims. `docs/TASKS.md` TASK-4 says what done looks like.
