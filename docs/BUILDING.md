# Building it

The shortest path from this repository to a desktop you can look at. Every step
below runs on a machine, which is why none of it has happened yet.

Read `docs/STATE.md` first if you want to know what is verified. This page is
purely mechanical.

---

## 1. Build the packages

Needs Arch, a normal user account (not root), and network for the source
checkouts.

    sudo pacman -S --needed base-devel
    ./packages/build.sh

It runs `makepkg` per directory and then `repo-add`, leaving a pacman repository
in `packages/repo`.

**Expect the first run to fail.** Eleven recipes, none ever built. Each failure
names a file and a line; fix that one and run it again. Do not add a package or
relax a check to make a failure go away.

The most likely first failures, in order:

- a `source` alias that does not match the directory the build `cd`s into — the
  alias must be spelled exactly like the upstream repository;
- a tool a recipe declares in `makedepends` but the machine lacks;
- the Plasma style recolour reporting that it matched nothing, which is a warning
  and not a failure: the palette still installs.

## 2. Build the image with those packages in it

    sudo HALCORA_REPO=$PWD/packages/repo ./iso/build.sh

That adds a `[halcora]` stanza to the profile's `pacman.conf` and the ten
`halcora-*` packages to its package list. Without `HALCORA_REPO` the image builds
exactly as it does in CI, with stock Plasma and no Halcora packages at all.

The output is `out/halcora-*.iso`.

## 3. Boot it

`docs/TESTING.md` is the protocol, including what to do when it does not boot and
the four ways that can look.

Boot the USB stick. At the boot menu there are two entries: the default one, and
one marked **(NVIDIA)** which blacklists nouveau. On the RTX 2060 either works —
neither loads a proprietary driver yet — so the default is the one to use.

If the packages built and were included, the first login asks one question: Windows
layout or macOS layout. That is the whole of the design showing up at once.

## 4. Send back the report

`docs/TESTING.md` has the template. The `journalctl -b -p err` line is worth more
than the rest of it put together.

---

## If you only want to look at the theme

You do not need the ISO for that. On any Plasma 6 machine:

    sudo pacman -S --needed base-devel
    ./packages/build.sh
    sudo pacman -U packages/repo/halcora-*.pkg.tar.zst

Then `halcora-layout win` and `halcora-layout macos`. That shows the layouts, the
icons, the window decoration and the HyperOS palette without touching a boot
loader, an installer or a partition.
