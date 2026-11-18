# Handoff

For an agent with less context than the one that wrote this. Everything here is
either a procedure you can follow mechanically or a fact you cannot derive from
the code. If something is neither, it is not in here on purpose.

Read `AGENTS.md` first if you have not.

---

## The mental model, in six sentences

Halcora is an Arch Linux distribution built by archiso. We do not write a
desktop: we package KDE Plasma and change its Global Theme, which is a bundle of
panel layout, colours, icons, cursor and window decoration as plain files. We do
not write an installer: we configure Calamares, which unpacks the live system's
squashfs image onto the target disk. So almost all "our" code is configuration,
and the two scripts in `scripts/` are genuinely small. The design goal is that
someone arriving from Windows finds nothing to relearn, and the visual goal is
HyperOS on top of a Windows-shaped skeleton. None of it has been tested.

## What "verified" means here

Three different claims get confused. Keep them apart in everything you write:

- **"CI is green"** — GitHub built an ISO. Checkable by you. Say only this.
- **"The human booted it"** — checkable only via their report. Quote it.
- **"It works"** — never say this. You cannot know.

---

## Procedures

### P1 — Change the package set

1. Read `iso/profile/packages.x86_64`.
2. Edit it. One package name per line, `#` comments allowed.
3. Confirm each name exists: https://archlinux.org/packages/?q=NAME
   (a name that does not exist fails the build with `target not found`).
4. Remember the 2 GiB limit in `docs/STATE.md`. Prefer removing something to
   adding something.
5. Commit, push to `main`, read the `ISO` workflow result.

### P2 — Add or change a file in the live system

1. Put it under `iso/overlay/`, mirroring the path it should have on the target
   (e.g. a file for `/etc/foo.conf` goes to `iso/overlay/etc/foo.conf`).
2. If it needs an owner or mode other than 644/755 owned by root, add an entry to
   `file_permissions` in `iso/profile/profiledef.sh`. mkarchiso flattens
   airootfs otherwise, and a config that needs 0400 will silently be 0644.
3. Commit, push, read CI.

`iso/overlay/` is copied over the live root **after** packages install, so it
wins over anything a package ships.

### P3 — Change how the image is built

Only `iso/build.sh`. It must stay runnable as `bash iso/build.sh`. If you add a
step, put it before the final `mkarchiso` call, and keep the comments explaining
*why* — they are the only defence the next agent has.

**Never** vendor archiso's `releng` profile into this repo. `build.sh` copies it
from `/usr/share/archiso/configs/releng` at build time. That is deliberate: it
means we cannot drift out of sync with archiso, and it is why this repo has so
little in it.

### P4 — Read a CI failure

1. Open the `ISO` workflow run on GitHub, or use the checks tool.
2. Read the **last** failing step, not the first line of the log.
3. Match it against the table below.
4. Fix exactly that. Push. Do not bundle a second speculative fix.

### P5 — Update the state

At the end of every session, edit `docs/STATE.md`:

- the `Last verified` date and commit
- anything you learned that a future agent could not derive from the code
- the blocker, if it moved

A stale `STATE.md` is worse than no `STATE.md`, because the next agent will
trust it.

### P6 — Build and index the theme packages

1. `./packages/build.sh` as a normal user, never root. It runs `makepkg` per
   package directory and then `repo-add` into `packages/repo`.
2. Expect it to fail the first time. Neither `PKGBUILD` has ever been built, and
   "upstream's install.sh was read carefully" is not the same claim as "it
   builds".
3. Fix exactly the thing it names, rerun, then commit. Do not add a package, and
   do not relax a check, to make a failure go away.
4. If a layout package builds, `plasma-apply-lookandfeel --list` on a Plasma 6
   machine should show `org.halcora.lookandfeel.win` and `.macos`. That is the
   check that the rename worked, and no CI job can do it.
5. Once the repository builds, an image that contains the packages is one
   environment variable away:

       sudo HALCORA_STAGE=… HALCORA_REPO=… ./iso/build.sh

   Without `HALCORA_REPO` the ISO is unchanged, which is why CI can keep
   building it before any of this works.

---

## Failure to action

- **`exit 126` on `./iso/build.sh`** — not executable after checkout. Already
  fixed by invoking `bash ./iso/build.sh`. Do not re-add a bare `./`.
- **`error: target not found: NAME`** — that package name does not exist or is
  misspelled. Check on archlinux.org. Do not guess a near-miss.
- **`error: target not found` for a package that certainly exists, and the job
  dies in about ten seconds** — you are in the `Check` workflow and it ran a
  `pacman -S` before a `pacman -Sy`. `archlinux:latest` ships no package
  databases at all. The first pacman command in that workflow must sync them.
  Do not "fix" this by adding the package to a list.
- **`No such file: /…` in `file_permissions`** — you listed a path that is not in
  the profile. Add the file, or drop the entry.
- **`syslinux.cfg`/BIOS boot errors** — `bootmodes` includes `bios.syslinux`, so
  `syslinux` must be in `packages.x86_64`. It was missing once.
