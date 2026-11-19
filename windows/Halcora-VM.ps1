#requires -Version 5.1
<#
.SYNOPSIS
  Runs the Halcora live ISO in a QEMU window on Windows.

.DESCRIPTION
  Downloads the latest prealpha ISO from GitHub and checks it against the
  release's SHA256SUMS. Creates a virtual disk for the installer to erase, and
  starts QEMU. Everything lives in %LOCALAPPDATA%\Halcora. The Windows disk is
  never touched.

  Written against QEMU's documented options. It has not been run on Windows
  yet, so each step reports what it was doing when it fails.

.PARAMETER BootDisk
  Boot the virtual disk the installer wrote to, instead of the ISO.

.PARAMETER Reset
  Erase the virtual disk and start the installer from nothing.

.PARAMETER ShowCommand
  Print the QEMU command line that would run, then exit. Starts nothing and
  downloads nothing. Used by CI.
#>
[CmdletBinding()]
param(
    [switch]$BootDisk,
    [switch]$Reset,
    [switch]$ShowCommand,
    [int]$MemoryMB = 4096,
    [int]$Cpus = 4,
    [int]$DiskGB = 20
)

# Windows PowerShell 5.1 defaults to TLS 1.0/1.1, which GitHub refuses.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# curl and QEMU write progress to stderr. Under 'Stop', Windows PowerShell turns
# that into a terminating error, so failures are checked through $LASTEXITCODE.
$ErrorActionPreference = 'Continue'

$Repo     = 'Ron-warrior/halcora'
$Tag      = 'prealpha'
$StateDir = Join-Path $env:LOCALAPPDATA 'Halcora'
$DiskPath = Join-Path $StateDir 'halcora-disk.qcow2'
$WingetId = 'SoftwareFreedomConservancy.QEMU'

function Say([string]$Message) {
    Write-Host "[halcora] $Message"
}

function Fail([string]$Message) {
    Write-Host "[halcora] ERROR: $Message" -ForegroundColor Red
    exit 1
}

function Find-Qemu {
    $paths = @(Join-Path $env:ProgramFiles 'qemu\qemu-system-x86_64w.exe')
    $programFilesX86 = ${env:ProgramFiles(x86)}
    if ($programFilesX86) {
        $paths += Join-Path $programFilesX86 'qemu\qemu-system-x86_64w.exe'
    }
    foreach ($path in $paths) {
        if (Test-Path -LiteralPath $path) { return $path }
    }
    $onPath = Get-Command 'qemu-system-x86_64w.exe' -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }
    return $null
}

function Install-Qemu {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Fail 'QEMU is not installed, and winget is not available to install it. Install QEMU from https://qemu.weilnetz.de/w64/ and run this again.'
    }
    Say 'installing QEMU with winget. Windows may ask for permission.'
    & winget install -e --id $WingetId --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Fail "winget could not install QEMU (exit code $LASTEXITCODE)."
    }
}

function Get-Accelerator {
    # HypervisorPresent is true when any hypervisor is running, including the
    # one WHPX needs. It does not prove the HypervisorPlatform feature is on,
    # so QEMU is given TCG as a fallback in the same command.
    $hypervisor = $false
    try {
        $hypervisor = [bool](Get-CimInstance -ClassName Win32_ComputerSystem).HypervisorPresent
    } catch {
        $hypervisor = $false
    }
    if ($hypervisor) {
        return [pscustomobject]@{
            Name  = 'whpx'
            Accel = @('-accel', 'whpx', '-accel', 'tcg')
            Cpu   = 'Haswell'
        }
    }
    return [pscustomobject]@{
        Name  = 'tcg'
        Accel = @('-accel', 'tcg')
        Cpu   = 'max'
    }
}

function Get-LatestRelease {
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/tags/$Tag" -Headers @{ 'User-Agent' = 'halcora-windows-launcher' }
    } catch {
        Fail "could not read the $Tag release from GitHub: $($_.Exception.Message)"
    }
    $iso  = $release.assets | Where-Object { $_.name -like 'halcora-*.iso' } | Select-Object -First 1
    $sums = $release.assets | Where-Object { $_.name -eq 'SHA256SUMS' } | Select-Object -First 1
    if (-not $iso -or -not $sums) {
        Fail "the $Tag release has no ISO and SHA256SUMS yet."
    }
    return [pscustomobject]@{
        Name    = $iso.name
        Url     = $iso.browser_download_url
        SumsUrl = $sums.browser_download_url
    }
}

function Save-Download([string]$Url, [string]$Destination) {
    if (-not (Get-Command curl.exe -ErrorAction SilentlyContinue)) {
        Fail 'curl.exe is missing. It ships with Windows 10 version 1803 and later.'
    }
    & curl.exe --location --fail --retry 3 --output $Destination $Url
    if ($LASTEXITCODE -ne 0) {
        Fail "download failed: $Url"
    }
}

