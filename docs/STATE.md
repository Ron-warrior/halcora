# State

**The single file that answers "where are we?".** Verified facts only, with the
date and commit they were verified at. Update this at the end of every session.

If you are an agent reading this and the numbers look stale, re-verify them with
the commands in `docs/HANDOFF.md` before trusting them.

    Last verified: 2026-11-18
    Commit:        the one containing this file
    Last commit with a known-green ISO: 33fee82
    Verified by:   git log/status, the GitHub Actions API, one job log
    Tested by anyone: NO

---

## What actually exists

- **Repository**: https://github.com/Ron-warrior/halcora — public, GPL-3.0.
- **`main` carries everything** as of the merge of `themes/lookandfeel`
  (`8767d41`): eleven packages, a repository builder, and the live-image fixes.
  The branch existed because none of it had been built; it was merged once the
  installer fixes were worth getting into a downloadable image.
  - `halcora-lookandfeel-win` wraps Fluent-kde at `44794f2`, `-macos` wraps
    WhiteSur-kde at `cf4df59`. Each renames its Global Theme to
    `org.halcora.lookandfeel.win` / `.macos` so the ids the switcher asks for
    exist, strips the palette and cursor lines from `contents/defaults` so a
    layout switch is not also a light/dark switch, and depends on its icon theme
    because its Global Theme names one.
  - `halcora-layout` ships the switcher to `/usr/bin`, depends on both layouts,
    and now says which package to install when an id is missing.
  - `halcora-theme-hyperos` ships two hand-authored colour schemes (a first
    approximation, not device-sampled — each file says so), an Aurorae
    decoration recoloured from literals read in upstream's `close.svg`, a
    Kvantum config recoloured from its `GeneralColors`, and a Plasma style
    recoloured by decompressing its `.svgz` files. **The Plasma style
    self-verifies**: if no file matched the map it is skipped with a build-log
    note rather than shipped in Fluent's colours.
  - `halcora-defaults` puts that palette in `/etc/skel` and sets double-click.
  - `halcora-icons-fluent`, `halcora-icons-whitesur` (the latter passes `-p` so
    the Apple logo never ships) and `halcora-cursors-whitesur` (the only package
    that compiles anything).
  - `halcora-branding` has `os-release`, Calamares branding with a placeholder
    mark, and two authored SVG wallpapers. **Not wired in**: `settings.conf`
    still says `branding: default`.
  - `halcora-first-run` asks one question at first login, then never again.
  - `halcora-migrate` copies a Windows profile's six user folders, read-only,
    refusing a dirty volume (ADR-10).
  - `packages/build.sh` runs `makepkg` then `repo-add` into `packages/repo`.
  - **No `makepkg` run has been attempted** and there is no pacman repository in
    the tree. CI checks that the packages parse as shell, that each `pkgname`
    matches its directory, that every layout id the switcher names is present,
    that each git source alias matches the directory its build uses, that the
    `.colors` files are well formed, that the palette exists nowhere else, that
    the default scheme exists, that no Calamares module config is orphaned, and
    that every SVG parses.
  - `iso/build.sh` can consume `packages/repo` through `HALCORA_REPO`; with it
    unset, which is what CI does, the image is unchanged. It also adds a second
    UEFI boot entry that blacklists nouveau (ADR-8) — an entry point for the
    NVIDIA work, not the work.
- **A downloadable ISO**, published as a moving `prealpha` release:
  - Built from `8767d41` — the merge that first put the packages and the
    live-image fixes on `main`.
  - Asset: `halcora-2026-11-18-x86_64.iso`
  - Size: 2,024,570,880 bytes (1.885 GiB)
  - SHA-256: `e8b37faef907c077cc3a632fee5a07adae9b1eedf42ab391dda73f7d416e7609`
  - It replaces the first prealpha (built from `33fee82`), which could not open
    its installer at all.
- **CI, build**: `.github/workflows/iso.yml`, 155 lines. Builds Calamares from
  source on Arch, then `mkarchiso`, then publishes the release. **Green on
  `8767d41`** — the first build to contain the X11 live session, installer
  wrapper, polkit rule and corrected locale.
- **CI, guard**: `.github/workflows/check.yml`, 131 lines. Unprivileged, about
  two minutes: every package name exists, the scripts parse, the Calamares YAML
  loads, and `install_dir` matches `unpackfs.conf`. It failed on its first run —
  `archlinux:latest` ships no pacman databases — and that is fixed. Expected to
  go green, not yet observed green.

## What has never happened

Everything below is genuinely untested, not "probably fine":

- The ISO has **never been booted**, on hardware or in a VM.
- The installer has **never completed an install**.
- The Calamares module sequence has **never been executed**.
- The live account (`sysusers.d`) has **never been created at boot**.
- NetworkManager has **never come up** in the live session.
- The installed system has **never rebooted**.