- **Calamares `cmake` fails on a missing KF6/Qt6 lib** — add the package to the
  `pacman -S` line in `iso.yml`. The list mirrors the AUR recipe's dependencies.
- **Calamares builds but the image's config is wrong** — check
  `INSTALL_CONFIG=OFF` is still in `iso.yml`, and that `build.sh` copies only
  `usr/` from the stage. Copying `etc/` replaces our config with upstream's.
- **Release step 422** — almost certainly the 2 GiB cap. `iso.yml` now measures
  the ISO first and says so; if the failure is the upload itself, remove packages.
- **`mkarchiso` finishes but no ISO in `out/`** — check `iso_name` and
  `install_dir` in `profiledef.sh`; `out/*.iso` is a glob and a naming change can
  put the file elsewhere.
- **`makepkg` fails inside `build()`, running an upstream `install.sh`** — the
  upstream moved. Re-read its `install.sh` and its tree rather than guessing at
  flags, and bump the commit in `source=` and the version in `pkgver` together.
  `scripts/fetch-themes.sh` prints the new HEAD.
- **`cp: cannot stat …/plasma/look-and-feel/…` in a layout package** — upstream
  renamed its Global Theme directory. `package()` copies named items on purpose:
  a wildcard would also ship the Liquid and HiDPI variants upstream installs
  unconditionally. Update the names.
- **`Running makepkg as root is not allowed`** — correct, and load-bearing. The
  layout packages let upstream's installer choose between `$HOME` and
  `/usr/share` based on `$UID`, so building as root would write to the build
  machine's `/usr/share`. Run `packages/build.sh` as a normal user.
- **A layout id disappears from `plasma-apply-lookandfeel --list`** — the
  `Id`/`X-KDE-PluginInfo-Name` rename in the PKGBUILD stopped matching. The
  check workflow catches the opposite case (an id no package produces), not a
  rename that silently half-worked.
- **Anything about `profiledef.sh` variables** — compare against upstream's
  `configs/releng/profiledef.sh` for the archiso version Arch currently ships.
  Ours is meant to mirror it exactly except for naming and `file_permissions`.

---

## Do not

- Do not add translations, ARM support, or Windows application compatibility.
- Do not add a second package manager, build system, or dependency.
- Do not "clean up" files the task did not ask about. This repo is small and
  deliberately sparse; apparent dead ends are usually documented decisions.
- Do not rewrite `docs/DECISIONS.md` decisions to match what you did. If you
  disagree with one, say so in your reply.
- Do not invent upstream behaviour — Calamares module names, Plasma theme ids,
  archiso variables. If you have not read it, say you have not read it.
- Do not create a GitHub release by hand. CI owns the `prealpha` tag.
- Do not promise a fix. Report what you changed and what CI said.

---

## Glossary

- **archiso** — the Arch tool that builds a live ISO from a *profile*.
- **releng** — archiso's own reference profile (`configs/releng`). We overlay it.
- **`mkarchiso`** — the command that does the build. Runs as root, mounts things,
  needs loop devices, hence the privileged container in CI.
- **`airootfs`** — the live system's root filesystem, before it is packed.
- **overlay** — our files copied over `airootfs`. `iso/overlay/` here.
- **squashfs** — the compressed read-only image the live system boots from.
- **Calamares** — the installer. Not in the Arch repos; CI builds it from
  Codeberg tag `v3.4.3`.
- **`unpackfs`** — the Calamares module that copies the live squashfs to disk.
  This is why the installed system is exactly the live system.
- **Global Theme / KFE / Look-and-Feel** — one Plasma package containing panel
  layout, colours, icons, cursor, decoration, splash. Swappable at runtime with
  `plasma-apply-lookandfeel`. This is the whole layout-switcher feature.
- **SDDM** — the login screen. Ours autologins the `live` account.
- **sysusers.d** — declarative user creation at boot. Our `live` user comes from
  `iso/overlay/etc/sysusers.d/live.conf`, not from a hand-written `/etc/passwd`.
- **nouveau** — the open NVIDIA driver. The live session uses it; the proprietary
  driver is a later task.
- **`prealpha`** — the single moving pre-release tag CI publishes to.

---

## If the repo has changed since this was written

It will have. Check, in this order:

1. `git log --oneline -15` — what happened since `33fee82`.
2. `git branch -a` — unmerged work. `themes/lookandfeel` holds the two layout
   packages and `packages/build.sh`; read its `docs/STATE.md` entry before
   assuming it is finished.
2. `docs/STATE.md` — the previous agent's verified state. Trust its *dates*, not
   its optimism.
3. `docs/TASKS.md` — which checkboxes are ticked. The first untutored one is yours.
4. `git diff 33fee82..HEAD --stat` — the shape of the change.

Then re-verify the two facts that matter most, because they expire:

- the ISO's size against the 2 GiB cap (`docs/STATE.md` has the number to beat);
- whether anyone has booted it yet, which is either in `STATE.md` or is still "no".

If this document contradicts the code, **the code wins**, and you should fix this
document in the same commit.
