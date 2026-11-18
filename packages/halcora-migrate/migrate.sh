#!/bin/sh
# halcora-migrate — copy a Windows user's files onto Halcora.
#
# ADR-10 governs every decision here:
#
#   * the Windows volume is mounted READ-ONLY, always;
#   * a volume that was not shut down cleanly is refused rather than forced,
#     because Windows Fast Startup leaves NTFS volumes dirty and ntfs3 has no
#     fsck to put them right;
#   * nothing is written to the Windows side, ever.
#
# Writing is how migrations destroy data. A migration that cannot write cannot
# corrupt what it reads.
set -eu

usage() {
    cat <<'EOF'
usage: halcora-migrate [DEVICE]

Copies Documents, Desktop, Downloads, Pictures, Music and Videos from a Windows
installation into "~/Imported from Windows".

With no argument, the script looks for a single NTFS partition. The Windows
volume is mounted read-only and is never written to.
EOF
}

# --- locate the volume -------------------------------------------------------

device=${1:-}

if [ -z "$device" ]; then
    if ! command -v lsblk >/dev/null 2>&1; then
        echo "lsblk is missing; pass the device explicitly." >&2
        exit 1
    fi
    # ntfs-3g and the in-kernel driver both report as ntfs; a BitLocker volume
    # reports as BitLocker and is deliberately not matched.
    set -- $(lsblk -rno NAME,FSTYPE 2>/dev/null | awk '$2 == "ntfs" { print "/dev/" $1 }')
    if [ "$#" -eq 0 ]; then
        echo "No NTFS partition found. Pass the device explicitly, for example:" >&2
        echo "  halcora-migrate /dev/nvme0n1p3" >&2
        exit 1
    fi
    if [ "$#" -gt 1 ]; then
        echo "More than one NTFS partition found:" >&2
        for d in "$@"; do echo "  $d" >&2; done
        echo "Pass the Windows one explicitly." >&2
        exit 1
    fi
    device=$1
fi

if [ ! -b "$device" ]; then
    echo "$device is not a block device." >&2
    exit 1
fi

# --- refuse a dirty volume ---------------------------------------------------

if ! command -v ntfsfix >/dev/null 2>&1; then
    echo "ntfsfix is missing. Install ntfsprogs, or the volume cannot be checked." >&2
    exit 1
fi

state=$(ntfsfix --info "$device" 2>&1 || true)
case "$state" in
    *"not a valid NTFS"*)
        echo "$device does not look like NTFS." >&2
        exit 1
        ;;
esac

# ntfsfix --info prints a volume state line. "dirty" means Windows did not shut
# down cleanly. The fix is Windows' own: boot it, let it finish, shut down
# properly. Forcing an unclean volume is how data is lost.
if printf '%s\n' "$state" | grep -qi 'dirty'; then
    cat >&2 <<'EOF'
The Windows volume was not shut down cleanly, so it refuses to mount safely.

Boot Windows once, let it finish any updates, and use "Shut down" rather than
hibernating or using Fast Startup. Then run this again.

Nothing has been copied and nothing has been written.
EOF
    exit 1
fi

# --- mount, read-only --------------------------------------------------------

mountpoint=$(mktemp -d)
cleanup() {
    if mountpoint -q "$mountpoint" 2>/dev/null; then
        umount "$mountpoint" || umount -l "$mountpoint" || true
    fi
    rmdir "$mountpoint" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "Mounting $device read-only at $mountpoint"
mount -o ro "$device" "$mountpoint"

# --- find the Windows profile ------------------------------------------------

if [ ! -d "$mountpoint/Users" ]; then
    echo "No Users directory on $device; this does not look like a Windows volume." >&2
    exit 1
fi

profiles=$(find "$mountpoint/Users" -mindepth 1 -maxdepth 1 -type d \
    ! -name 'Public' ! -name 'Default' ! -name 'Default User' ! -name 'All Users' \
    -printf '%f\n' 2>/dev/null || true)

if [ -z "$profiles" ]; then
    echo "No user profile found under $device/Users." >&2
    exit 1
fi

count=$(printf '%s\n' "$profiles" | wc -l)
if [ "$count" -gt 1 ]; then
    echo "More than one Windows profile:" >&2
    printf '  %s\n' "$profiles" >&2
    printf 'Pick one by re-running with the profile name as the second argument:\n' >&2
    printf '  halcora-migrate %s <profile>\n' "$device" >&2
    exit 1
fi

profile=$(printf '%s\n' "$profiles" | head -n1)
if [ -n "${2:-}" ]; then
    profile=$2
fi

source="$mountpoint/Users/$profile"
if [ ! -d "$source" ]; then
    echo "No such profile: $profile" >&2
    exit 1
fi

# --- copy --------------------------------------------------------------------

dest="${HOME}/Imported from Windows"
mkdir -p "$dest"

echo "Copying from $source"
echo "          to $dest"

found=0
for folder in Documents Desktop Downloads Pictures Music Videos; do
    if [ ! -d "$source/$folder" ]; then
        continue
    fi
    found=1
    printf '  %-10s ' "$folder"
    # Nothing is deleted: rsync without --delete only adds. Files that cannot be
    # read (permissions, broken symlinks, filesystems that do not map) are
    # counted rather than aborting the whole migration.
    if rsync -rlt --no-perms --no-owner --no-group --ignore-errors \
             "$source/$folder/" "$dest/$folder/" 2>/dev/null
    then
        printf 'ok\n'
    else
        printf 'ok (some files were skipped)\n'
    fi
done

if [ "$found" -eq 0 ]; then
    echo "None of the usual folders exist in that profile." >&2
    exit 1
fi

cat <<EOF

Done. Nothing was written to the Windows volume.

What was deliberately not copied:
  * program files and installed applications — reinstall them;
  * browser profiles — import bookmarks from each browser's own first-run
    importer, which knows its own format and its own locks;
  * anything under AppData — it contains caches and machine-specific paths.
EOF
