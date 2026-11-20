# Decisions

Architecture decision records, in the order they were settled. Each one closes a
door; the closed door is stated so it does not get re-litigated.

## ADR-0 — ISO first, then the skin

**Decision:** the first deliverable is a bootable live ISO with a working
installer. The HyperOS skin and the layout packages come after it.
**Why:** the project's real risk is in the image and the installer. A skin that
looks right inside a machine that cannot install is a demo. The skin is also
where the design work is, and it is the part most likely to change once the
image exists and people have tried it.
**Closed off:** designing the shell in isolation before there is an installable
image to put it in.

## ADR-1 — Arch Linux as the base, with glibc

**Decision:** Arch, pacman, glibc.
**Why:** Arch is the least opinionated base available for assembling from parts
— no SELinux policing, no ostree, no desktop patch stack to fight — and its
package corpus is the parts bin. glibc is forced, not chosen: NVIDIA's
proprietary userspace requires glibc 2.27 and checks for `/lib/libc.so.6`, and
the target machine has an RTX 2060.
**Closed off:** musl, and therefore the "clean Alpine-style userland" idea. A
musl host would mean nouveau + NVK only, with no CUDA and less certain
VM-accelerated graphics. Revisit only if the target hardware changes.

## ADR-2 — KDE Plasma 6 as the shell, not a custom compositor

**Decision:** Plasma, themed. No custom shell, no custom compositor.
**Why:** Plasma's Global Theme packages already bundle panel layout, colour
scheme, Plasma style, icons, cursors, decorations, splash and fonts as
replaceable files, and `plasma-apply-lookandfeel` swaps them non-interactively.
Everything the design needs lives at that layer. libadwaita was rejected because
it deliberately resists deep restyling.
**Closed off:** an original QML shell. Revisit only if Plasma's theme layer turns
out to be insufficient for a specific component, in which case replace that
component, not the shell.

## ADR-3 — Two layouts, both skinned HyperOS

**Decision:** `win` (default) and `macos` (option). Not a third "HyperOS layout".
**Why:** HyperOS is a surface language, not a skeleton. Making it a third layout
would mean inventing a spatial model with no reference, and the Windows desktop
mode Xiaomi already ships proves HyperOS reads correctly on a Windows-style
taskbar.
**Closed off:** a HyperOS-branded third skeleton.

## ADR-4 — Build the HyperOS theme by recolouring Fluent-kde

**Decision:** `halcora-theme-hyperos` starts as a fork of Fluent-kde's geometry
and KVantum/Aurorae SVG scaffolding, recoloured to the HyperOS palette, not
authored from zero.
**Why:** No HyperOS theme exists for KDE Plasma — the stores contain only Android
theme packages and one unlicensed GNOME bundle. Fluent's geometry (soft rounded
rectangles, centred, generous padding) is the closest Plasma work to HyperOS, is
GPL-3.0, and is already Plasma-6-shaped with correct `metadata.json`.
**Known limitation:** this yields a recognisably HyperOS-flavoured theme, not a
pixel-accurate reproduction. Say so; do not oversell it.
**Closed off:** porting the GNOME HyperOS bundle, whose asset licences are
vague and which ships a font we may not redistribute.

## ADR-5 — Inter shipped, MiSans never bundled

**Decision:** Inter (OFL-1.1) is the shipped face. MiSans is an optional,
user-initiated download at first run.
**Why:** Xiaomi's MiSans licence grants commercial *use* but expressly prohibits
redistributing the font files or their components. Bundling it in an ISO, a
package, a Flatpak or a GitHub release is a licence violation.
**Closed off:** a MiSans default. Also closed: copying assets from
`iijawadm/hyperos-theme`, which ships MiSans itself.

## ADR-6 — archiso rather than mkosi for the ISO

**Decision:** archiso profile, built with `mkarchiso`.
**Why:** archiso is purpose-built for boot menus, a live session, a squashfs
image and an `airootfs` overlay, and there are two maintained production
archiso+Calamares profiles to copy (CachyOS, EndeavourOS) plus one minimal
template (ALCI). mkosi produces OS images, not installable live media, and has no
Calamares plumbing — we would be rebuilding glue that already exists.
**Closed off:** mkosi as the image path. It remains useful for quick rootfs
iteration during development.

