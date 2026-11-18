# Roadmap

The order changed once it was decided that a bootable ISO comes first. That is
the right sequencing for a project whose risk lives in the installer and the
image, not in the design: a shell that looks perfect inside a machine you cannot
install is a demo, and an installer that works is a distribution.

## Phase 0 — The image boots

`iso/build.sh` builds, `mkarchiso` succeeds, CI uploads an ISO, the ISO reaches
a Plasma live session on real hardware and in QEMU.

**Exit criterion:** the ISO boots to a desktop on the 10700F / RTX 2060 machine
from USB, on both the UEFI and BIOS paths, with working network and sound.

**Risks:** the live account (created by `sysusers.d`, autologged-in by SDDM);
the service symlinks `build.sh` creates; whether disabling `systemd-networkd`
left the live session with no networking. All three are cheap to fix and all
three are invisible until something boots.

## Phase 1 — The installer works

Calamares, offline, unpacking the live image. Erase-disk only. One account, one
password, one bootloader.

**Exit criterion:** a blank disk installs to a desktop that looks and behaves
exactly like the live session, and reboots unaided. Then the same on a machine
with an existing Windows install that must survive.

**Risks:** this is the highest-risk phase in the project. `unpackfs` from
`/run/archiso/bootmnt/<install_dir>/x86_64/airootfs.sfs`, the initramfs
regeneration, and grub installation on both firmware types are all things that
either work or produce an unbootable disk. Then the leftovers: the installed
system currently inherits the `live` account, the installer's desktop entry and
the SDDM autologin, and needs a `shellprocess` cleanup step that does not exist
yet.

## Phase 2 — The skin

The theme packages, and the layout switcher finally has something to switch to:

- `halcora-lookandfeel-win` (wraps Fluent-kde) — the Windows layout, default.
- `halcora-lookandfeel-macos` (wraps WhiteSur-kde) — the macOS layout, option.
- `halcora-theme-hyperos` — the authored skin, forked from Fluent-kde's geometry
  and recoloured. The only design work in the project.
- `halcora-fonts` — Inter, already an Arch package (`inter-font`), so this is
  a dependency rather than a build.
- `halcora-branding` — our own wallpapers, Plymouth splash, Calamares branding.

As of the `themes/lookandfeel` branch the first two are written and have never
been built; `halcora-layout` (the package that ships the switcher) is written
too. Everything else here is unwritten. Nothing in this list is in the ISO until
`packages/build.sh` produces a repository the image can read.

**Exit criterion:** `halcora-layout win` and `halcora-layout macos` both produce
the intended desktop on a freshly installed system, with no manual steps, and
the HyperOS skin is doing the work in both.

**Risks:** the HyperOS theme will look like recoloured Fluent long before it
looks like HyperOS. Expected; do not stall the phase waiting for beauty.

## Phase 3 — Hardware and first run

`chwd` at install time, the NVIDIA boot entry, and a first-run wizard that asks
one question — which layout — then offers the MiSans download.

**Exit criterion:** a machine with an RTX 2060 installs, reboots with the
proprietary driver and working suspend, and the user answered at most two
questions.

## Phase 4 — Migration, and the long refinery

`halcora-migrate`: read-only NTFS mount, rsync from lists lifted from
migratepc, browser import delegated to the browsers, and a refusal path for dirty
volumes that reads as help rather than an error. Then the unglamorous pile:
printing, Bluetooth, store curation, and the small hardware things that decide
whether anyone keeps it installed.

**Exit criterion:** someone whose only computer experience is Windows 11 can be
handed a USB stick and be productive without a terminal, and we have a list of
the things that surprised them.

## Explicitly not scheduled

- Translations.
- ARM or non-x86_64.
- Any Windows application compatibility claims.
- A custom store, installer or shell.
- Reproducible builds, a signed repository, update infrastructure. Needed
  eventually; deliberately after the thing exists.
