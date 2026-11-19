# Running Halcora on Windows

Double-click `Halcora.cmd` and Halcora opens in a window, inside Windows. It
does not replace Windows, does not touch your Windows disk, and can be closed
like any other window.

**Status: not yet run on Windows.** The launcher is written against QEMU's
documented options and checked by CI for syntax, but no one has double-clicked
it yet. If it fails, the message says which step it was on.

## What you need

- Windows 10 (version 1803 or later) or Windows 11.
- About 25 GB of free disk space: 1.9 GB for the ISO and up to 20 GB for the
  installer's virtual disk.
- 8 GB of RAM or more. The virtual machine takes 4 GB.
- Internet access, for the first download.

## Steps

1. Download `Halcora.cmd` and `Halcora-VM.ps1` into one folder. Both are in
   the `windows/` folder of
   https://github.com/Ron-warrior/halcora. Use "Download ZIP" on that page if
   you prefer, and take the `windows` folder out of it.
2. Double-click `Halcora.cmd`.
   - If Windows says it "protected your PC", click **More info**, then
     **Run anyway**. The file is unsigned.
   - The first run downloads the ISO, which takes a while. It then checks the
     download against the release's checksum before it starts anything.
   - If QEMU is not installed, the launcher installs it with `winget`. Windows
     will ask for permission.
3. A Halcora window opens. It is a live system, so nothing is installed yet.
4. To install, use **Install Halcora** from the application launcher. It erases
   only the virtual disk in `%LOCALAPPDATA%\Halcora`, never your Windows disk.
5. After installing, close the window. Next time, run `Halcora.cmd` with
   `-BootDisk` in a PowerShell window to boot the installed system:

       powershell -ExecutionPolicy Bypass -File Halcora-VM.ps1 -BootDisk

## Speed

Turn on hardware acceleration for a usable speed. In an administrator
PowerShell:

    Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All

Then restart Windows. Virtualisation must also be enabled in the BIOS or UEFI,
usually as "Intel VT-x" or "SVM". Without it the virtual machine runs in
software and is very slow. The launcher prints this instruction when
acceleration is off.

Whether this works on Windows 11 Home has not been confirmed.

## Starting over

    powershell -ExecutionPolicy Bypass -File Halcora-VM.ps1 -Reset

This erases the virtual disk and starts the installer from nothing.

## Where things are

- `%LOCALAPPDATA%\Halcora\halcora-*.iso` — the downloaded ISO
- `%LOCALAPPDATA%\Halcora\halcora-disk.qcow2` — the installed system's disk
- Delete the whole `Halcora` folder to remove everything the launcher made.
