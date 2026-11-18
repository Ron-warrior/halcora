# Halcora

A Linux desktop distribution that **looks like Xiaomi HyperOS**, ships a
**Windows-style layout by default**, offers a **macOS-style layout as an option**,
and is built to be unthreatening to people arriving from Windows.

Status: **the live ISO builds in CI and is downloadable, and has never been
booted.** The installer has never completed an install. Eleven packages exist on
`main` — the layouts, the HyperOS theme, icons, cursors, branding, a first-run
question and a migration tool — and **none of them has been built**, so the
current image is a boot-and-install test, not a design test.

---

## The one decision everything else follows from

KDE Plasma 6 already contains a layout switcher. It is called a *Global Theme*
(formerly *Look and Feel*), and `plasma-apply-lookandfeel` is its command line.

A Global Theme package bundles a panel layout template, a colour scheme, a Plasma
style, an icon theme, a cursor theme, window decorations, a splash screen and
fonts — each as plain files. Several can be installed side by side and switched
at runtime, non-interactively.

That means `halcora-layout win` and `halcora-layout macos` are two package ids and
one `plasma-apply-lookandfeel` invocation. The flagship feature of distributions
like Zorin OS costs about thirty lines of shell, because Plasma solved it first.

The entire project is an application of that principle: find the thing that is
already done, and package it rather than write it.

## The name

**Halcora.** Coined, not a word in any language we know of, and a GitHub search
for it returns no repositories at all — about as unclaimed as a name gets. It is
also not trademark-adjacent: no Harmony, no Windows, no Apple. See `LEGAL.md`
for why that matters and what still needs checking before anything is public.

## What we author vs. what we borrow

- **Borrowed:** the base system, package manager, desktop shell, installer, live
  image tooling, app store, two of the three visual themes, the GPU detection
  tool, the file manager, the migration logic. Enumerated with licences and
  pinning strategy in `docs/REUSE.md`.
- **Authored:** the HyperOS palette, a recoloured window decoration and Kvantum
  configuration, two wallpapers, one first-run question, a read-only Windows
  import tool, and the thin glue between all of it. Right now: two shell scripts,
  the palette, the decoration, two SVG wallpapers and the Calamares
  configuration.

## The three visual identities, stacked rather than mixed

- **Windows** owns the default skeleton: taskbar, launcher, tray, window
  snapping, the habits switchers already have.
- **macOS** owns the optional skeleton: menu bar, dock, traffic lights,
  Mission-Control recents.
- **HyperOS** owns the skin in both cases: geometry, radii, colour, type, blur,
  accents.

Never averaged. One skeleton at a time, one surface language on top.

## Non-goals

- Not a new compositor, kernel, init system or package manager.
- Not a phone OS. Desktop x86_64 only.
- Not a Windows compatibility layer; no `.exe` promises of any kind.
- Not translated. English only for the foreseeable future.
- Not an attempt to out-do Arch, Plasma, Calamares or archiso. They are the
  supply chain.

## Building the ISO

Nothing builds on the user's device, so CI is the build host:

    .github/workflows/iso.yml    # Arch container, mkarchiso, artifact upload

The profile is a delta over archiso's `releng` profile rather than a vendored
copy of it, so it tracks Arch instead of pinning a version. Details and the
current list of known gaps are in `iso/README.md`.

## Where to read next

**If you are an AI agent picking this up:** start at `AGENTS.md`, then
`docs/STATE.md` and `docs/TASKS.md`. Those three exist precisely so you do not
have to reconstruct the situation from the rest of the tree.

- `AGENTS.md` — rules for agents, and the loop you are working in
- `docs/STATE.md` — verified current state, with dates. Update it when you finish
- `docs/BUILDING.md` — the four steps from clone to a desktop, in order
- `docs/TASKS.md` — the ordered queue; do the first unfinished task only
- `docs/HANDOFF.md` — procedures, failure-to-action table, glossary
- `docs/TESTING.md` — the human's boot and install protocol
- `docs/PROMPTS.md` — copy-paste prompts for starting a session
- `docs/VISION.md` — who it is for and what "friendly" concretely means
- `docs/ARCHITECTURE.md` — the layers, and which upstream owns each
- `docs/REUSE.md` — the borrow ledger: every component, its licence, its pin
- `docs/DESIGN.md` — the visual spec and layout component mapping
- `docs/DECISIONS.md` — the settled decisions and why, including what was closed off
- `docs/ROADMAP.md` — phases, ordered ISO-first
- `docs/LEGAL.md` — what we may redistribute, and the three things we may not
- `iso/README.md` — how the image is built and what is still missing from it

## Status

An ISO is published as a moving `prealpha` pre-release and can be downloaded.
**It has never been booted.** See `docs/STATE.md` for what that does and does not
mean, and `docs/TESTING.md` if you are the person who can change that.

## License

GPL-3.0-or-later. See `LICENSE`.
