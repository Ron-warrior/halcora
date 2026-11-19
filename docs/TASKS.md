# Tasks

**Do the first unfinished task only.** Not two. Not "while I'm here".

Each task states what done looks like, so you can tell whether you finished.
If you cannot tell, you have not finished.

---

## TASK-1 — HUMAN: boot the ISO and report

- [ ] Blocked on a person, not on the agent.

Give the human `docs/TESTING.md` and wait. On Windows, the easiest route is
`windows/Halcora.cmd`, described in `windows/README.md`; it runs the ISO in a
QEMU window without touching the Windows disk. Do not guess at results, and do not
"pre-emptively fix" things you suspect might be wrong: the first boot report is
the most valuable data this project will ever get, and changes made before it
arrive contaminate it.

**Done looks like:** a human message containing a filled-in copy of the report
template from `docs/TESTING.md`.

**Agent action while waiting:** only TASK-2.

---

## TASK-2 — AGENT: keep the checks green

- [ ] `.github/workflows/check.yml` passes on `main`.

Run it, read it, fix what it names. It checks what this project's CI has actually
broken before: package names that do not exist, shell scripts that do not parse,
Calamares YAML that does not load.

**Done looks like:** the `Check` workflow green on the latest `main`.

**Do not** use this task as an excuse to refactor. It is a janitor's job.

---

## TASK-3 — AGENT: fix the first thing the boot report says is broken

- [ ] Waiting on TASK-1.

Read the human's report. Fix **one** problem: the first one, the earliest in the
boot sequence. Do not fix three at once; if the second fix is wrong you will not
know which change caused what.

Consult the failure-to-action table in `docs/HANDOFF.md` first.

**Done looks like:** a pushed fix, a green CI run, and a request for the human to
re-test the same thing.

---

## TASK-4 — AGENT: the two layout packages (on a branch)

- [ ] PKGBUILDs written, never built. Merged to `main` in `8767d41`.

Write the PKGBUILDs that `packages/README.md` describes:

- `halcora-lookandfeel-win` — wraps `vinceliuice/Fluent-kde` (GPL-3.0)
- `halcora-lookandfeel-macos` — wraps `vinceliuice/WhiteSur-kde` (GPL-3.0)

Both install a Plasma Global Theme under the id `org.halcora.lookandfeel.*`.
Pin upstream by commit, never by branch: `scripts/fetch-themes.sh` prints the
current HEADs. Read each upstream's `install.sh` before using it; do not assume
its flags.

**Done looks like:** `makepkg` builds both packages on Arch without network
tricks. This has **not** happened. What exists is two recipes written against
upstream's actual installers, and CI that checks they parse, that each `pkgname`
matches its directory, and that every layout id the switcher asks for is
produced by some package.

**Still missing, deliberately:** icon and cursor themes (upstream's
`Fluent-icon-theme`, `WhiteSur-icon-theme`, `WhiteSur-cursors`), and a pacman
repository to build against. `packages/README.md` lists both.

**Branch, not `main`:** these are unverified and would be baked into the next ISO.

---

## TASK-5 — AGENT: strip live-session leftovers after install

- [ ] Not started. Only after an install has succeeded once.

The installed system inherits the `live` account, the SDDM autologin and the
installer's `.desktop` entry. A Calamares `shellprocess` module removes them.

**Do not start this before TASK-1 and TASK-3.** Adding modules to an installer
that has never run makes the next failure harder to attribute, not easier.

**Done looks like:** installs twice, and the second install has no `live` user.

---

## TASK-6 — the HyperOS theme

- [ ] Palette written; shapes not started.

The only authored design work. Fork Fluent-kde's geometry, recolour to the
HyperOS palette, Inter as the UI face. `docs/DESIGN.md` has the rules and
`docs/DECISIONS.md` ADR-4 has the reasoning.

**Done so far:** the palette, the window decoration and the Kvantum config, plus
a Plasma style recolour that decompresses each `.svgz`, remaps the colours and
recompresses it — and **skips the style with a build-log note if nothing
matched**, because those literals have never been read and an unmodified copy
would look like a finished theme.

**Still open:** the Plasma style map has to be verified against a real build. If
the map is wrong the style silently does not ship. That is one line in a build
log, and it is the next thing to look for.

**Read this before touching the recolour.** Fluent-kde's Plasma style is not
plain SVG: the files under `plasma/desktoptheme/Fluent/` (note: `Fluent`, not
`Fluent-dark` — that name is created by the installer) are `.svgz`, i.e. gzipped.
A `sed` over them matches nothing. The map currently guesses that the style uses
the same palette as the Kvantum config, which was read. Verify it rather than
extending the guess.

**Honest expectation:** it will look like recoloured Fluent long before it looks
like HyperOS. That is expected. Do not stall the queue waiting for beauty.

---

## TASK-7 — NVIDIA, and the parts of first run that remain

- [ ] Boot entry and first-run question done; `chwd` not started.

`chwd` at install time, and the proprietary driver itself. The other two pieces
exist:

- `iso/build.sh` generates a second UEFI boot entry from archiso's own, with
  `module_blacklist=nouveau`. It boots the same kernel with the same absent
  driver, so it changes nothing until `chwd` runs at install time: it is the
  entry point for the work, not the work.
- `halcora-first-run` asks one question at login — Windows or macOS layout — and
  offers Xiaomi's MiSans page. It writes its marker before asking.

**Still missing:** `chwd` in the Calamares sequence, and any evidence that the
proprietary driver loads on the RTX 2060. `docs/DECISIONS.md` ADR-8.

---

## Explicitly not queued

Do not start these, and do not ask whether you should:

- Translations, i18n, RTL.
- ARM, RISC-V, non-x86_64.
- Any Windows application compatibility, or mentioning `.exe` anywhere.
- A custom compositor, shell, store, installer or package manager.
- Reproducible builds, a signed repository, update infrastructure.
- Renaming anything.

The reasons are in `docs/DECISIONS.md` and `docs/VISION.md`. If you think one of
them is wrong, write down the argument in your reply and let the human decide.
