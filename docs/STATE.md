# State

**The single file that answers "where are we?".** Verified facts only, with the
date and commit they were verified at. Update this at the end of every session.

If you are an agent reading this and the numbers look stale, re-verify them with
the commands in `docs/HANDOFF.md` before trusting them.

    Last verified: 2026-11-18
    Commit:        33fee82  (Add syslinux to ISO package list)
    Verified by:   reading git status/log and the GitHub releases API
    Tested by anyone: NO

---

## What actually exists

- **Repository**: https://github.com/Ron-warrior/halcora — public, GPL-3.0.
- **Four commits**, all pushed, working tree clean.
- **A downloadable ISO**, published as a pre-release:
  - Tag: `prealpha` (a single moving pre-release, replaced on each green build)
  - Asset: `halcora-2026.11.18-x86_64.iso`
  - Size: 2,024,570,880 bytes (1.885 GiB)
  - SHA-256: `52e6eb90b8c492c5b2584ea339b11c7c3aab001d012185c3d8c50367a97811d1`
  - Built from commit `33fee82`
- **CI**: `.github/workflows/iso.yml`, 148 lines. Builds Calamares from source on
  Arch, then `mkarchiso`, then publishes the release. Green as of `33fee82`.

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

**A human has to boot the ISO.** No agent can do this, and nothing else can be
learned until it happens. `docs/TESTING.md` is the protocol to give them.

Until a boot report arrives, the only safe work on `main` is documentation and
the fast check workflow. Anything else risks muddying the first real test.

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

Two real CI failures so far, both instructive:

1. `./iso/build.sh` exited 126: the executable bit does not survive checkout.
   Fixed by invoking `bash ./iso/build.sh`.
2. The ISO build failed because `syslinux` was missing from the package list:
   `bootmodes` includes `bios.syslinux`. Fixed in `33fee82`.

Both were caught by CI, not by reading carefully. That is the expected shape of
progress here: push, read the log, fix the named thing.
