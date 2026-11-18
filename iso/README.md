# iso

The live image, built by `build.sh` in CI.

## The shape of it

The profile is a **delta over archiso's own `releng` profile**, not a vendored
copy of it. `build.sh` copies whatever `releng` ships with the installed
`archiso` package, then overlays only what we change:

- `profile/profiledef.sh` — naming and `file_permissions`. Mirrors upstream with
  the minimum possible divergence.
- `profile/packages.x86_64` — the package set. This is also the installed
  system's package set, because the installer unpacks the live squashfs.
- `overlay/` — everything added to the live root: the live account, SDDM
  autologin, the Calamares configuration, the installer's desktop entry.

Projects that vendor the whole profile have to pin an archiso version and go
stale when Arch moves. Tracking it means an archiso upgrade cannot leave us with
a dead mkinitcpio hook path.

## Build

Locally, on Arch, as root:

    sudo pacman -S archiso
    sudo bash ./iso/build.sh

It is invoked through `bash` rather than executed directly, because the
executable bit does not survive every checkout — that mismatch was the
workflow's first failure (exit 126).

In CI, `.github/workflows/iso.yml` does the same thing in a privileged Arch
container, plus the one step that cannot come from the package list: building
Calamares from source (it is AUR-only) and staging it for `build.sh` to overlay.

Nothing can be built or tested on the user's device, so **CI is the only real
build host and the only real test loop.** An ISO that has not been through the
workflow has not been built.

## Releases

Every green build on `main` publishes a GitHub release tagged `prealpha`, marked
as a pre-release, carrying the ISO and `SHA256SUMS`. It is replaced on each
successful build rather than accumulating versions, because a version number on
an image nobody has booted would claim more than it has earned.

GitHub caps a release asset at 2 GiB. Whether a Plasma ISO lands under that is
unknown until one exists, so the workflow measures it and fails with a plain
message rather than letting the upload fail as an opaque 422.

## What is in the first image

- Plasma 6 on Wayland, SDDM autologin to a `live` account, Firefox, Dolphin.
- NetworkManager for wired and wireless; `systemd-networkd` is disabled so the
  two cannot fight over a link.
- Calamares, offline, unpacking the live image to disk. Erase-disk only.
- **No Halcora skin yet.** The theme packages do not exist, so this image looks
  like stock Plasma. It is a boot-and-install test, not a design test.

## Known gaps, roughly in the order they bite

1. **Calamares has never been run.** The sequence in
   `overlay/etc/calamares/settings.conf` uses only stock modules and is derived
   from ALCI's working sequence, but "stock modules, correct order" is exactly
   the kind of claim that is wrong in a way only a real install reveals.
2. **The installer is unbranded.** `branding: default` until there is a Halcora
   brand worth showing.
3. **No NVIDIA path yet.** The live session uses nouveau; the open kernel
   modules and the second boot entry are next.
4. **Erase-disk only.** No install-alongside, so a test machine's Windows install
   is not safe from a careless click.
5. **The installed system carries live-session leftovers** — the `live` account,
   the installer's desktop entry, the SDDM autologin. A Calamares `shellprocess`
   cleanup step is the fix, and it is not written yet.