function Test-IsoAgainstSums([string]$IsoPath, [string]$SumsPath, [string]$IsoName) {
    # SHA256SUMS lines look like "<hash>  ./<name>", so match on the name's end.
    $line = Get-Content -LiteralPath $SumsPath | Where-Object { $_ -like "*$IsoName" } | Select-Object -First 1
    if (-not $line) { return $false }
    $expected = ($line.Trim() -split '\s+')[0].ToLower()
    $actual   = (Get-FileHash -Algorithm SHA256 -LiteralPath $IsoPath).Hash.ToLower()
    return ($expected -eq $actual)
}

function Ensure-Iso {
    New-Item -ItemType Directory -Force -Path $StateDir | Out-Null
    $release  = Get-LatestRelease
    $isoPath  = Join-Path $StateDir $release.Name
    $sumsPath = Join-Path $StateDir 'SHA256SUMS'

    Save-Download $release.SumsUrl $sumsPath
    if ((Test-Path -LiteralPath $isoPath) -and (Test-IsoAgainstSums $isoPath $sumsPath $release.Name)) {
        Say "ISO already downloaded and verified: $($release.Name)"
        return $isoPath
    }

    # Older prealpha builds are replaced rather than kept, so the folder does not fill up.
    Get-ChildItem -Path $StateDir -Filter 'halcora-*.iso' | Remove-Item -Force
    Say "downloading $($release.Name). It is about 1.9 GB and can take a while."
    Save-Download $release.Url $isoPath

    if (-not (Test-IsoAgainstSums $isoPath $sumsPath $release.Name)) {
        Remove-Item -LiteralPath $isoPath -Force
        Fail 'the download does not match SHA256SUMS. It has been deleted. Run the launcher again.'
    }
    Say 'ISO verified against SHA256SUMS.'
    return $isoPath
}

function Ensure-Disk([string]$QemuImg) {
    if ($Reset -and (Test-Path -LiteralPath $DiskPath)) {
        Remove-Item -LiteralPath $DiskPath -Force
    }
    if (Test-Path -LiteralPath $DiskPath) { return }
    if (-not (Test-Path -LiteralPath $QemuImg)) {
        Fail "qemu-img.exe was not found next to QEMU ($QemuImg)."
    }
    Say "creating a $DiskGB GB virtual disk. The installer erases this file, never your Windows disk."
    & $QemuImg create -f qcow2 $DiskPath "${DiskGB}G" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Fail 'qemu-img could not create the virtual disk.'
    }
}

function Get-QemuArguments($Accel, [string]$IsoPath) {
    $qemuArgs = @('-name', 'Halcora', '-M', 'q35') + $Accel.Accel + @(
        '-cpu', $Accel.Cpu,
        '-smp', "$Cpus",
        '-m', "$MemoryMB",
        '-drive', "file=$DiskPath,format=qcow2,if=virtio",
        '-vga', 'std',
        '-display', 'gtk',
        '-device', 'qemu-xhci',
        '-device', 'usb-tablet',
        '-netdev', 'user,id=net0',
        '-device', 'virtio-net-pci,netdev=net0'
    )
    if ($IsoPath) {
        $qemuArgs += @('-cdrom', $IsoPath, '-boot', 'order=dc')
    } else {
        $qemuArgs += @('-boot', 'order=c')
    }
    return $qemuArgs
}

# ---- main ----

Say 'Halcora Windows launcher'

$accel = Get-Accelerator
if ($accel.Name -eq 'whpx') {
    Say 'hardware acceleration (WHPX) looks available. QEMU falls back to software if it fails.'
} else {
    Say 'hardware acceleration is OFF, so the virtual machine will be very slow.'
    Say 'to turn it on, in an administrator PowerShell run:'
    Say '  Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All'
    Say 'then restart Windows. Virtualisation must also be enabled in the BIOS/UEFI.'
}

if ($ShowCommand) {
    $qemu    = '<qemu-system-x86_64w.exe>'
    $isoPath = if ($BootDisk) { $null } else { '<halcora-iso>' }
} else {
    $qemu = Find-Qemu
    if (-not $qemu) {
        Install-Qemu
        $qemu = Find-Qemu
        if (-not $qemu) {
            Fail 'QEMU was installed but cannot be found. Close this window and run the launcher again.'
        }
    }
    if ($BootDisk) {
        $isoPath = $null
        if (-not (Test-Path -LiteralPath $DiskPath)) {
            Fail 'there is no installed disk yet. Run the launcher without -BootDisk first.'
        }
    } else {
        $isoPath = Ensure-Iso
    }
    Ensure-Disk (Join-Path (Split-Path -Parent $qemu) 'qemu-img.exe')
}

$qemuArgs = Get-QemuArguments $accel $isoPath

if ($ShowCommand) {
    Say 'the command that would run (nothing was started):'
    Write-Host ("$qemu " + ($qemuArgs -join ' '))
    exit 0
}

Say 'starting Halcora. Close its window to stop the virtual machine.'
& $qemu @qemuArgs
Say "the virtual machine has stopped (exit code $LASTEXITCODE)."
