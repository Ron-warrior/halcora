using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Windows.Forms;

namespace Halcora;

internal static class Program
{
    /// <summary>
    /// Named mutex so a second double-click raises the existing window instead of
    /// starting a second virtual machine against the same disk image. Two QEMUs
    /// on one qcow2 will corrupt it.
    /// </summary>
    private const string MutexName = @"Global\Halcora.Launcher.SingleInstance";

    [STAThread]
    private static int Main(string[] args)
    {
        if (Array.Exists(args, a => string.Equals(a, "--self-test", StringComparison.OrdinalIgnoreCase)))
        {
            return SelfTest.Run();
        }

        using var mutex = new Mutex(initiallyOwned: true, MutexName, out var isFirstInstance);
        if (!isFirstInstance)
        {
            MessageBox.Show(
                "Halcora is already running.",
                "Halcora",
                MessageBoxButtons.OK,
                MessageBoxIcon.Information);
            return 1;
        }

        Application.SetHighDpiMode(HighDpiMode.PerMonitorV2);
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new MainForm());
        return 0;
    }
}

/// <summary>
/// Prints the machine's capacity and what Halcora would take from it.
///
/// This exists so CI can exercise the sizing logic on a real Windows machine
/// without opening a window or starting a virtual machine. It writes to stdout
/// when there is a console to attach to, and always to a file, because a WinExe
/// launched from a GUI has no stdout.
/// </summary>
internal static class SelfTest
{
    private const int AttachParentProcess = -1;

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool AttachConsole(int dwProcessId);

    public static int Run()
    {
        AttachConsole(AttachParentProcess);

        var plan = ResourcePlan.Compute();
        var text = new StringBuilder()
            .AppendLine("halcora-self-test")
            .AppendLine($"total-ram-mb      {plan.TotalRamMb}")
            .AppendLine($"used-ram-mb       {plan.UsedRamMb}")
            .AppendLine($"available-ram-mb  {plan.AvailableRamMb}")
            .AppendLine($"reserve-ram-mb    {plan.ReserveRamMb}")
            .AppendLine($"vm-ram-mb         {plan.VmRamMb}")
            .AppendLine($"logical-cpus      {plan.LogicalCpus}")
            .AppendLine($"cpu-load-percent  {plan.CpuLoadPercent}")
            .AppendLine($"vm-cpus           {plan.VmCpus}")
            .AppendLine($"disk-virtual-gb   {plan.VirtualDiskGb}")
            .ToString();

        try
        {
            Console.Out.Write(text);
            Console.Out.Flush();
        }
        catch (Exception)
        {
            // No console attached; the file below is the answer. Catching
            // broadly because a WinExe's stdout is a null stream and different
            // runtimes complain differently.
        }

        try
        {
            File.WriteAllText(Path.Combine(Path.GetTempPath(), "halcora-self-test.txt"), text);
        }
        catch (IOException)
        {
            return 2;
        }

        return 0;
    }
}
