using System;
using System.Linq;
using Microsoft.CommandPalette.Extensions;
using Microsoft.CommandPalette.Extensions.Toolkit;
using PortPilot.Commands;
using PortPilot.Helpers;

namespace PortPilot.Pages;

internal sealed partial class PortListPage : ListPage
{
    public PortListPage()
    {
        Icon = new IconInfo("\uE839"); // Network
        Title = "PortPilot";
        Name = "Open";
        Id = "com.portpilot.portlist";
    }

    public override IListItem[] GetItems()
    {
        var ports = PortScanner.GetListeningPorts();

        if (ports.Count == 0)
        {
            return
            [
                new ListItem(new NoOpCommand())
                {
                    Title = "No listening ports found in range 3000\u201310000",
                    Subtitle = "All clear! No dev servers detected.",
                },
            ];
        }

        return ports.Select(p =>
        {
            var killCommand = new KillProcessCommand(p, this);
            return new ListItem(killCommand)
            {
                Title = $":{p.Port}  \u2014  {p.ProcessName}",
                Subtitle = $"PID {p.ProcessId} \u00B7 {p.Protocol}",
                Icon = new IconInfo("\uE774"), // WebAsset / Globe
            };
        }).ToArray();
    }

    internal void RefreshList()
    {
        RaiseItemsChanged();
    }
}
