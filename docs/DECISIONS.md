# Decisions

Architecture decision records, in the order they were settled. Each one closes a
door; the closed door is stated so it does not get re-litigated.

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

**Decision:** `tessera-theme-hyperos` starts as a fork of Fluent-kde's geometry
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