`docs/ROADMAP.md` phase 0 and phase 1 are therefore both open, despite a
downloadable ISO existing.

## The blocker

**Two things, both needing a person, not an agent.**

1. **Boot the ISO.** No agent can do this, and nothing else can be learned until
   it happens. `docs/TESTING.md` is the protocol.
2. **Build the packages.** `packages/build.sh` needs an Arch machine. Nothing on
   the branch has ever been through `makepkg`, so every recipe is "written
   against sources that were read", which is not the same claim.

Until those happen, the only safe work is documentation and CI. Everything else
risks turning an unverified tree into a larger unverified tree.

## Live hazards, with numbers

- **2 GiB release limit.** The ISO is 2,024,570,880 bytes against a
  2,147,483,648-byte GitHub asset cap: **117 MiB of headroom (5.7%)**. A dozen
  large packages can silently kill publishing. `iso.yml` measures the ISO and
  fails with a readable message rather than an opaque 422.
- **`install_dir` coupling.** `iso/profile/profiledef.sh` sets
  `install_dir="halcora"`, and `iso/overlay/etc/calamares/modules/unpackfs.conf`
  hard-codes `/run/archiso/bootmnt/halcora/x86_64/airootfs.sfs`. Change one
  without the other and every install produces an unbootable disk, with no error
  until the human reboots.
- **Erase-disk only.** `partition.conf` offers no install-alongside path. A test
  machine holding another OS is at risk from a careless click.
- **No NVIDIA path.** The live session uses nouveau. The RTX 2060 target machine
  will not have the proprietary driver.
- **No skin.** The theme packages do not exist, so the image looks like stock
  Plasma. `scripts/halcora-layout` is installed in the image but references
  Global Theme ids (`org.halcora.lookandfeel.win`) that no package provides, so
  running it there does nothing useful yet.
- **No trademark search** has been done on the name. `docs/LEGAL.md`.

## Failure history

Three real CI failures so far, all instructive:

1. `./iso/build.sh` exited 126: the executable bit does not survive checkout.
   Fixed by invoking `bash ./iso/build.sh`.
2. The ISO build failed because `syslinux` was missing from the package list:
   `bootmodes` includes `bios.syslinux`. Fixed in `33fee82`.
3. The `Check` workflow failed in twelve seconds with `error: target not found:
   archlinux-keyring` — a package that obviously exists. `archlinux:latest`
   ships no pacman databases, and the step ran `pacman -S` before any `pacman
   -Sy`. Fixed by syncing first.

Both were caught by CI, not by reading carefully. That is the expected shape of
progress here: push, read the log, fix the named thing.


## Fixed by reading, never by running

Four things in the live image were wrong in ways that would have looked like "it
just doesn't work". All four fixes are unverified:

1. **The installer could not open.** The live session was Wayland, and Calamares
   runs as root through pkexec, which cannot reach a user's Wayland socket. The
   live session is X11 now, and `halcora-installer` grants root X access for the
   installer's lifetime and revokes it after.
2. **pkexec had no password to ask for.** The live account has none. A polkit rule
   allows that one user to run calamares, and nothing else.
3. **The locale did not exist.** `LANG` was `en_GB.UTF-8`; archiso's releng
   profile generates only `en_US`.
4. **Partitioning did not default to erase.** The comment said it did; nothing set
   it. `initialPartitioningChoice` now does.
5. **The switcher's KWin reload did nothing.** It calls `qdbus6`, and `qt6-tools`
   — which provides it — was in no package list. The call is guarded by `|| true`,
   so the window buttons kept the old decoration until the next login.
6. **The first-run dialog could abort the script.** Under `set -e`, closing the
   window returned 1 from a test that was the last command of its branch.

Plus three smaller ones: the autologin group the Calamares `users` module
requires did not exist, the migration tool mounted a disk as a non-root user,
`halcora-layout` was shipped twice with `/usr/local/bin` shadowing the packaged
copy, and the polkit rule would have granted root to `/usr/bin/env` rather than to
the installer.

Every one of these is a claim from reading, not from a boot. `docs/TESTING.md` is
how they get proven.


## Windows launcher (written, never run on Windows)

- `windows/Halcora.cmd` starts `windows/Halcora-VM.ps1`.
- The script downloads the newest `halcora-*.iso` from the `prealpha` release
  and checks it against `SHA256SUMS` before starting anything.
- It runs QEMU's `qemu-system-x86_64w.exe` with WHPX when the hypervisor is
  present, TCG otherwise, and creates a 20 GB qcow2 disk for the installer.
- CI (`.github/workflows/windows.yml`) parses the PowerShell and dry-runs
  `-ShowCommand` on a Windows runner. That is the only verification so far.
- Unknowns: whether WHPX works on Windows 11 Home; whether `-cpu Haswell` is
  accepted under WHPX; whether PowerShell 5.1 quotes paths containing spaces
  the way QEMU needs. These are the first things to check on a real machine.
