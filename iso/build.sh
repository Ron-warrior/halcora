#!/usr/bin/env bash
# Build the Halcora live ISO.
#
# The profile is a DELTA over archiso's own releng profile, not a vendored copy
# of it. At build time we take whatever releng ships with the installed archiso
# package, then overlay only the files we actually change.
#
# That choice is deliberate and it is the main reason this profile is short:
#
#   - It cannot drift out of sync with archiso. Projects that vendor the whole
#     profile have to pin an archiso version; we track whatever Arch ships, so an
#     archiso upgrade cannot leave us with a stale mkinitcpio hook or a missing
#     boot entry.
#   - The diff we maintain is the diff a reviewer can actually read.
#
# Requires: archiso, plus root (mkarchiso mounts filesystems and uses loop
# devices).
#
# Usage:
#   sudo ./iso/build.sh
#   sudo CALAMARES_STAGE=/path/to/stage ./iso/build.sh
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=${WORK:-/tmp/halcora-build}
OUT=${OUT:-$ROOT/out}
RELENG=${RELENG:-/usr/share/archiso/configs/releng}
PROFILE=$WORK/profile

if [[ ! -d $RELENG ]]; then
    printf 'archiso releng profile not found at %s\n' "$RELENG" >&2
    printf 'Install the archiso package, or set RELENG to its configs/releng.\n' >&2
    exit 1
fi

printf '==> staging a clean profile at %s\n' "$PROFILE"
rm -rf "$WORK"
mkdir -p "$PROFILE" "$OUT"

# 1. Upstream releng, verbatim.
cp -a "$RELENG/." "$PROFILE/"

# 2. Profile-level deltas: naming and package set.
install -m 644 "$ROOT/iso/profile/profiledef.sh" "$PROFILE/profiledef.sh"
install -m 644 "$ROOT/iso/profile/packages.x86_64" "$PROFILE/packages.x86_64"

# 3. Everything we add to the live root.
cp -a "$ROOT/iso/overlay/." "$PROFILE/airootfs/"

# 4. Our own scripts that belong in the image.
install -Dm 755 "$ROOT/scripts/halcora-layout" \
    "$PROFILE/airootfs/usr/local/bin/halcora-layout"

# 5. Calamares, when CI has built it out of tree. It is not in the Arch
#    repositories, so it cannot come from the package list.
if [[ -n ${CALAMARES_STAGE:-} ]]; then
    if [[ ! -d $CALAMARES_STAGE ]]; then
        printf 'CALAMARES_STAGE is set but %s is not a directory\n' "$CALAMARES_STAGE" >&2
        exit 1
    fi
    # Only usr/ is taken from the stage. Its etc/ would be upstream's default
    # configuration and would overwrite the overlay above, so it is never copied.
    printf '==> overlaying Calamares binaries from %s\n' "$CALAMARES_STAGE"
    cp -a "$CALAMARES_STAGE/usr" "$PROFILE/airootfs/"
else
    printf '==> CALAMARES_STAGE unset: building an ISO with no installer\n'
fi

# 6. Halcora's own packages, when somebody has built them.
#
#    The theme packages are not in the Arch repositories, so until a local
#   pacman repository exists the image simply does not contain them and looks
#   like stock Plasma. Pointing HALCORA_REPO at the output of
#   `packages/build.sh` pulls them in.
#
#   Build time only: the repository is added to the *profile*, which mkarchiso
#   uses to install packages. It is deliberately not added to the installed
#   system's /etc/pacman.conf, because update infrastructure is a later phase and
#   an installed system pointed at a path on someone else's disk is worse than
#   one with no extra repository at all.
if [[ -n ${HALCORA_REPO:-} ]]; then
    if [[ ! -d $HALCORA_REPO ]]; then
        printf 'HALCORA_REPO is set but %s is not a directory\n' "$HALCORA_REPO" >&2
        exit 1
    fi
    if ! compgen -G "$HALCORA_REPO/*.pkg.tar.zst" >/dev/null; then
        printf 'HALCORA_REPO has no built packages; run packages/build.sh first\n' >&2
        exit 1
    fi
    printf '==> adding local repository %s\n' "$HALCORA_REPO"
    {
        printf '\n[halcora]\n'
        # These are our own packages, built here, unsigned. Trusting them is the
        # same decision as shipping them in the image.
        printf 'SigLevel = Optional TrustAll\n'
        printf 'Server = file://%s\n' "$HALCORA_REPO"
    } >>"$PROFILE/pacman.conf"
    # Everything the image needs from our repository. Branding is deliberately
    # absent: it is written but not wired into Calamares yet, and an image that
    # shows it would say the installer had been rebranded when settings.conf
    # still says `branding: default`.
    printf 'halcora-theme-hyperos\nhalcora-defaults\nhalcora-first-run\nhalcora-migrate\nhalcora-icons-fluent\nhalcora-icons-whitesur\nhalcora-cursors-whitesur\nhalcora-lookandfeel-win\nhalcora-lookandfeel-macos\nhalcora-layout\n' \
        >>"$PROFILE/packages.x86_64"
