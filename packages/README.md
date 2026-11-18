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
- `halcora-theme-hyperos` — **palette written, style not.** Two colour schemes,
  light and dark, authored by hand from a first approximation of HyperOS (not
  device-sampled — see the header in each file). The Plasma style, Aurorae
  decoration and Kvantum style that ADR-4 describes are still to come: a desktop
  wearing these colours has Fluent's or Breeze's shapes, not HyperOS's. That
  distinction is the honest state of "the HyperOS theme" and should stay in the
  docs until the shapes exist.
- `halcora-fonts` — **probably unnecessary.** Inter (OFL-1.1), and nothing else;
  MiSans is never packaged. But `inter-font` is already an Arch package and is
  already in `iso/profile/packages.x86_64`, so a wrapper would be a dependency
  with our name on it and nothing else. Delete this entry rather than write it
  unless a real reason appears.
- `halcora-branding` — **written, never built, not wired in.** `os-release` and
  a Calamares branding directory with a placeholder mark. `settings.conf` still
  says `branding: default` on purpose: changing what the installer looks like
  before the first boot test would blur that test's result.
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
- `halcora-migrate` — the Windows import tool and its Calamares module
  (phase 4). **Not written.**

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
