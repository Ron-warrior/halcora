# Testing

**For the human, not for the agent.** An agent that reads this should give it to
the human and then stop; no part of it can be done by an agent.

Nothing in this project has ever been booted. The first run is the most
informative event available, so the point of this document is to get *useful*
information out of it rather than "it didn't work".

---

## Before you start

- A machine you can afford to **erase**. The installer is erase-disk only and
  has never been run. Do not use the machine holding your only copy of anything.
- A USB stick, 4 GB or more.
- The ISO: https://github.com/Ron-warrior/halcora/releases/tag/prealpha
- Optional but very useful: a phone camera.
- Note the machine's GPU, and **check whether Secure Boot is on**.

On Secure Boot: this image is not signed, so with Secure Boot enabled the
firmware will refuse to boot it at all and you will get the machine's own "no
bootable device" or "security violation" message rather than anything from
Halcora. That is not a Halcora bug and there is nothing to debug. Turn it off
in the firmware settings (often `Secure Boot`, `Security`, or `Boot`), or expect
to stop at that message. Report which of the two happened; it is genuinely
useful.

Verify the download first:

    sha256sum halcora-*.iso

It must match the `SHA256SUMS` asset on the release page. If it does not, stop:
the download is corrupt and every later result will be a lie.

Write the ISO to the USB stick with whatever you normally use (Rufus, Etcher,
`dd`). **Rufus in "DD mode".** ISO mode writes a filesystem that will not boot
the way archiso expects.

## The boot test

Do these in order. After each, note the result — the failures are the useful part.

1. Boot the USB stick. UEFI first; if it will not, try the BIOS/legacy entry.
2. Does the boot menu appear? How many entries, and what do they say?
3. Does it reach a graphical login, and does it log in by itself to a `live`
   session without asking for a password? The live session is **X11 on purpose**,
   not Wayland: the installer runs as root through pkexec, and a root Qt
   application cannot reach a user's Wayland socket. The installed system is
   unaffected.
4. Does the Plasma desktop appear? Is it the stock blue Plasma look (expected) or
   something broken?
5. Right-click the desktop → does the application launcher open?
6. Open Firefox. Does it start, and does it have network?
7. Open Dolphin. Does it show `live`'s home?
8. Is there sound? Open System Settings → Audio and see whether devices appear.
9. Look for an **"Install Halcora"** entry in the application launcher. Does it
   appear, and does clicking it open a window (it will ask for a password via
   pkexec; the live account has none, so just confirm a dialogue appears)?

Then reboot without installing. Booting is the test; installing is the next one.

## The install test (only after the boot test passes)

Only on a sacrificial disk.

1. Launch "Install Halcora".
2. Walk through. Note every screen, especially the partition screen and the user
   screen.
3. Let it finish. Reboot, removing the USB stick.
4. Does the installed system boot to its own login screen?
5. Does the account you created log in with the password you gave?
6. If **not** bootable: is there a GRUB menu at all, or a black screen, or
   `grub>`? That distinction is the single most valuable thing in the report.

## If it does not boot at all

The shape of the failure is worth more than the failure. These four are
different problems with different fixes, and telling them apart takes one
sentence:

1. **The firmware message, no boot menu.** Nothing from Halcora appears. Suspect
   Secure Boot first (above), then how the stick was written (Rufus must be in
   DD mode).
2. **The boot menu appears, then the screen goes black or the machine restarts.**
   Boot the second menu entry instead and photograph the last lines of text
   before it dies.
3. **It reaches `archiso#` or a login prompt on a black screen.** This is the
   *most informative* outcome: the live system works and the graphical session
   did not start. Photograph that screen. It means the kernel, the squashfs and
   the accounts are all fine and the problem is small.
4. **The menu appears and nothing is selectable, or the menu never times out.**
   Say so; that is the bootloader configuration, not the hardware.

If you can get a shell at any point — outcome 3 gives you one — this single
command is the most useful thing you can send back:

    journalctl -b -p err --no-pager

Copy the output, or photograph the screen. It is worth more than the rest of the
report put together.

## Report template

Copy this, fill it in, send it back verbatim. Skim-reading a vague description
costs the agent a 40-minute build cycle.

    Machine:        (CPU / GPU / RAM, Secure Boot on or off, UEFI or BIOS)
    ISO sha256:     (matched the release? yes/no)
    USB tool:       (Rufus DD / Etcher / dd / …)

    Boot menu:      (appeared? entries visible?)
    Live session:   (login? desktop? which look?)
    Launcher:       (opens? "Install Halcora" present?)
    Network:        (yes/no — wired or wireless)
    Sound:          (yes/no)
    Dolphin:        (opens? home shown?)
    Installer:      (opens? which screen did it stop on?)
    journalctl -b -p err:  (paste, or "no shell available")

    First thing that went wrong:
    Exact text of any error, if there is one:
    Photo/screenshot:

## What not to bother reporting

- Subjective taste about the look. There is no skin yet; it is stock Plasma on
  purpose, and TASK-6 handles that.
- Missing applications. The package list is deliberately minimal.
- That it is not Windows. That is the point of the project.
