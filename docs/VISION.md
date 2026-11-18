# Vision

## Who this is for

One specific person, defined precisely, because "everyone" is how desktop Linux
projects die: **a competent Windows user with no interest in learning an
operating system.** They can install software, manage files and change settings.
They have never opened a terminal and will not start.

Their first hour is the product. If it involves the words *package*,
*repository*, *compositor*, *display server*, *dependency*, *kernel* or
*partition table*, it has failed.

## What "friendly" means, concretely

Friendly is not a theme. A Windows-shaped taskbar with a Linux-shaped first-run
experience is still hostile. The bar, in the order it matters:

1. **Nothing to learn.** Win opens the launcher. Alt+Tab, Win+D,
   Win+Left/Right, Ctrl+C. These must work because we did not override
   Plasma's defaults, not because we remapped them.
2. **One way to install software.** A store, one button, no format names. The
   moment a user is asked to choose between a package, a Flatpak and a build
   recipe, the illusion of normality breaks.
3. **The filesystem is invisible.** Home is the world. No root, no `/etc`, no
   permission walls reachable by accident.
4. **Their old computer still works with it.** A Windows NTFS partition or USB
   drive must mount, read-only, first try. Their browser bookmarks and
   documents must be importable without a wiki.
5. **English, and honest.** No untranslated strings, no "this feature is
   experimental" apologetics.

## What we will not promise

- Running Windows software. We can mention Wine; we will never advertise
  `.exe` compatibility, never imply a Windows application will work, and never
  put "Windows" in the product name. (See `LEGAL.md` for why this is both an
  ethical and a legal line.)
- Feature parity with Windows. We are not a replacement; we are a place to move
  to.
- Any hardware. We test on known hardware and say so.

## The honest risk

Ecosystem and hardware enablement are the two things that have killed every
independent desktop OS attempt for fifteen years, and neither is solved by good
design. What this project can realistically be is a *well-fitted small
distribution for people who mostly browse, write, listen and manage photos* —
and it should be judged on that, not against Windows.
