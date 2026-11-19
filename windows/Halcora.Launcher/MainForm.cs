using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Halcora;

/// <summary>
/// The window a user sees when they double-click Halcora.
///
/// It explains what it is about to take from the machine, downloads and verifies
/// the ISO on first run, then hands the display to QEMU. It stays open while the
/// virtual machine runs, so closing it deliberately is the way to stop Halcora.
/// </summary>
internal sealed class MainForm : Form
{
    private static readonly Color Background = Color.FromArgb(27, 27, 31);
    private static readonly Color Surface = Color.FromArgb(38, 38, 44);
    private static readonly Color Accent = Color.FromArgb(52, 130, 255);
    private static readonly Color Foreground = Color.FromArgb(240, 240, 245);
    private static readonly Color Muted = Color.FromArgb(160, 160, 172);

    private readonly string _stateDirectory;
    private readonly string _diskPath;

    private readonly Label _headline;
    private readonly Label _detail;
    private readonly ProgressBar _progress;
    private readonly TextBox _log;
    private readonly Button _start;
    private readonly Button _bootInstalled;
    private readonly Button _reset;
    private readonly Button _quit;

    private CancellationTokenSource? _cancellation;
    private Process? _qemu;
    private ResourcePlan _plan;

    public MainForm()
    {
        _stateDirectory = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "Halcora");
        _diskPath = Path.Combine(_stateDirectory, "halcora-disk.qcow2");
        _plan = ResourcePlan.Compute();

        Text = "Halcora";
        StartPosition = FormStartPosition.CenterScreen;
        MinimumSize = new Size(640, 520);
        Size = new Size(760, 580);
        BackColor = Background;
        ForeColor = Foreground;
        Font = new Font("Segoe UI", 9.75f);
        Icon = SystemIcons.Application;

        _headline = new Label
        {
            Text = "Halcora",
            Font = new Font("Segoe UI Semibold", 22f),
            ForeColor = Foreground,
            AutoSize = true,
            Location = new Point(28, 22),
        };

        var tagline = new Label
        {
            Text = "A desktop that stays out of your way. Running inside a window.",
            Font = new Font("Segoe UI", 10f),
            ForeColor = Muted,
            AutoSize = true,
            Location = new Point(31, 68),
        };

        _detail = new Label
        {
            Text = _plan.Describe(),
            ForeColor = Foreground,
            AutoSize = false,
            Size = new Size(700, 44),
            Location = new Point(31, 100),
        };

        _progress = new ProgressBar
        {
            Location = new Point(31, 152),
            Size = new Size(700, 6),
            Style = ProgressBarStyle.Continuous,
            Visible = false,
        };

        _log = new TextBox
        {
            Multiline = true,
            ReadOnly = true,
            ScrollBars = ScrollBars.Vertical,
            BackColor = Surface,
            ForeColor = Muted,
            BorderStyle = BorderStyle.None,
            Font = new Font("Consolas", 9f),
            Location = new Point(31, 172),
            Size = new Size(700, 268),
            Anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right | AnchorStyles.Bottom,
        };

        _start = MakeButton("Start Halcora", primary: true, new Point(31, 456));
        _start.Click += async (_, _) => await StartAsync(bootInstalled: false);

        _bootInstalled = MakeButton("Start installed system", primary: false, new Point(171, 456));
        _bootInstalled.Click += async (_, _) => await StartAsync(bootInstalled: true);

        _reset = MakeButton("Erase and start over", primary: false, new Point(346, 456));
        _reset.Click += (_, _) => ResetDisk();

        _quit = MakeButton("Quit", primary: false, new Point(521, 456));
        _quit.Click += (_, _) => Close();

        Controls.AddRange(new Control[] { _headline, tagline, _detail, _progress, _log, _start, _bootInstalled, _reset, _quit });

        _bootInstalled.Enabled = File.Exists(_diskPath);

        Log($"This PC has {_plan.TotalRamMb / 1024} GB of memory, {_plan.UsedRamMb / 1024} GB of it in use.");
        Log($"Halcora will take {_plan.VmRamMb / 1024} GB and {_plan.VmCpus} cores, keeping {_plan.ReserveRamMb / 1024} GB spare.");
        if (_plan.Tight)
        {
            Log("Warning: this PC does not have much free memory, so Halcora will run slowly.");
            Log("Closing some applications before starting will give it more to work with.");
        }
        Log("The virtual disk starts near empty and grows only as Halcora uses it.");
        Log(string.Empty);
        Log("Press Start Halcora. The first run downloads about 1.9 GB.");

