# Design

## The rule

**Hierarchise, never average.** Each of the three visual targets owns a different
layer, and when two collide one of them is required to yield. Averaging produces
the uncanny valley: traffic lights spaced like touch targets, a dock that is also
an app drawer, hamburger menus beside a menu bar.

- **Windows** owns the **default skeleton** — layout, launcher position, window
  controls, the habits a switcher already has.
- **macOS** owns the **optional skeleton** — menu bar, dock, Mission Control.
- **HyperOS** owns the **surface** in both cases — geometry, radii, colour,
  type, blur, accent treatment.

macOS is an option. Windows is the default. HyperOS is never optional: it is what
both layouts are wearing, which is why the project is not really a "HyperOS
distro" but a friendliness project with a HyperOS face.

## Type

- UI face: **Inter** (OFL-1.1). One family, variable, four weights in use
  (Regular, Medium, SemiBold, Bold).
- Monospace: the base system's default; do not add one.
- **MiSans is offered, never bundled.** Xiaomi's licence forbids redistributing
  the font files. First-run offers a download link to `hyperos.mi.com` and
  installs it into the user's own font directory if they accept. Do not ship it
  in a package, an ISO, a Flatpak or a release tarball.
- No SF Pro, no SF Symbols. Apple's licences restrict both to designing for
  Apple platforms. The macOS *impression* has to be achieved with Inter and a
  free icon set.

## Geometry

Target values, to be sampled properly from HyperOS screenshots and device
captures during implementation rather than guessed here. The shape of the answer:

- Corner radii: large and consistent — one radius scale (roughly 8 / 12 / 16 /
  24 px) applied to every surface, with pills reserved for toggles and sliders.
- Padding: generous, and uniform between rows. HyperOS's calm comes mostly from
  spacing, not colour.
- Elevation: soft, wide, low-opacity shadows; almost no hard borders.
- Blur: behind panels and menus only, never behind content.

## Colour

HyperOS is a warm, slightly desaturated light surface with a vivid blue accent,
plus a dark scheme that is a genuine redesign rather than an inversion. The
implementation rule is that the palette lives **only** in
`tessera-theme-hyperos`'s colour schemes and Plasma Style SVGs — nowhere else, so
the macOS layout can adopt it without touching layout code.

## Component mapping, layout by layout

**Top of screen.** Windows' taskbar is at the bottom, so the top strip is free.
macOS puts the menu bar there, and the menu bar is the app menu, so it wins in
that layout. Its right-hand status cluster is then drawn in HyperOS style — which
macOS already does, so it is a free merge.

**Launcher.** In the Windows layout: a Start-equivalent at the left of a centred
taskbar, opening HyperOS-styled pills, a search field and an app grid. In the
macOS layout: a Dock plus **Launchpad as the home screen** — a full-screen grid
of large squircle icons with page dots over the wallpaper. Launchpad is the
cleanest mapping in the whole design, because it gives HyperOS's launcher
grammar without breaking the desktop model.

**Control centre.** The one place the two philosophies genuinely converge. Take
macOS's module grid (grouped tiles, sliders, Now Playing) and draw the toggles as
HyperOS pills. GNOME 43's quick settings is the existing midpoint to study.

**Window decoration.** Always on the left in the macOS layout (traffic lights,
drawn as HyperOS circular pills), always on the right in the Windows layout.
Ergonomics from the owning skeleton, material from HyperOS. Button geometry is
`kwinrc` configuration, so it is one of the few places a switch must change
KWin settings — `scripts/tessera-layout` reloads KWin for exactly this reason.

**Recents and workspaces.** Mission Control in the macOS layout (horizontal card
stack). Windows' task view in the Windows layout. Do not use the other one's
idiom: a touch-style card stack is wrong with a mouse, and vice versa.

**Settings.** System Settings' sidebar-plus-pane with HyperOS's colourful rounded
row tiles inside the pane. Cheap, and one of the best blend points.

**Notifications.** Top-right banners in the macOS layout, bottom-right toasts in
the Windows layout, both drawn as HyperOS cards.

## Motion

Pick one motion spec and apply it everywhere. Motion sells "feels like" more than
any static style does, and Apple's springs and Android's interruption-friendly
curves are different languages; mixing them makes a shell feel broken even when
every screenshot looks right. Until we have a reason otherwise: Plasma's default
curves, with durations shortened. Do not attempt to reproduce Apple's springs —
it is the highest-effort, lowest-visibility work in the project.

## Where the design ceiling actually is

- **Weeks:** fonts, icons, radii, blur, window decoration, a global theme. The
  "recognisable" impression.
- **Months:** a genuinely coherent shell — panel, launcher, control centre, lock
  screen, SDDM theme, on-screen displays, settings reskin.
- **Never fully:** third-party GTK and Qt apps. Cross-application consistency is
  most of what makes macOS feel like macOS, and we cannot theme arbitrary apps
  into it. Be honest about this in the release notes; do not claim otherwise.

## Wallpapers

Xiaomi's wallpapers are not ours to redistribute. Author our own in the same
idiom: soft gradients, a single focal object, no text, no logos. Six images
minimum (two per layout, light and dark).
