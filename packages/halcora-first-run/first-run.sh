#!/bin/sh
# halcora-first-run — one question, once.
#
# The only place this project asks anything of a user: which layout. Everything
# else is a default. It runs from an autostart entry, writes a marker so it never
# asks twice, and does nothing at all when there is no way to show a dialog
# (a terminal session, a failed Plasma start).
#
# It is deliberately not a wizard. A first-run wizard with four screens is a
# product decision about what the OS thinks it knows better than the user. One
# question is a question; more is an interrogation.
set -eu

marker="${XDG_CONFIG_HOME:-$HOME/.config}/halcora/first-run-done"
[ -e "$marker" ] && exit 0

if ! command -v kdialog >/dev/null 2>&1; then
    exit 0
fi

# Written before the questions, not after: a user who closes the dialog has
# answered, in the only way that matters, and being asked again at every login
# is worse than a question that was skipped.
mkdir -p "$(dirname "$marker")"
: >"$marker"

if kdialog --title 'Welcome to Halcora' --yesno \
    'Start with the Windows-style layout?\n\nChoose No for the macOS-style layout. You can switch at any time with halcora-layout.' \
    --yes-label 'Windows' --no-label 'macOS'
then
    halcora-layout win || true
else
    halcora-layout macos || true
fi

# MiSans is offered, never bundled: Xiaomi's licence allows use but not
# redistribution of the font files (docs/LEGAL.md). A link is the whole feature.
if kdialog --title 'Fonts' --yesno \
    'HyperOS uses a typeface called MiSans. Halcora cannot ship it, because its licence does not allow redistributing the files.\n\nOpen Xiaomi'"'"'s page to download it yourself?'
then
    xdg-open 'https://hyperos.mi.com' >/dev/null 2>&1 || true
fi

exit 0
