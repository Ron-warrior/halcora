# Legal

Three prohibitions, one licensing note, one naming rule. This file exists so
nobody re-derives it under deadline pressure.

## Do not redistribute

1. **Microsoft assets.** No Windows wallpapers, icons, sounds, logos, font files
   or UI artwork. No "Windows" in the product name, the ISO label, the package
   names or the marketing. Interaction patterns are free to copy; assets and
   marks are not. The cautionary example is Wubuntu, a distribution that dressed
   itself in Windows' identity, promised `.exe` support, and ended up with
   trademark complaints and no credibility.
2. **Apple assets.** No SF Pro, no SF Symbols. Apple licenses both for designing
   Apple-platform software only. The macOS layout must be built from Inter and a
   free icon set, and it must not be advertised as macOS or claim compatibility
   with it.
3. **Xiaomi assets.** MiSans is licensed for commercial *use* but the licence
   expressly forbids redistributing the font files or their components. Xiaomi
   wallpapers, sounds and icons are equally not ours. MiSans is a first-run
   user-initiated download from Xiaomi and is never bundled. This is also why
   `iijawadm/hyperos-theme` is a look reference only — it ships MiSans.

The general test: **imitate the grammar, author the assets.** Layouts, spacing,
radii, motion and interaction models are conventional and unprotectable. A
specific logo, artwork, typeface file or product name is not.

## What we do redistribute, and under what terms

- **Fluent-kde, Fluent-icon-theme, WhiteSur-kde, WhiteSur-icon-theme** —
  GPL-3.0. Repackaging is fine; our modifications to them must stay GPL-3.0 and
  the source must be available. The HyperOS theme, being derived from
  Fluent-kde, is GPL-3.0.
- **WhiteSur-gtk-theme** — MIT. Attribution only.
- **WhiteSur-cursors** — licence not yet checked. **Verify before packaging.**
- **Inter** — SIL OFL-1.1. Redistribution allowed with the licence text; the
  reserved font name may not be used for modified versions, so do not subset and
  re-release it under the name Inter.
- **archiso, Calamares, chwd, pacman** — GPL-3.0 / GPL-2.0 / GPL-3.0 /
  GPL-2.0. Consumption and repackaging are fine; our copies of their
  configuration are ours.
- **KDE Plasma, Discover, Qt** — GPL/LGPL mix. Untouched.
- **NVIDIA driver and `nvidia-utils`** — NVIDIA's redistribution terms are
  permissive for unmodified driver packages but are not a free licence. **Read
  them before baking the driver into an ISO**, and prefer downloading it in the
  installer over preinstalling it in the image. Flag as an open question if the
  installer-download path proves unreliable.

## Repo licensing

This repository is GPL-3.0-or-later (see `LICENSE`), which is not a claim that
every file in every produced image is GPL-3.0. The tree aggregates several
licences; when we vendor a third-party asset, its licence travels with it in the
package `PKGBUILD` and in the shipped `/usr/share/licenses/` entry.

## Naming

The working name **Tessera** is a placeholder. Before anything public, check that
it is not an existing OS, distribution, company or registered mark in the
relevant classes. It is cheap now and expensive later.

## Open questions to close before a public release

- WhiteSur-cursors licence.
- NVIDIA redistribution terms for a preinstalled driver.
- Whether the HyperOS-derived theme's GPL-3.0 obligation is satisfied by
  publishing `tessera-theme-hyperos` source in this repository (it is, but state
  it in the package).
- Whether the MiSans download link is Xiaomi-permitted to link from a third-party
  OS. Linking is normally fine; confirm the terms do not prohibit it.
