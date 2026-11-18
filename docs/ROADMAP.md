# Roadmap

Each phase ends with something a person can look at. Nothing in a later phase
starts before the earlier one's exit criterion is met, because the whole premise
is that the design is judged before any of it is packaged.

## Phase 0 — Judge the design, no build required

Install Plasma 6 on an existing machine (or a VM with virtio-gpu), install
`Fluent-kde` and `WhiteSur-kde`, apply each with
`plasma-apply-lookandfeel --apply <id> --resetLayout`, and live in each for a
day. Recolour nothing yet.

**Exit criterion:** a written verdict on whether a Windows-style default with a
macOS-style option is worth building on, and which parts of each feel wrong.

## Phase 1 — The theme packages

Repackage Fluent-kde, WhiteSur-kde and their icon and cursor sets as
`tessera-lookandfeel-win` and `tessera-lookandfeel-macos`, pinned by commit via
`scripts/fetch-themes.sh`. Add `tessera-fonts` (Inter) and `tessera-defaults`
(`/etc/skel`). Ship the HyperOS skin as a first cut, recoloured from Fluent-kde.
Publish to a local pacman repository.

**Exit criterion:** on a clean Arch + Plasma install, adding our repo and running
`tessera-layout win` produces the intended desktop, and `tessera-layout macos`
switches it, with no manual steps.

**Risks:** the HyperOS skin is the only authored design and will look like
recoloured Fluent before it looks like HyperOS. That is expected; do not stall
the phase waiting for it to be beautiful.

## Phase 2 — A bootable image

Copy archiso's `releng` profile into `iso/profile/`, swap the package list, add
an `airootfs` overlay with `os-release`, skel files, an autologin Plasma session,
the Discover featured-listing config, and two boot entries (nouveau default,
NVIDIA explicit). Build with `mkarchiso`, test with `run_archiso`.

**Exit criterion:** boots to a Plasma live session on the 10700F / RTX 2060
machine from USB, on both boot entries, with the HyperOS skin already applied.

**Risks:** live-session autologin and the NVIDIA entry are the two historically
fiddly parts.

## Phase 3 — Installer and first run

Calamares with lifted EndeavourOS branding and stock modules (ADR-7), `chwd`
called inside the target, our Calamares branding, and a first-run wizard that
asks one question — *which layout* — and then offers the MiSans download and the
Windows import.

**Exit criterion:** a blank machine installs to a desktop that looks the same as
the live session, with the right GPU driver, and the user answered at most two
questions along the way.

**Risks:** `chwd` from the AUR against a non-CachyOS Arch; Calamares' module
choice (ADR-7); not shipping a bootloader configuration that eats an existing
Windows entry.

## Phase 4 — Migration and refinery

`tessera-migrate`: read-only NTFS mount, rsync from lists lifted from migratepc,
browser import delegated to the browsers, wallpaper copied, and a refusal path
for dirty volumes that reads as help rather than an error. Then the long work:
HyperOS theme quality, our own wallpapers, store curation, printing, Bluetooth,
suspend, and the pile of small hardware things that decide whether anyone keeps
it installed.

**Exit criterion:** someone whose only computer experience is Windows 11 can be
handed a USB stick and be productive without a terminal, and we have a list of
the things that surprised them.

**Risks:** this is the phase with no upstream to lean on. It is also the phase
that decides whether the project is real.

## Explicitly not scheduled

- Translations.
- ARM or non-x86_64.
- Any Windows application compatibility claims.
- A custom store, installer or shell.
- Reproducible builds, signed repository, update infrastructure. Needed
  eventually; deliberately after the thing exists.