        FormClosing += OnFormClosing;
    }

    private Button MakeButton(string text, bool primary, Point location)
    {
        var button = new Button
        {
            Text = text,
            Location = location,
            Size = new Size(135, 34),
            FlatStyle = FlatStyle.Flat,
            BackColor = primary ? Accent : Surface,
            ForeColor = primary ? Color.White : Foreground,
            Font = new Font("Segoe UI Semibold", 9.5f),
            Anchor = AnchorStyles.Bottom | AnchorStyles.Left,
        };
        button.FlatAppearance.BorderSize = primary ? 0 : 1;
        button.FlatAppearance.BorderColor = Color.FromArgb(60, 60, 70);
        return button;
    }

    private void Log(string message)
    {
        if (InvokeRequired)
        {
            BeginInvoke(new Action(() => Log(message)));
            return;
        }

        _log.AppendText(message + Environment.NewLine);
    }

    private void SetBusy(bool busy, string headline)
    {
        _start.Enabled = !busy;
        _bootInstalled.Enabled = !busy && File.Exists(_diskPath);
        _reset.Enabled = !busy;
        _progress.Visible = busy;
        if (headline.Length > 0)
        {
            _detail.Text = headline;
        }
    }

    private void ResetDisk()
    {
        if (!File.Exists(_diskPath))
        {
            return;
        }

        var answer = MessageBox.Show(
            "This erases the installed Halcora system. Your Windows install is not touched.\r\n\r\nContinue?",
            "Erase and start over",
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Warning,
            MessageBoxDefaultButton.Button2);

        if (answer != DialogResult.Yes)
        {
            return;
        }

        try
        {
            File.Delete(_diskPath);
            Log("Virtual disk erased.");
            _bootInstalled.Enabled = false;
        }
        catch (IOException exception)
        {
            Log($"Could not erase the disk: {exception.Message}");
        }
    }

    private async Task StartAsync(bool bootInstalled)
    {
        if (_qemu is { HasExited: false })
        {
            return;
        }

        _cancellation = new CancellationTokenSource();
        var token = _cancellation.Token;
        SetBusy(true, "Getting ready.");

        try
        {
            var qemuPath = Qemu.Find();
            if (qemuPath is null)
            {
                SetBusy(true, "Installing QEMU, the virtual machine engine.");
                Log("QEMU is not installed. Asking Windows to install it; this may ask for permission.");
                await InstallQemuAsync(token).ConfigureAwait(true);

                qemuPath = Qemu.Find();
                if (qemuPath is null)
                {
                    throw new InvalidOperationException(
                        "QEMU was installed but cannot be found. Close Halcora and open it again.");
                }
            }

            Directory.CreateDirectory(_stateDirectory);

            string? isoPath = null;
            if (!bootInstalled)
            {
                isoPath = await EnsureIsoAsync(token).ConfigureAwait(true);
            }
            else if (!File.Exists(_diskPath))
            {
                throw new InvalidOperationException("There is no installed system yet. Press Start Halcora first.");
            }

            Qemu.EnsureDisk(Qemu.ImageToolBeside(qemuPath), _diskPath, _plan.VirtualDiskGb, Log);
            RefreshDiskUsage();

            var arguments = Qemu.BuildArguments(_plan, _diskPath, isoPath);
            Log($"Starting the virtual machine with {_plan.VmRamMb / 1024} GB and {_plan.VmCpus} cores.");
            SetBusy(true, "Halcora is running in the window that just opened.");

            _qemu = Qemu.Start(qemuPath, arguments);
            _qemu.EnableRaisingEvents = true;
            _qemu.Exited += (_, _) => BeginInvoke(new Action(OnQemuExited));

            // The console window stays open behind the guest; that is QEMU's, not
            // ours, and closing it would kill the machine.
            Log("Close the Halcora window to shut the machine down. This window stays open so it can start again.");
        }
        catch (OperationCanceledException)
        {
            Log("Cancelled.");
            SetBusy(false, _plan.Describe());
        }
        catch (Exception exception)
        {
            Log($"ERROR: {exception.Message}");
            SetBusy(false, _plan.Describe());
            MessageBox.Show(exception.Message, "Halcora could not start", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    private void OnQemuExited()
    {
        var code = _qemu?.ExitCode ?? 0;
        _qemu?.Dispose();
        _qemu = null;

        if (code != 0)
        {
            Log($"The virtual machine stopped with exit code {code}.");
        }
        else
        {
            Log("The virtual machine stopped.");
        }

        RefreshDiskUsage();
        SetBusy(false, _plan.Describe());
    }

    private void RefreshDiskUsage()
    {
        if (!File.Exists(_diskPath))
        {
            return;
        }

        var megabytes = Qemu.DiskBytesInUse(_diskPath) / (1024 * 1024);
        Log($"The virtual disk is using {megabytes} MB of its {_plan.VirtualDiskGb} GB ceiling.");
        _bootInstalled.Enabled = _qemu is null;
    }

    private async Task InstallQemuAsync(CancellationToken token)
    {
        var startInfo = new ProcessStartInfo("winget")
        {
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true,
        };
        startInfo.ArgumentList.Add("install");
        startInfo.ArgumentList.Add("-e");
        startInfo.ArgumentList.Add("--id");
        startInfo.ArgumentList.Add(Qemu.WingetId);
        startInfo.ArgumentList.Add("--accept-package-agreements");
        startInfo.ArgumentList.Add("--accept-source-agreements");

        using var process = Process.Start(startInfo)
            ?? throw new InvalidOperationException("winget is not available. Install QEMU from https://qemu.weilnetz.de/w64/ and try again.");

        var output = await process.StandardOutput.ReadToEndAsync().ConfigureAwait(true);
        await process.WaitForExitAsync(token).ConfigureAwait(true);

        if (process.ExitCode != 0)
        {
            throw new InvalidOperationException(
                "winget could not install QEMU. Install it from https://qemu.weilnetz.de/w64/ and try again.\r\n\r\n" +
                output.Trim());
        }
    }

    private async Task<string> EnsureIsoAsync(CancellationToken token)
    {
        SetBusy(true, "Finding the latest Halcora image.");
        var source = await IsoSource.ResolveAsync(token).ConfigureAwait(true);
        var isoPath = Path.Combine(_stateDirectory, source.FileName);
        var sumsPath = Path.Combine(_stateDirectory, "SHA256SUMS.tmp");

        if (File.Exists(isoPath))
        {
            SetBusy(true, "Checking the image already on this PC.");
            if (await source.VerifyAsync(isoPath, token).ConfigureAwait(true))
            {
                Log("The existing image is intact.");
                return isoPath;
            }

            Log("The existing image is damaged or out of date. Downloading it again.");
            File.Delete(isoPath);
        }

        // Old prealpha builds are replaced rather than accumulated.
        foreach (var stale in Directory.GetFiles(_stateDirectory, "halcora-*.iso"))
        {
            File.Delete(stale);
        }

        SetBusy(true, $"Downloading {source.FileName}. This happens once.");
        Log($"Downloading {source.FileName}, about 1.9 GB.");

        var progress = new Progress<double>(fraction =>
        {
            if (fraction < 0)
            {
                _progress.Style = ProgressBarStyle.Marquee;
                return;
            }

            _progress.Style = ProgressBarStyle.Continuous;
            _progress.Value = Math.Clamp((int)(fraction * 100), 0, 100);
        });

        await source.DownloadAsync(isoPath, progress, Log, token).ConfigureAwait(true);

        SetBusy(true, "Checking the download.");
        if (!await source.VerifyAsync(isoPath, token).ConfigureAwait(true))
        {
            File.Delete(isoPath);
            throw new InvalidOperationException(
                "The download does not match the release checksum and has been deleted. Try again.");
        }

        if (File.Exists(sumsPath))
        {
            File.Delete(sumsPath);
        }

        Log("The image matches the release checksum.");
        _progress.Value = 0;
        return isoPath;
    }

    private void OnFormClosing(object? sender, FormClosingEventArgs e)
    {
        if (_qemu is { HasExited: false })
        {
            var answer = MessageBox.Show(
                "Halcora is still running. Closing this window shuts it down.\r\n\r\nClose it?",
                "Halcora",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question,
                MessageBoxDefaultButton.Button2);

            if (answer != DialogResult.Yes)
            {
                e.Cancel = true;
                return;
            }

            try
            {
                _qemu.Kill(entireProcessTree: true);
            }
            catch (InvalidOperationException)
            {
                // It exited between the check and the kill.
            }
        }

        _cancellation?.Cancel();
        _cancellation?.Dispose();
    }
}
