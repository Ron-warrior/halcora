# Borrow ledger

Every borrowed component, what it gives us, its license, and how it is pinned.
The pinning rule is the AnduinOS one: **never track a branch, always a commit.**
`scripts/fetch-themes.sh` resolves the current HEADs so a package can pin one.

## Themes — the bulk of the product

- **`vinceliuice/Fluent-kde`** — GPL-3.0. Windows-11 "Fluent" Plasma theme:
  Aurorae window decoration, Kvantum style, Plasma global theme, colour schemes.
  Gives us the entire Windows layout. Also our **starting point for the HyperOS
  skin**, because Fluent's geometry (soft rounded rectangles, centred, generous
  padding) is the closest Plasma work to HyperOS that exists.
- **`vinceliuice/Fluent-icon-theme`** — GPL-3.0. Icon set for the Windows layout.
- **`vinceliuice/WhiteSur-kde`** — GPL-3.0. macOS Big Sur Plasma theme. Ships a
  Plasma global theme, desktop theme, Aurorae decoration, Kvantum style, colour
  schemes, and both `metadata.desktop` and Plasma-6 `metadata.json`. Gives us
  the entire macOS layout. Also the reference for glass/blur SVG scaffolding
  when we build the HyperOS decoration.
- **`vinceliuice/WhiteSur-icon-theme`** — GPL-3.0. Icons for the macOS layout.
- **`vinceliuice/WhiteSur-cursors`** — cursor set for the macOS layout.
  License not yet checked; verify before packaging.
- **`vinceliuice/WhiteSur-gtk-theme`** — MIT. Makes GTK apps stop looking out of
  place under the macOS layout. Optional, but cheap and it closes a visible gap.

## Fonts

- **`rsms/inter`** — SIL OFL-1.1. Our default UI face in every layout. OFL
  permits redistribution with the license text; do not rename it.
- **MiSans (Xiaomi)** — **not redistributable.** See `LEGAL.md`. Offered as an
  optional first-run download only.

## Distribution plumbing

- **`archlinux/archiso`** (package `archiso`, v92) — GPL-3.0. Live ISO tooling.
  We copy `configs/releng` and change only `profiledef.sh`, `packages.x86_64`,
  `pacman.conf`, `airootfs/` and boot entries.
- **`arch-linux-calamares-installer/alci-iso`** — the least-fork
  archiso+Calamares profile: stock Arch, stock-ish Calamares, no custom modules.
  Copy the configuration shape. Caveat: the ArcoLinux team is winding down and
  it is no longer maintained, so treat it as a template, not a dependency.
- **`endeavouros-team/calamares`**, directory `data/eos` — GPL-3.0. A complete
  `/etc/calamares` tree: branding, 32 module configs, `netinstall.yaml`,
  `packagechooser.conf`, bootloader and windows-boot-entry configs, QML
  slideshow. The single most complete thing to lift. Caveat: it calls modules
  that only exist in EndeavourOS's Calamares fork (`eos_pacman`, `eos_script`,
  `eos_bootloader`, `hardwaredetect`, `usersq`, `packagechooserq`,
  `windowsbootentry`, `dracutlukscfg`) — either build their fork or strip those
  modules and keep stock ones. This is an open decision; see `DECISIONS.md`
  ADR-7.
- **`CachyOS/cachyos-calamares`** — GPL-3.0. Another reference; its config is
  split between `settings*.conf` and per-module dirs, so it is less liftable
  than `data/eos`.

## Drivers and hardware

- **`CachyOS/chwd`** — GPL-3.0, Rust. GPU/device profile detection; run at
  install time to pull the right driver packages. Ships profiles for
  `nvidia-open-dkms`, `nvidia-dkms-580xx`, `nouveau`, Intel, AMD, Mac T2,
  handhelds, VMs. Run `chwd -a` from the installer. Also packaged standalone
  for plain Arch, which is why we prefer it over EndeavourOS's `nvidia-inst`
  (GPL-2.0) — either is acceptable if `chwd` proves awkward.