## ADR-7 — Stock Calamares with lifted configuration (open)

**Decision:** take the ALCI configuration shape (stock Arch + stock Calamares)
and lift EndeavourOS's `data/eos` branding, module configs and slideshow, using
stock Calamares modules only.
**Why:** EndeavourOS's tree is the most complete `/etc/calamares` available, but
it calls modules that exist only in their fork.
**Still open:** whether to strip those modules and lose their niceties, or build
EndeavourOS's Calamares fork and inherit them. Decide at phase 3, when we know
which modules we actually want. Note that Calamares is AUR-only on Arch, so
either way we build it ourselves.

## ADR-8 — NVIDIA for Turing, detected by chwd

**Decision:** install `nvidia-open` for Turing and later via `chwd` during
installation; ship two live boot entries, the default one on nouveau and a
second explicitly for NVIDIA.
**Why:** Turing is officially supported by the open kernel modules and NVIDIA
recommends them; `nvidia-utils` already enables `nvidia_drm.modeset=1`. The
two-entry live boot is the pattern EndeavourOS has proven
(`module_blacklist=nouveau,nouveau_drm nouveau.modeset=0` on the NVIDIA entry).
**Closed off:** nouveau-only. Also closed: trying to make the proprietary driver
work under musl.

## ADR-9 — Discover plus a featured-listing file is the store

