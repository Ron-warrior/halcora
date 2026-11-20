# Architecture

Four layers. The rule is that we own as little as possible of layer 0, and every
piece of layer 3 must justify its existence against something that already works.

## Layer 0 — Upstream that we do not touch

- **Base system** — Arch Linux. Consumed, never forked.
- **Package manager** — pacman / makepkg. We add a repository; we do not change
  the tool.
- **Desktop shell** — KDE Plasma 6. We add packages; we do not write QML.
- **Installer** — **ours.** `iso/overlay/usr/local/bin/halcora-install`, a shell
  script over the Arch base tools. See ADR-17. This is the first component this
  project has taken back from upstream.
- **Live image** — archiso. Profile only, `mkarchiso` unmodified.
- **App store** — KDE Discover + Flatpak. Configuration only.
- **GPU detection** — `chwd`, when it is used. Not currently called at all: it is
  not in any pacman repository, the installer is offline, and ADR-16 records the
  three ways to resolve that. Until one is chosen, no driver is installed
  automatically.
- **Applications** — Dolphin, Kate, Firefox, Konsole and the rest. Shipped as
  they are.

## Layer 1 — Distribution configuration

Everything in `iso/profile/` is an archiso profile: naming, the package list,
`pacman.conf` (pointing at Arch, plus our own repository when `HALCORA_REPO` is
set), and an `airootfs` overlay that drops files into the live system before
packaging (os-release, skel files, enabled systemd units, the Discover
featured-listing config, Calamares config and its launcher, the polkit rule that
lets the live account run the installer).

Derived from the archiso `releng` profile. `mkarchiso` itself is never edited.

## Layer 2 — Packages we publish

Thin pacman packages. None of them compile anything; each downloads an upstream
tree at a pinned commit and installs its files, or installs files that are
already in this repository.

**Status:** every package in this layer exists as a recipe on `main`, and none of
them has ever been built.

- `halcora-lookandfeel-win` — Windows layout, wrapping `Fluent-kde`. Renamed to
  `org.halcora.lookandfeel.win` so the switcher names a layout, not an author.
- `halcora-lookandfeel-macos` — macOS layout, wrapping `WhiteSur-kde`.
- `halcora-layout` — installs `scripts/halcora-layout`; depends on both layouts.
- `halcora-theme-hyperos` — **the half of the design we author that exists.**
  Two colour schemes, a recoloured Aurorae decoration and a recoloured Kvantum
  configuration, all hand-written from upstream values that were read rather than
  guessed. The Plasma style — the shapes of panels and menus — is still Fluent's:
  its files are gzipped, so recolouring it needs a machine that can decompress
  them.
- `halcora-branding` — `os-release` and Calamares branding, with a placeholder
  mark. Deliberately not wired into `settings.conf` yet.
- `halcora-defaults` — `/etc/skel/.config/kdeglobals`, five lines: the HyperOS
  palette as the system default, and double-click.
- `halcora-icons-fluent`, `halcora-icons-whitesur` — the icon themes the two
  layouts' Global Themes name. Both written, neither built. Cursors are not
  packaged: generating them needs `xcursorgen` and a build-time clone of an
  unpinned helper repository, so they are a build rather than a wrapper.
- `halcora-migrate` — the Windows import tool. See below. Not written.

## Layer 3 — Glue we actually write

This should stay small. If it grows past a few hundred lines outside
`halcora-theme-hyperos` and `halcora-migrate`, something is wrong.

- `scripts/halcora-layout` — the layout switcher. Two ids, one
  `plasma-apply-lookandfeel` call, one KWin reconfigure.
- `scripts/fetch-themes.sh` — resolves upstream commits so packages pin rather
  than track. Build-time only, never shipped.
- `halcora-migrate` — a Calamares module plus an import script. Mounts the
  Windows volume **read-only**, refuses dirty volumes rather than forcing them
  (Fast Startup leaves them dirty and `ntfs3` has no fsck), copies user data
  from a fixed list of six folders, and defers browser profile import to the
  browsers' own first-run importers. The script exists and works alone; the
  Calamares module around it does not. No code is lifted from `migratepc` —
  what was borrowed is the read-only discipline, not its file lists.

## Deliberate absences

- **No custom compositor or shell.** Plasma's shell is already replaceable at
  the theme layer, which is where all three of our visual targets live.
- **No musl.** The NVIDIA proprietary userspace is glibc-only, and this project
  targets NVIDIA hardware. Closed by ADR-1.
- **No custom store.** Discover plus a featured-listing JSON is a curated store.
- **No custom installer.** Calamares plus branding.
- **No i18n.** English only.

## The test loop

- **Skin judgement** happens on bare metal, on the target machine. Blur-heavy
  UI in a VM on virtio-gpu misrepresents the design.
- **Image and installer** are tested in QEMU (`run_archiso -i`, or `mkosi vm`
  for quick rootfs iteration).
- **GPU-accelerated paths cannot be tested in the VM.** The i7-10700F has no
  integrated GPU, so passing the RTX 2060 through leaves the host with no
  display. Graphics is native-only.