- **NVIDIA:** Turing (RTX 2060) is supported by `nvidia-open*` and by NVIDIA's
  recommendation. `nvidia-utils` has enabled `nvidia_drm.modeset=1` by default
  since 560.35.03-5.
- **`ntfs3`** — in-kernel, read/write, but **no fsck**. `udisks` prefers it, so
  auto-mount is already correct. Dirty volumes (Windows Fast Startup) refuse to
  mount without `force`; recovery is `ntfsfix --clear-dirty`. Never force.

## Store

- **KDE Discover** + `flatpak` + `packagekit-qt6` (which pulls `packagekit` and
  its real `libpk_backend_alpm.so` pacman backend). `appstream-qt` and
  `archlinux-appstream-data` arrive as hard dependencies.
- **Curated storefront, zero code:** `/usr/share/discover/featuredurlrc` with
  `[Software] FeaturedListingURL=` pointing at our own JSON. Schema reference:
  `https://autoconfig.kde.org/discover/featured-5.9.json`.

## Migration

- **`jackjumpinc/migratepc`** — a fork of Mint/Ubuntu's Ubiquity installer that
  copies Windows user files with rsync and reconfigures browsers post-install.
  GPL, and it targets Ubiquity rather than Calamares, so it cannot be dropped in
  — but its **rsync file lists and post-install browser steps are directly
  reusable** and are the only part we want.
- No existing open-source tool imports a Windows user (browser profiles,
  documents, wallpaper) into a Calamares-installed Arch system. This is the one
  piece of real work with no upstream to lean on.

## Reference implementations, not dependencies

- **`AiursoftWeb/AnduinOS-2`** and **`AnduinOS-Packages`** — GPL-3.0. A
  Windows-11-look Ubuntu distro doing exactly our trick, in the other desktop.
  Steal their *techniques*, not their code: pinned upstream themes repackaged as
  packages rather than forked, dconf/gsettings defaults as a package, and an
  appearance switcher (`src/anduinos_appearance/profiles.py`, `layout.py`) with
  named layout profiles. On Plasma we get the equivalent for free from Global
  Themes, which is the point.
- **`iijawadm/hyperos-theme`** — GNOME, no top-level license, 15 stars, assets
  under vague "original authors' licenses". **Reference for the look only.**
  Do not copy files or assets; the repo also ships MiSans, which is not ours to
  redistribute.
- **`neuromorph/openbar`** — GPL-3.0 GNOME extension with a HyperOS preset.
  Useful as a second opinion on HyperOS's top-bar geometry. Not portable.

## What genuinely has no upstream, and must be authored

1. `halcora-theme-hyperos` — no HyperOS global theme exists for KDE Plasma. The
   KDE Store and GitHub contain only Android theme packages and one unlicensed
   GNOME bundle. We build it, lazily, by recolouring Fluent-kde.
2. Wallpapers — Xiaomi's are not ours. We author our own in the same idiom.
3. `halcora-migrate` — the Windows import flow, reusing migratepc's lists.


## Pinned upstream commits

`packages/README.md` explains why every pin is a commit rather than a branch or
a tag. The current pins:

- `vinceliuice/Fluent-kde` — `44794f29c89de994b0179aebabd2f5776c90d236` (2025-11-10)
- `vinceliuice/WhiteSur-kde` — `cf4df59ce91004f7ea39358b1b8ff917d5c329f7` (2026-08-07)
- `vinceliuice/Fluent-icon-theme` — `c8a244f571ef8fb47812bdc9dbce76546cedce69` (2026-08-30)
- `vinceliuice/WhiteSur-icon-theme` — `73d8040da51a9ed74e47c7366e7e9ff437601a5c` (2026-09-10)
- `vinceliuice/WhiteSur-cursors` — `e190baf618ed95ee217d2fd45589bd309b37672b` (2025-04-05), **not packaged**: it generates cursors with `xcursorgen` and clones an unpinned helper repository at build time, so it is a real build rather than a wrapper

`scripts/fetch-themes.sh` prints the current HEAD of each, so a bump is a
copy-paste into `source=` **and** `pkgver` — never one without the other.
