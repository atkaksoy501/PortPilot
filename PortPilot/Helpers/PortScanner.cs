using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net;
using System.Net.NetworkInformation;

namespace PortPilot.Helpers;

public record PortInfo(int Port, int ProcessId, string ProcessName, string Protocol);

public static class PortScanner
{
    private const int MinPort = 3000;
    private const int MaxPort = 10000;

    public static List<PortInfo> GetListeningPorts()
    {
        var results = new List<PortInfo>();
        var properties = IPGlobalProperties.GetIPGlobalProperties();

        // TCP listeners
        try
        {
            var tcpListeners = properties.GetActiveTcpListeners();
            var tcpConnections = properties.GetActiveTcpConnections();

            // GetActiveTcpListeners gives us endpoints but not PIDs.
            // We need netstat-style data, so fall back to parsing netstat.
            results.AddRange(GetPortsFromNetstat());
        }
        catch (Exception)
        {
            // Fallback: try netstat parsing
            results.AddRange(GetPortsFromNetstat());
        }

        return results
            .Where(p => p.Port >= MinPort && p.Port <= MaxPort)
            .OrderBy(p => p.Port)
            .ToList();
    }

    private static List<PortInfo> GetPortsFromNetstat()
    {
        var results = new List<PortInfo>();

        try
        {
            var psi = new ProcessStartInfo
            {
                FileName = "netstat",
                Arguments = "-ano -p TCP",
                RedirectStandardOutput = true,
                UseShellExecute = false,
                CreateNoWindow = true,
            };

            using var process = Process.Start(psi);
            if (process == null)
            {
                return results;
            }

            var output = process.StandardOutput.ReadToEnd();
            process.WaitForExit();

            var lines = output.Split('\n', StringSplitOptions.RemoveEmptyEntries);

            foreach (var line in lines)
            {
                var trimmed = line.Trim();
                if (!trimmed.StartsWith("TCP", StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                // Only include LISTENING ports
                if (!trimmed.Contains("LISTENING", StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                var parts = trimmed.Split(' ', StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length < 5)
                {
                    continue;
                }

                // Parse local address (e.g., "0.0.0.0:3000" or "[::]:3000")
                var localAddress = parts[1];
                var lastColon = localAddress.LastIndexOf(':');
                if (lastColon < 0)
                {
                    continue;
                }

                if (!int.TryParse(localAddress[(lastColon + 1)..], out var port))
                {
                    continue;
                }

                if (!int.TryParse(parts[4], out var pid))
                {
                    continue;
                }

                var processName = GetProcessName(pid);
                results.Add(new PortInfo(port, pid, processName, "TCP"));
            }
        }
        catch (Exception)
        {
            // Silently fail — can't enumerate ports
        }

        // Deduplicate (same port may appear for 0.0.0.0 and [::])
        return results
            .GroupBy(p => p.Port)
            .Select(g => g.First())
            .ToList();
    }

    private static string GetProcessName(int pid)
    {
        try
        {
            var process = Process.GetProcessById(pid);
            return process.ProcessName;
        }
        catch
        {
            return $"PID {pid}";
        }
    }

    public static bool KillProcess(int pid)
    {
        try
        {
            var process = Process.GetProcessById(pid);
            process.Kill(entireProcessTree: true);
            process.WaitForExit(5000);
            return true;
        }
        catch
        {
            return false;
        }
    }
}
