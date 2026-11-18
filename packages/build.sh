#!/usr/bin/env bash
# build.sh — build every package into a local pacman repository.
#
# Not shipped, not trusted: it is the shortest path from "two PKGBUILDs" to "a
# repository pacman can read", which is the last piece of phase 1. Nothing here
# has been run; see the caveat at the bottom.
#
# Usage, on Arch, as a normal user:
#
#     sudo pacman -S --needed base-devel
#     ./packages/build.sh
#     sudo pacman -Syu --needed halcora-lookandfeel-win halcora-lookandfeel-macos
#
# Environment:
#   REPO=/path   where the repository is written  (default: packages/repo)
#   BUILD=/path  where makepkg's working dirs go  (default: packages/build)
#
# Must NOT run as root: makepkg refuses to, and the layout packages additionally
# rely on that refusal, because upstream's installers would otherwise write to
# the build machine's /usr/share.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
repo=${REPO:-$here/repo}
build=${BUILD:-$here/build}

if (( EUID == 0 )); then
    printf 'Do not run this as root. Run it as the user who will own the repo.\n' >&2
    exit 1
fi

for tool in makepkg repo-add; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf '%s not found. On Arch: sudo pacman -S --needed base-devel pacman\n' "$tool" >&2
        exit 1
    fi
done

mkdir -p "$repo" "$build"

built=0
for pkgbuild in "$here"/*/PKGBUILD; do
    [ -f "$pkgbuild" ] || continue
    name=$(basename "$(dirname "$pkgbuild")")
    printf '==> %s\n' "$name"
    (
        cd "$(dirname "$pkgbuild")"
        PKGDEST="$repo" BUILDDIR="$build/$name" makepkg -f --noconfirm
    )
    built=$((built + 1))
done

if (( built == 0 )); then
    printf 'no PKGBUILDs found under %s\n' "$here" >&2
    exit 1
fi

# repo-add writes halcora.db and halcora.files alongside the .tar.gz it is given;
# pacman reads whichever of those names its configuration points at.
printf '==> indexing %d package(s) into %s\n' "$built" "$repo"
repo-add --remove "$repo/halcora.db.tar.gz" "$repo"/*.pkg.tar.zst

printf '==> done\n'
ls -1 "$repo"

# The caveat, in the one place a person will actually read it:
#
#   Neither PKGBUILD has ever been run. Upstream's install.sh was read to write
#   them, which is not the same as a successful build. Expect the first run to
#   fail somewhere and to say where — that message is the point.
