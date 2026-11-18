#!/bin/sh
# fetch-themes.sh — resolve the exact upstream commits our packages pin.
#
# Build-time tool, never shipped. Upstream themes are actively developed, so a
# package that tracks a branch is a package that breaks its own reproducibility.
# Run this before bumping a PKGBUILD and paste the commit into `source=` and
# `pkgver`.
set -eu

repos="
vinceliuice/Fluent-kde
vinceliuice/Fluent-icon-theme
vinceliuice/WhiteSur-kde
vinceliuice/WhiteSur-icon-theme
vinceliuice/WhiteSur-cursors
vinceliuice/WhiteSur-gtk-theme
rsms/inter
"

for repo in $repos; do
    sha=$(git ls-remote "https://github.com/$repo.git" HEAD | cut -f1)
    printf '%-38s %s\n' "$repo" "$sha"
done