else
    printf '==> HALCORA_REPO unset: no Halcora packages in this image\n'
fi

# 7. Symlinks. These cannot live in git, so they are made here.
printf '==> creating service symlinks\n'
SYSTEMD=$PROFILE/airootfs/etc/systemd/system
mkdir -p "$SYSTEMD/multi-user.target.wants" "$SYSTEMD/network-online.target.wants"
ln -sf /usr/lib/systemd/system/sddm.service \
    "$SYSTEMD/display-manager.service"
ln -sf /usr/lib/systemd/system/NetworkManager.service \
    "$SYSTEMD/multi-user.target.wants/NetworkManager.service"
ln -sf /usr/lib/systemd/system/NetworkManager-wait-online.service \
    "$SYSTEMD/network-online.target.wants/NetworkManager-wait-online.service"
ln -sf /usr/lib/systemd/system/NetworkManager-dispatcher.service \
    "$SYSTEMD/dbus-org.freedesktop.nm-dispatcher.service"
ln -sf /dev/null "$SYSTEMD/multi-user.target.wants/systemd-networkd.service"

# releng ships systemd-networkd wired-link config. We use NetworkManager for both
# wired and wireless, and two network managers fighting over one link is a
# classic self-inflicted outage, so the networkd .network files go.
rm -f "$PROFILE"/airootfs/etc/systemd/network/*.network

# 8. A second UEFI boot entry for NVIDIA.
#
#    ADR-8: the default entry keeps nouveau, and a second one blacklists it so the
#    proprietary driver can take the card. On a machine with an RTX 2060 the
#    default entry is the safe one and the second is the one that will be used;
#    on anything else the first still works.
#
#    The entries are derived from releng's own rather than written out, so a
#    change to archiso's kernel command line is inherited instead of copied.
#    `&` in the sed replacement is the whole matched title line.
printf '==> adding the NVIDIA boot entries\n'
for entry in "$PROFILE"/efiboot/loader/entries/*.conf; do
    [ -f "$entry" ] || continue
    case "$entry" in *-nvidia.conf) continue ;; esac
    sed -e 's/^title[[:space:]].*/& (NVIDIA)/' \
        -e 's/^options[[:space:]]/options module_blacklist=nouveau,nouveau_drm nouveau.modeset=0 /' \
        "$entry" >"${entry%.conf}-nvidia.conf"
done
# Only the UEFI entries get a variant. releng's syslinux menus are a different
# format and editing them is a second job for a path nobody has needed; the
# BIOS entry therefore has one entry, which is correct on old hardware.

# 9. The live user's home. The account itself comes from sysusers.d, which is
#    declarative and creates the matching group for us.
printf '==> creating /home/live\n'
install -d -o 1000 -g 1000 -m 750 "$PROFILE/airootfs/home/live"

# 10. Build.
printf '==> mkarchiso\n'
mkarchiso -v -w "$WORK/work" -o "$OUT" "$PROFILE"

printf '==> done\n'
ls -lh "$OUT"
( cd "$OUT" && sha256sum ./*.iso > SHA256SUMS && cat SHA256SUMS )
