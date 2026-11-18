# Architecture

Four layers. The rule is that we own as little as possible of layer 0, and every
piece of layer 3 must justify its existence against something that already works.

## Layer 0 — Upstream that we do not touch

- **Base system** — Arch Linux. Consumed, never forked.
- **Package manager** — pacman / makepkg. We add a repository; we do not change
  the tool.
- **Desktop shell** — KDE Plasma 6. We add packages; we do not write QML.
- **Installer** — Calamares. Configuration only.
- **Live image** — archiso. Profile only, `mkarchiso` unmodified.
- **App store** — KDE Discover + Flatpak. Configuration only.
- **GPU detection** — `chwd`. Called, not modified.
- **Applications** — Dolphin, Kate, Firefox, Konsole and the rest. Shipped as
  they are.

## Layer 1 — Distribution configuration

Everything in `iso/profile/` is an archiso profile: naming, the package list,
`pacman.conf` pointing at Arch plus our own repo, and an `airootfs` overlay that
drops files into the live system before packaging (os-release, skel files,
enabled systemd units, the Discover featured-listing config, Calamares config).

Derived from the archiso `releng` profile. `mkarchiso` itself is never edited.

## Layer 2 — Packages we publish

Thin pacman packages. None of them compile anything; each downloads an upstream
tree at a pinned commit and installs its files.

- `tessera-lookandfeel-win` — the Windows layout. Wraps `Fluent-kde`.
- `tessera-lookandfeel-macos` — the macOS layout. Wraps `WhiteSur-kde`.
- `tessera-icons-*`, `tessera-cursors-*` — Fluent and WhiteSur icon and cursor
  sets, repackaged so a layout switch never leaves a mismatched icon set.
- `tessera-theme-hyperos` — **the only theme we author.** Forked from
  Fluent-kde's geometry, recoloured to the HyperOS palette, Inter as the UI
  face, our own wallpapers. See `DESIGN.md`.
- `tessera-fonts` — Inter (OFL-1.1). MiSans is *not* included; see `LEGAL.md`.
- `tessera-branding` — os-release, Plymouth splash, SDDM theme, Calamares
  branding, wallpaper set.
- `tessera-defaults` — `/etc/skel`: Plasma defaults, window rules, keybinds we
  deliberately leave alone, first-run state.
- `tessera-migrate` — the Windows import tool. See below.

## Layer 3 — Glue we actually write

This should stay small. If it grows past a few hundred lines outside
`tessera-theme-hyperos` and `tessera-migrate`, something is wrong.

- `scripts/tessera-layout` — the layout switcher. Two ids, one
  `plasma-apply-lookandfeel` call, one KWin reconfigure.
- `scripts/fetch-themes.sh` — resolves upstream commits so packages pin rather
  than track. Build-time only, never shipped.
- `tessera-migrate` — a Calamares module plus an import script. Mounts the
  Windows volume **read-only**, refuses dirty volumes rather than forcing them
  (Fast Startup leaves them dirty and `ntfs3` has no fsck), copies user data
  from a list, and defers browser profile import to the browsers' own first-run
  importers. The rsync lists are lifted from `jackjumpinc/migratepc`.

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
