using Microsoft.CommandPalette.Extensions;
using Microsoft.CommandPalette.Extensions.Toolkit;
using PortPilot.Pages;

namespace PortPilot;

public partial class PortPilotCommandsProvider : CommandProvider
{
    private readonly ICommandItem[] _commands;
    private readonly PortListPage _portListPage;

    public PortPilotCommandsProvider()
    {
        DisplayName = "PortPilot";
        Id = "com.portpilot";
        Icon = new IconInfo("\uE839"); // Network icon

        _portListPage = new PortListPage();
        _commands =
        [
            new CommandItem(_portListPage)
            {
                Title = "PortPilot",
                Subtitle = "Find and free dev server ports",
            },
        ];
    }

    public override ICommandItem[] TopLevelCommands() => _commands;

    public override ICommandItem[]? GetDockBands()
    {
        var dockBand = new WrappedDockItem(
            _portListPage,
            "PortPilot — Ports");
        return [dockBand];
    }
}
