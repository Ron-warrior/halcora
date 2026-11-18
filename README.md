# Tessera

A Linux desktop distribution that **looks like Xiaomi HyperOS**, ships a
**Windows-style layout by default**, offers a **macOS-style layout as an option**,
and is built to be unthreatening to people arriving from Windows.

Working title. The name is a placeholder and cheap to change.

Status: **planning**. Nothing here builds a working operating system yet.

---

## The one decision everything else follows from

KDE Plasma 6 already contains a layout switcher. It is called a *Global Theme*
(formerly *Look and Feel*), and `plasma-apply-lookandfeel` is its command line.

A Global Theme package bundles a panel layout template, a colour scheme, a Plasma
style, an icon theme, a cursor theme, window decorations, a splash screen and
fonts — each as plain files. Several can be installed side by side and switched
at runtime, non-interactively.

That means `tessera-layout win` and `tessera-layout macos` are two package ids and
one `plasma-apply-lookandfeel` invocation. The flagship feature of distros like
Zorin OS costs us about thirty lines of shell, because Plasma solved it first.

The entire project is an application of that principle: find the thing that is
already done, and package it rather than write it.

## What we author vs. what we borrow

- **Borrowed:** the base system, package manager, desktop shell, installer,
  live-image tooling, app store, two of the three visual themes, the GPU
  detection tool, the file manager, the migration logic. Enumerated with
  licenses and pinning strategy in `docs/REUSE.md`.
- **Authored:** one theme (HyperOS — no Plasma version exists), our own
  wallpapers and branding, a migration assistant, and the thin glue between
  them.

## The three visual identities, stacked rather than mixed

- **Windows** owns the default skeleton: taskbar, launcher, tray, window
  snapping, the habits switchers already have.
- **macOS** owns the optional skeleton: menu bar, dock, traffic lights,
  Mission-Control recents.
- **HyperOS** owns the skin in both cases: geometry, radii, colour, type,
  blur, accents.

Never averaged. One skeleton at a time, one surface language on top.

## Non-goals

- Not a new compositor, kernel, init system or package manager.
- Not a phone OS. Desktop x86_64 only.
- Not a Windows compatibility layer; no `.exe` promises of any kind.
- Not translated. English only for the foreseeable future.
- Not an attempt to out-do Arch, Plasma, Calamares or archiso. They are the
  supply chain.

## Where to read next

- `docs/VISION.md` — who it is for and what "friendly" concretely means
- `docs/ARCHITECTURE.md` — the layers, and which upstream owns each
- `docs/REUSE.md` — the borrow ledger: every component, its license, its pin
- `docs/DESIGN.md` — the visual spec and layout component mapping
- `docs/DECISIONS.md` — the settled decisions and why, including what was closed off
- `docs/ROADMAP.md` — phases, from "judge the skin" to "bootable ISO"
- `docs/LEGAL.md` — what we may redistribute, and the three things we may not

## Quick start (Phase 0 — no build required)

On a machine already running Arch with Plasma 6:

1. Install the two upstream themes from AUR or by building the packages:
   `fluent-kde` and `whitesur-kde`, plus their icon and cursor sets.
2. Copy the Global Theme directories into
   `~/.local/share/plasma/look-and-feel/`.
3. `plasma-apply-lookandfeel --list` then
   `plasma-apply-lookandfeel --apply <id> --resetLayout`.

That is the whole product minus the HyperOS skin, the branding and the installer.
Judge it, then read the roadmap.

## License

GPL-3.0-or-later. See `LICENSE`.
