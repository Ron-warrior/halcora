using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text.Json.Serialization;
using System.Threading;
using System.Threading.Tasks;

namespace Halcora;

/// <summary>
/// Where the ISO comes from, and the check that it arrived intact.
///
/// A download that is silently corrupt produces a virtual machine that fails in
/// ways that look like Halcora's fault, so the SHA-256 in the release's
/// SHA256SUMS is verified before anything runs.
/// </summary>
internal sealed class IsoSource
{
    private const string Repository = "Ron-warrior/halcora";
    private const string Tag = "prealpha";

    private static readonly HttpClient Http = CreateClient();

    private static HttpClient CreateClient()
    {
        var client = new HttpClient { Timeout = TimeSpan.FromMinutes(30) };
        client.DefaultRequestHeaders.UserAgent.ParseAdd("halcora-launcher");
        return client;
    }

    public required string FileName { get; init; }
    public required string DownloadUrl { get; init; }
    public required string SumsUrl { get; init; }

    private static async Task<ReleaseResponse> GetReleaseAsync(CancellationToken cancellation)
    {
        var url = $"https://api.github.com/repos/{Repository}/releases/tags/{Tag}";
        var release = await Http.GetFromJsonAsync<ReleaseResponse>(url, cancellation).ConfigureAwait(false);
        return release ?? throw new InvalidOperationException($"GitHub returned nothing for {Tag}.");
    }

    public static async Task<IsoSource> ResolveAsync(CancellationToken cancellation, string tier)
    {
        var release = await GetReleaseAsync(cancellation).ConfigureAwait(false);

        // Two images ship under the same tag, named "halcora-full-…" and
        // "halcora-lite-…". Pick the one this machine asked for; if the release
        // only has one, take it rather than failing, because a half-published
        // release should still be runnable.
        Asset? preferred = null;
        Asset? anyIso = null;
        Asset? sums = null;

        foreach (var asset in release.Assets ?? new List<Asset>())
        {
            if (asset.Name.EndsWith(".iso", StringComparison.OrdinalIgnoreCase))
            {
                anyIso ??= asset;
                if (asset.Name.Contains($"-{tier}-", StringComparison.OrdinalIgnoreCase))
                {
                    preferred = asset;
                }
            }
            else if (string.Equals(asset.Name, "SHA256SUMS", StringComparison.OrdinalIgnoreCase))
            {
                sums = asset;
            }
        }

        var iso = preferred ?? anyIso;

        if (iso is null || sums is null)
        {
            throw new InvalidOperationException(
                $"The {Tag} release has no ISO and SHA256SUMS yet. Nothing to download.");
        }

        return new IsoSource
        {
            FileName = iso.Name,
            DownloadUrl = iso.BrowserDownloadUrl,
            SumsUrl = sums.BrowserDownloadUrl,
        };
    }

    /// <summary>
    /// Downloads to <paramref name="destination"/>, reporting 0..1 or -1 when the
    /// server sends no content length.
    /// </summary>
    public async Task DownloadAsync(
        string destination,
        IProgress<double> progress,
        Action<string> log,
        CancellationToken cancellation)
    {
        var partial = destination + ".part";

        using (var response = await Http
            .GetAsync(DownloadUrl, HttpCompletionOption.ResponseHeadersRead, cancellation)
            .ConfigureAwait(false))
        {
            response.EnsureSuccessStatusCode();

            long total = response.Content.Headers.ContentLength ?? -1L;
            long written = 0;

            await using (var source = await response.Content.ReadAsStreamAsync(cancellation).ConfigureAwait(false))
            await using (var target = new FileStream(partial, FileMode.Create, FileAccess.Write, FileShare.None, 1 << 20, useAsync: true))
            {
                var buffer = new byte[1 << 20];
                int read;
                while ((read = await source.ReadAsync(buffer, cancellation).ConfigureAwait(false)) > 0)
                {
                    await target.WriteAsync(buffer.AsMemory(0, read), cancellation).ConfigureAwait(false);
                    written += read;

                    if (total > 0)
                    {
                        progress.Report((double)written / total);
                    }
                    else
                    {
                        progress.Report(-1);
                    }
                }
            }
        }

        // The partial file only becomes the real one after a clean finish, so a
        // cancelled download never looks like a usable ISO.
        if (File.Exists(destination))
        {
            File.Delete(destination);
        }

        File.Move(partial, destination);
        log($"Downloaded {Path.GetFileName(destination)}.");
    }

    public async Task<bool> VerifyAsync(string isoPath, CancellationToken cancellation)
    {
        string sumsText;
        using (var response = await Http.GetAsync(SumsUrl, cancellation).ConfigureAwait(false))
        {
            response.EnsureSuccessStatusCode();
            sumsText = await response.Content.ReadAsStringAsync(cancellation).ConfigureAwait(false);
        }

        string expected = string.Empty;
        var name = Path.GetFileName(isoPath);

        foreach (var line in sumsText.Split('\n'))
        {
            var trimmed = line.Trim();
            if (trimmed.Length == 0)
            {
                continue;
            }

            // "<hash>  ./<name>": matching on the tail avoids caring about the prefix.
            if (trimmed.EndsWith(name, StringComparison.Ordinal))
            {
                var parts = trimmed.Split(new[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length > 0)
                {
                    expected = parts[0];
                    break;
                }
            }
        }

        if (expected.Length == 0)
        {
            return false;
        }

        using var stream = File.OpenRead(isoPath);
        var actual = await SHA256.HashDataAsync(stream, cancellation).ConfigureAwait(false);
        var actualHex = Convert.ToHexString(actual);

        return string.Equals(expected, actualHex, StringComparison.OrdinalIgnoreCase);
    }

    internal sealed class ReleaseResponse
    {
        [JsonPropertyName("assets")]
        public List<Asset>? Assets { get; set; }
    }

    internal sealed class Asset
    {
        [JsonPropertyName("name")]
        public string Name { get; set; } = string.Empty;

        [JsonPropertyName("browser_download_url")]
        public string BrowserDownloadUrl { get; set; } = string.Empty;
    }
}
