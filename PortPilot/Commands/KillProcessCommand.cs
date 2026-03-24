using System;
using Microsoft.CommandPalette.Extensions;
using Microsoft.CommandPalette.Extensions.Toolkit;
using PortPilot.Helpers;
using PortPilot.Pages;

namespace PortPilot.Commands;

internal sealed partial class KillProcessCommand : InvokableCommand
{
    private readonly PortInfo _portInfo;
    private readonly PortListPage _page;

    public KillProcessCommand(PortInfo portInfo, PortListPage page)
    {
        _portInfo = portInfo;
        _page = page;
        Name = $"Free port {portInfo.Port}";
        Icon = new IconInfo("\uE74D"); // Delete icon
    }

    public override CommandResult Invoke()
    {
        var confirmArgs = new ConfirmationArgs
        {
            Title = $"Kill process on port {_portInfo.Port}?",
            Description = $"This will terminate **{_portInfo.ProcessName}** (PID {_portInfo.ProcessId}) listening on port {_portInfo.Port}.",
            PrimaryCommand = new AnonymousCommand(() =>
            {
                var success = PortScanner.KillProcess(_portInfo.ProcessId);
                if (success)
                {
                    var toast = new ToastStatusMessage($"Freed port {_portInfo.Port} — killed {_portInfo.ProcessName}");
                    toast.Show();
                }
                else
                {
                    var toast = new ToastStatusMessage($"Failed to kill {_portInfo.ProcessName} on port {_portInfo.Port}. May need admin rights.");
                    toast.Show();
                }

                _page.RefreshList();
            })
            {
                Name = "Kill Process",
                Result = CommandResult.KeepOpen(),
            },
        };

        return CommandResult.Confirm(confirmArgs);
    }
}