**Decision:** KDE Discover, with Flatpak enabled and a curated
`featuredurlrc` pointing at our own JSON. No custom storefront.
**Why:** Discover already provides the whole UI; its pacman support is real
(`packagekit`'s `libpk_backend_alpm.so`) if flagged "use at your own risk" by
Arch, and the featured listing is a documented one-file customisation.
**Open:** whether to expose the pacman backend at all, or show only Flatpak to
users and keep pacman for our own packages. Lean towards Flatpak-only in the UI
— it is the safer surface for someone who has never seen a Linux dependency.

## ADR-10 — Migration mounts Windows read-only and never forces

**Decision:** the import tool mounts the Windows volume `ro`, refuses to proceed
on a dirty volume, and tells the user to boot Windows once and shut down cleanly.
**Why:** `ntfs3` refuses dirty volumes without `force`, has no fsck, and Fast
Startup leaves volumes permanently dirty. Writing is how migrations corrupt data.
**Closed off:** any read/write migration path.

## ADR-11 — English only, no i18n framework

**Decision:** no translations, no RTL support, no locale QA.
**Why:** it reduces scope and matches the audience. It is free to reverse later;
adding i18n is easier than removing it.

## ADR-12 — Familiarity yes, impersonation no

**Decision:** interaction patterns may be copied freely; assets, logos, fonts and
product names may not.
**Why:** taskbar/Start/tray layouts are unprotectable patterns, and Zorin OS
proves they can be shipped. Windows wallpapers, icons, logos and the word
"Windows" in the product are a legal and reputational hazard — see `LEGAL.md`.
**Closed off:** any "Windows-compatible" marketing, in any wording.


## ADR-13 — A layout is our id wrapped around someone else's theme

**Decision:** `halcora-lookandfeel-win` and `-macos` rename upstream's Global
Theme to `org.halcora.lookandfeel.win` / `.macos`, rather than exposing
`com.github.vinceliuice.…` and pointing the switcher at that.
**Why:** `scripts/halcora-layout` is the product's flagship feature and it should
name a *layout*, not a theme author. With our ids, the upstream theme providing a
layout can be replaced — Fluent replaced by a HyperOS-flavoured fork, or by
something better later — without touching the switcher, the docs, or anything a
user has saved. It also keeps the two packages interchangeable rather than making
one of them the one true Windows theme.
**Closed off:** pointing the switcher at upstream ids directly.

## ADR-14 — A layout package carries no palette

**Decision:** the layout packages delete `ColorScheme=` and `cursorTheme=` from
the Global Theme's `contents/defaults`, and do not install upstream's `.colors`
files at all.
**Why:** `DESIGN.md` gives the palette to `halcora-theme-hyperos` exclusively, so
that the macOS layout can wear it without layout code changing. A Global Theme
that also sets a colour scheme silently makes "switch layout" mean "switch
light/dark", which is exactly the averaged behaviour the design rules forbid. The
cursor line is removed for a narrower reason: it names a cursor set these packages
do not ship, so it would be a promise the system cannot keep.
**Open:** the icon theme line is left in place and Plasma falls back. Folding
`Fluent-icon-theme` and `WhiteSur-cursors` in is follow-up work.
**Closed off:** bundling a palette into a layout.

## ADR-15 — Pin a commit; a checksum is optional, a guess is not

**Decision:** every package pins an upstream commit. The source may be a git
repository at `#commit=<sha>` with `sha256sums=('SKIP')`, or an archive tarball
with a real checksum — whichever the maintainer can actually verify.
**Why:** this repository is maintained from a device with no shell. A tarball
`source=` requires a `sha256sums` entry, and inventing one is worse than not
having one: it looks verified. A commit-pinned git source is reproducible without
a checksum, so `SKIP` is the honest value rather than a shortcut. When a machine
that can run `updpkgsums` exists, switch to the archive form, which is lighter to
download.
**Closed off:** tracking a branch or a tag, and any checksum written by hand.


## ADR-16 — An offline installer cannot fetch a driver

**Decision:** no automatic driver installation at install time. The second UEFI
boot entry exists, the NVIDIA packages stay out of the image, and installing the
proprietary driver is a documented step after first boot until there is a way to
pay for it.

**Why:** ADR-8 said "install `nvidia-open` via `chwd` during installation". That
assumes the installer can fetch packages. Ours cannot: Calamares unpacks the live
squashfs and downloads nothing, which is the property `iso/README.md` and
`ADR-0` both lean on. The three ways out, none of them free:

- **Put the driver in the image.** `nvidia-open` plus `nvidia-utils` is a few
  hundred megabytes, and the ISO has 117 MiB of headroom under GitHub's 2 GiB
  release-asset limit. It would also ship the driver to every user, including the
  ones whose hardware must keep nouveau.
- **Make that one step network-dependent.** Honest, but it breaks "an offline
  install is the least surprising thing an installer can do", and it fails on the
  machine with a Broadcom or Realtek Wi-Fi card and no wired network — which is
  exactly the machine a Windows refugee has.
- **A second ISO variant** with the driver included. Doubles the build and the
  release surface, and doubles what has to be tested.

**Closed off:** quietly adding `nvidia-open` to the package list because the
target machine happens to have an RTX 2060. The image is for everyone.

**Open:** which of the three to take. It should be decided after a first install
succeeds, because the answer depends on how the installer behaves on the target
machine, and nothing about that is known yet.


## ADR-17 — Halcora installs itself

**Decision:** replace Calamares with `iso/overlay/usr/local/bin/halcora-install`,
a shell script built from tools that already ship in the Arch base system.

**Why:** the project's rule changed. Until now the brief was to borrow and glue;
the aim now is independence from upstream, the way HarmonyOS moved off AOSP.
Calamares was the largest upstream dependency in the install path: an AUR-only
package we built from source in CI, with its own module model, its own
configuration language and its own release cycle. Every installer bug this
project has had was a mismatch between our files and its expectations. The
replacement is about two hundred lines and one language.

**What changed:**
- Calamares removed from both package lists, from `iso/build.sh`, and from CI —
  no out-of-tree build, no `INSTALL_CONFIG=OFF`, no staged `usr/`.
- Its `/etc/calamares` tree deleted from the overlay.
- The launcher opens a Halcora-titled Konsole and runs the script under pkexec;
  the polkit rule names `halcora-install` and nothing else.

**Closed off:** going back to Calamares. If the installer is a problem, the fix
is in the script.

**Not done:** nothing here has run on hardware. A graphical installer — the thing
Calamares actually gave us — is a later job, and the Konsole window is the honest
intermediate rather than a few dialogs wrapped around prompts they hide.

**Revisit if:** the script cannot be made to survive a real install, in which case
the answer is still ours, just a different implementation of it.
