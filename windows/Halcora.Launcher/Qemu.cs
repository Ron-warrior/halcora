using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;

namespace Halcora;

/// <summary>
/// Finding QEMU, sizing the disk, and building the command line.
///
/// QEMU is the engine. It is installed separately rather than bundled, because
/// shipping a 200 MB virtualiser inside a launcher would make the download
/// enormous and drag its licence into ours.
/// </summary>
internal sealed class Qemu
{
    public const string WingetId = "SoftwareFreedomConservancy.QEMU";

    public required string Executable { get; init; }

    public static string? Find()
    {
        var candidates = new List<string>();

        if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("ProgramFiles")))
        {
            candidates.Add(Path.Combine(Environment.GetEnvironmentVariable("ProgramFiles")!, "qemu", "qemu-system-x86_64w.exe"));
        }

        var programFilesX86 = Environment.GetEnvironmentVariable("ProgramFiles(x86)");
        if (!string.IsNullOrEmpty(programFilesX86))
        {
            candidates.Add(Path.Combine(programFilesX86!, "qemu", "qemu-system-x86_64w.exe"));
        }

        foreach (var candidate in candidates)
        {
            if (File.Exists(candidate))
            {
                return candidate;
            }
        }

        // Fall back to PATH, in case someone installed it themselves.
        var path = Environment.GetEnvironmentVariable("PATH") ?? string.Empty;
        foreach (var directory in path.Split(Path.PathSeparator))
        {
            if (string.IsNullOrWhiteSpace(directory))
            {
                continue;
            }

            var candidate = Path.Combine(directory, "qemu-system-x86_64w.exe");
            if (File.Exists(candidate))
            {
                return candidate;
            }
        }

        return null;
    }

    public static string ImageToolBeside(string qemuExecutable)
    {
        var directory = Path.GetDirectoryName(qemuExecutable) ?? ".";
        return Path.Combine(directory, "qemu-img.exe");
    }

    /// <summary>
    /// Creates the disk if it is missing. qcow2 is sparse and copy-on-write: the
    /// file starts at a few hundred kilobytes and grows with what the guest
    /// writes, so VirtualDiskGb is a ceiling the installer sees, not an
    /// allocation and not a minimum.
    /// </summary>
    public static void EnsureDisk(string imageTool, string diskPath, int virtualGb, Action<string> log)
    {
        if (File.Exists(diskPath))
        {
            return;
        }

        if (!File.Exists(imageTool))
        {
            throw new FileNotFoundException("qemu-img.exe was not found next to QEMU.", imageTool);
        }

        log($"Creating a {virtualGb} GB virtual disk. It starts near empty and grows only as Halcora uses it.");

        var startInfo = new ProcessStartInfo(imageTool)
        {
            UseShellExecute = false,
            RedirectStandardError = true,
            CreateNoWindow = true,
        };
        startInfo.ArgumentList.Add("create");
        startInfo.ArgumentList.Add("-f");
        startInfo.ArgumentList.Add("qcow2");
        // preallocation=off keeps the file sparse; metadata costs a little more
        // but the file stays tiny until the guest writes to it.
        startInfo.ArgumentList.Add("-o");
        startInfo.ArgumentList.Add("preallocation=off");
        startInfo.ArgumentList.Add(diskPath);
        startInfo.ArgumentList.Add($"{virtualGb}G");

        using var process = Process.Start(startInfo)
            ?? throw new InvalidOperationException("Could not start qemu-img.");

        var errors = process.StandardError.ReadToEnd();
        process.WaitForExit();

        if (process.ExitCode != 0)
        {
            throw new InvalidOperationException($"qemu-img failed: {errors.Trim()}");
        }
    }

    public static long DiskBytesInUse(string diskPath)
    {
        var info = new FileInfo(diskPath);
        return info.Exists ? info.Length : 0L;
    }

    /// <summary>
    /// Builds the argument list. Kept separate from starting the process so the
    /// self-test and CI can inspect it without booting anything.
    /// </summary>
    public static List<string> BuildArguments(
        ResourcePlan plan,
        string diskPath,
        string? isoPath)
    {
        var arguments = new List<string>
        {
            "-name", "Halcora",
            "-title", "Halcora",
            "-M", "q35",

            // An accelerator list is tried in order: WHPX if the Windows
            // Hypervisor Platform feature is installed, otherwise software.
            // Asking QEMU is more reliable than interrogating Windows for it,
            // and it avoids a dependency on System.Management just to read one
            // boolean.
            "-accel", "whpx", "-accel", "tcg",
            "-smp", plan.VmCpus.ToString(),
            "-m", plan.VmRamMb.ToString(),
        };

        // discard=unmap lets the guest's TRIM release blocks back to the host, so
        // the disk shrinks again as well as grows.
        arguments.AddRange(new[]
        {
            "-drive", $"file={diskPath},format=qcow2,if=virtio,discard=unmap,detect-zeroes=unmap",
        });

        if (isoPath is not null)
        {
            arguments.AddRange(new[] { "-cdrom", isoPath, "-boot", "order=dc" });
        }
        else
        {
            arguments.AddRange(new[] { "-boot", "order=c" });
        }

        arguments.AddRange(new[]
        {
            "-vga", "std",
            "-display", "gtk",
            "-device", "qemu-xhci",
            "-device", "usb-tablet",
            "-netdev", "user,id=net0",
            "-device", "virtio-net-pci,netdev=net0",
        });

        return arguments;
    }

    public static Process Start(string executable, IEnumerable<string> arguments)
    {
        var startInfo = new ProcessStartInfo(executable)
        {
            UseShellExecute = false,
            RedirectStandardError = true,
            RedirectStandardOutput = true,
        };

        foreach (var argument in arguments)
        {
            startInfo.ArgumentList.Add(argument);
        }

        return Process.Start(startInfo) ?? throw new InvalidOperationException("Could not start QEMU.");
    }
}
