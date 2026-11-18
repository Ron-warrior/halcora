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

# Yes is Windows, No is macOS, and closing the dialog is a cancellation — but the
# desktop still has to end up consistent. A cancelled run therefore applies the
# default layout rather than leaving the session with Breeze's icons and no
# decoration, which would look broken rather than undecided.
#
# The status is captured rather than tested with an if/else, because under
# `set -e` a "No" and a closed window are different exit codes and only one of
# them is 1; testing `$?` inside an else branch would abort the script on the
# other.
layout=win
set +e
kdialog --title 'Welcome to Halcora' --yes-label 'Windows' --no-label 'macOS' --yesno \
    'Start with the Windows-style layout?\n\nChoose No for the macOS-style layout. You can switch at any time with halcora-layout.'
answer=$?
set -e

case "$answer" in
    0) layout=win ;;
    1) layout=macos ;;
    *) layout=win ;;
esac

halcora-layout "$layout" || true

# MiSans is offered, never bundled: Xiaomi's licence allows use but not
# redistribution of the font files (docs/LEGAL.md). A link is the whole feature.
if kdialog --title 'Fonts' --yesno \
    'HyperOS uses a typeface called MiSans. Halcora cannot ship it, because its licence does not allow redistributing the files.\n\nOpen Xiaomi'"'"'s page to download it yourself?'
then
    xdg-open 'https://hyperos.mi.com' >/dev/null 2>&1 || true
fi

exit 0
