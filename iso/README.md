# iso — the live image

An archiso profile, in the shape of archiso's own `configs/releng`.

## What is copied rather than written

Everything except the five files listed below comes from
`archlinux/archiso` at tag `v92` (package `archiso` 92-1):

    configs/releng/airootfs/
    configs/releng/efiboot/loader/
    configs/releng/grub/
    configs/releng/syslinux/
    configs/releng/bootstrap_packages
    configs/releng/pacman.conf

## What we change

- `profiledef.sh` — name, label, publisher, boot modes, squashfs options,
  `file_permissions`.
- `packages.x86_64` — the package set. `mkinitcpio`, `mkinitcpio-archiso` and
  `arch-install-scripts` are mandatory; everything else is policy.
- `pacman.conf` — Arch mirrors plus our own repository, in that order. This is
  the *build-time* config; the live system's own `pacman.conf` lives in
  `airootfs/etc/pacman.conf` and is separate.
- `airootfs/` — the overlay. What goes in it:
  - `etc/os-release`, `etc/lsb-release`
  - `etc/skel/` — the Plasma defaults a new user gets
  - `etc/systemd/system/getty@tty1.service.d/autologin.conf` and the equivalent
    for SDDM, so the live session opens without a login
  - `etc/systemd/system/multi-user.target.wants/NetworkManager.service`
  - `etc/calamares/` — the installer configuration (phase 3)
  - `etc/xdg/*` — Plasma defaults, so the live session is already skinned
  - `usr/share/discover/featuredurlrc` — points at our featured listing
  - `root/.automated_script.sh` — the live-session bootstrap
- Boot entries, only if we change them. Two are planned: the default entry on
  nouveau, and a second explicit entry that blacklists nouveau and loads
  `nvidia`, following the pattern EndeavourOS ships (`Only RTX GPUs, Turing, or
  later`). `%ARCHISO_LABEL%`, `%INSTALL_DIR%`, `%ARCH%` and `%KERNEL_PARAMS%` are
  substituted by archiso; do not hardcode them.

`mkarchiso` itself is never edited.

## Build

    mkarchiso -v -w work -o out .

## Test

    run_archiso -i out/tessera-*.iso

## Open items

- **Calamares is AUR-only on Arch.** `calamares` does not exist in `core` or
  `extra`; it must be built (AUR `calamares` 3.4.2, upstream 3.4.3 on Codeberg
  after the GitHub repo was archived in August 2025). It goes into the live
  image from our repository, not from Arch.
- **`chwd`** is packaged for plain Arch from CachyOS's repositories. Either add
  their repository or vendor the package into ours. Not yet decided.
- **NVIDIA driver in the image.** Prefer downloading it during installation over
  preinstalling it, pending a read of NVIDIA's redistribution terms
  (`docs/LEGAL.md`). The live NVIDIA entry therefore needs the driver shipped,
  which is exactly the tension to resolve.
- `archinstall` (in `releng`'s package list) is not wanted; we ship Calamares
  instead. Remove it when copying the list.
