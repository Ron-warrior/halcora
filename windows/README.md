# Running Halcora on Windows

Download **Halcora.exe** from
https://github.com/Ron-warrior/halcora/releases/tag/prealpha and double-click it.
No installer, no .NET runtime, nothing to configure.

Halcora runs as a window inside Windows. It does not replace Windows, and it
cannot touch your Windows disk: the installer writes to a single file in
`%LOCALAPPDATA%\Halcora`.

**Status: never run on Windows.** `Halcora.exe` is compiled and its sizing logic
is self-tested by CI on a real Windows machine, but nobody has double-clicked it.
Every step reports what it was doing when it fails.

## What the window does

It says what it is taking before it takes it — how much memory, how many cores —
then downloads the image on first run, checks it against the release's checksum,
and starts the virtual machine.

**How much it takes.** Computed every launch from what is actually free. On a
16 GB PC with 6 GB in use there is 10 GB free, so Halcora takes 9 GB and leaves
1 GB spare. It never takes more than three quarters of your RAM, and it takes two
fewer cores than the machine has so Windows stays responsive. If the machine is
busy at launch it takes one core fewer still.

**The disk.** There is no size to choose and nothing is reserved up front. The
virtual disk is a sparse file: it starts near empty and grows only as Halcora
writes to it. The installer is told it has 64 GB so it is not constrained, and
the window shows real usage — a fresh install is a few gigabytes, not sixty-four.
Freed space returns to Windows as the guest discards it.

**The title bar** says Halcora, and so does the window the desktop appears in.

## If it does not start

- **Windows protects your PC.** The executable is unsigned. Click **More info**,
  then **Run anyway**.
- **QEMU is installed on first run.** If that fails, Halcora says so and points
  at https://qemu.weilnetz.de/w64/. Install it and open Halcora again.
- **It is very slow.** Hardware acceleration is off. In an administrator
  PowerShell:

      Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All

  Then restart Windows. Virtualisation must also be on in the BIOS or UEFI,
  usually called "Intel VT-x" or "SVM". Halcora asks QEMU to use acceleration
  when it is there and fall back to software when it is not, so this costs speed
  rather than working.

## What it cannot do

The desktop appears in a **separate window**, titled Halcora, that belongs to the
virtual machine engine. Putting that display inside Halcora's own window means
routing it over VNC, which adds a whole class of connection failures for a
cosmetic gain. It is not done, and this file would rather say so than imply
otherwise.

## Without the executable

`Halcora-VM.ps1` runs the same thing through PowerShell, for machines where the
single-file executable will not start. Same behaviour, same window, no
installation:

    powershell -ExecutionPolicy Bypass -File Halcora-VM.ps1

There is deliberately no `.cmd` wrapper: the static preview publisher in this
project rejects `.cmd` files, and the executable is the real path anyway.

## Starting over

Delete `%LOCALAPPDATA%\Halcora`. That removes the downloaded image and the
installed system. Nothing outside that folder was ever written to.
