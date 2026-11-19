using System;
using System.Runtime.InteropServices;
using System.Threading;

namespace Halcora;

/// <summary>
/// How much of the machine Halcora takes.
///
/// The rule is the one the project owner asked for: use what is free, leave a
/// reserve, and never assume a fixed machine. On a 16 GB machine with 6 GB in
/// use there is 10 GB available, so the virtual machine gets 9 GB and the host
/// keeps 1 GB.
///
/// What this is not: live resizing. QEMU fixes guest RAM when the virtual
/// machine starts, and changing it afterwards needs a virtio-balloon device and
/// a cooperating guest. So the numbers are computed at launch, which is when
/// they can actually be honoured.
/// </summary>
internal sealed record ResourcePlan(
    long TotalRamMb,
    long UsedRamMb,
    long AvailableRamMb,
    long ReserveRamMb,
    long VmRamMb,
    int LogicalCpus,
    int CpuLoadPercent,
    int VmCpus,
    int VirtualDiskGb,
    bool Tight)
{
    private const long Mb = 1024L * 1024L;

    /// <summary>Floor for guest RAM. Plasma on 1 GB is not a desktop.</summary>
    private const long MinimumVmRamMb = 2048;

    /// <summary>
    /// The least we will ever hand the guest. Below this the desktop will not
    /// start, so it is a floor rather than a preference.
    /// </summary>
    private const long HardFloorMb = 512;

    /// <summary>
    /// Never hand the guest more than this share of physical RAM. Free memory
    /// can be high right after a reboot, and taking three quarters of it leaves
    /// the host unusable the moment a browser wakes up.
    /// </summary>
    private const double MaximumShareOfTotal = 0.75;

    /// <summary>
    /// The virtual disk is sparse: the file starts near zero bytes and grows with
    /// what the guest actually writes, so there is no meaningful minimum and no
    /// cost to a generous ceiling. 64 GB is the ceiling the installer will see.
    /// </summary>
    public const int DefaultVirtualDiskGb = 64;

    public static ResourcePlan Compute()
    {
        var memory = MemoryStatus.Query();
        long totalMb = (long)(memory.TotalPhys / Mb);
        long availableMb = (long)(memory.AvailablePhys / Mb);
        if (availableMb > totalMb)
        {
            availableMb = totalMb;
        }

        long usedMb = totalMb - availableMb;

        // A sixteenth of RAM, but never less than 1 GB: on 16 GB that is exactly
        // the 1 GB buffer in the rule above.
        long reserveMb = Math.Max(1024, totalMb / 16);

        long vmMb = availableMb - reserveMb;

        long ceilingMb = (long)(totalMb * MaximumShareOfTotal);
        if (vmMb > ceilingMb)
        {
            vmMb = ceilingMb;
        }

        // Tight means this machine cannot comfortably host a desktop. Say so,
        // then take what is actually free rather than a comfortable figure the
        // machine does not have: handing out 2 GB when only 1 GB is free means
        // the host swaps, which is slower than a smaller machine that fits.
        bool tight = vmMb < MinimumVmRamMb;
        if (tight)
        {
            vmMb = Math.Max(HardFloorMb, vmMb);
        }

        vmMb = vmMb / 256 * 256;
        if (vmMb < HardFloorMb)
        {
            vmMb = HardFloorMb;
        }

        int logical = Math.Max(1, Environment.ProcessorCount);
        int vmCpus = Math.Clamp(logical - 2, 1, 8);
        int loadPercent = (int)Math.Round(CpuLoad.Sample() * 100);
        if (loadPercent >= 50 && vmCpus > 1)
        {
            vmCpus -= 1;
        }

        return new ResourcePlan(
            TotalRamMb: totalMb,
            UsedRamMb: usedMb,
            AvailableRamMb: availableMb,
            ReserveRamMb: reserveMb,
            VmRamMb: vmMb,
            LogicalCpus: logical,
            CpuLoadPercent: loadPercent,
            VmCpus: vmCpus,
            VirtualDiskGb: DefaultVirtualDiskGb,
            Tight: tight);
    }

    /// <summary>A short line for the window, in the words a user would use.</summary>
    public string Describe()
    {
        return $"This PC has {TotalRamMb / 1024} GB ({UsedRamMb / 1024} GB in use). " +
               $"Halcora takes {VmRamMb / 1024} GB and {VmCpus} of {LogicalCpus} cores, " +
               $"leaving {ReserveRamMb / 1024} GB spare.";
    }
}

[StructLayout(LayoutKind.Sequential)]
internal struct MemoryStatusEx
{
    public uint Length;
    public uint MemoryLoad;
    public ulong TotalPhys;
    public ulong AvailablePhys;
    public ulong TotalPageFile;
    public ulong AvailablePageFile;
    public ulong TotalVirtual;
    public ulong AvailableVirtual;
    public ulong AvailableExtendedVirtual;
}

internal static class MemoryStatus
{
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GlobalMemoryStatusEx(ref MemoryStatusEx buffer);

    public static MemoryStatusEx Query()
    {
        var status = new MemoryStatusEx
        {
            Length = (uint)Marshal.SizeOf<MemoryStatusEx>(),
        };

        if (!GlobalMemoryStatusEx(ref status))
        {
            throw new InvalidOperationException("GlobalMemoryStatusEx failed.");
        }

        return status;
    }
}

/// <summary>
/// Current CPU busy fraction, sampled rather than instantaneous, because a
/// single reading of the counters is meaningless.
/// </summary>
internal static class CpuLoad
{
    [StructLayout(LayoutKind.Sequential)]
    private struct FileTime
    {
        public uint Low;
        public uint High;

        public ulong ToUInt64() => ((ulong)High << 32) | Low;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GetSystemTimes(out FileTime idle, out FileTime kernel, out FileTime user);

    public static double Sample(int milliseconds = 200)
    {
        if (!GetSystemTimes(out var idle0, out var kernel0, out var user0))
        {
            return 0;
        }

        Thread.Sleep(milliseconds);

        if (!GetSystemTimes(out var idle1, out var kernel1, out var user1))
        {
            return 0;
        }

        ulong idle = idle1.ToUInt64() - idle0.ToUInt64();
        ulong total = (kernel1.ToUInt64() - kernel0.ToUInt64()) + (user1.ToUInt64() - user0.ToUInt64());

        if (total == 0)
        {
            return 0;
        }

        // Kernel time includes idle time, so busy is total minus idle.
        double busy = (double)(total - idle) / total;
        return Math.Clamp(busy, 0d, 1d);
    }
}
