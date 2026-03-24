using System;
using System.Runtime.InteropServices;
using System.Threading;
using Microsoft.CommandPalette.Extensions;

namespace PortPilot;

[ComVisible(true)]
[Guid("B74E2E5A-8F3C-4A1D-9C7B-6D8F2E1A3B5C")]
[ComDefaultInterface(typeof(IExtension))]
public sealed partial class PortPilotExtension : IExtension, IDisposable
{
    private readonly ManualResetEvent _extensionDisposedEvent;
    private readonly PortPilotCommandsProvider _provider = new();

    public PortPilotExtension(ManualResetEvent extensionDisposedEvent)
    {
        _extensionDisposedEvent = extensionDisposedEvent;
    }

    public object GetProvider(ProviderType providerType)
    {
        return providerType switch
        {
            ProviderType.Commands => _provider,
            _ => null!,
        };
    }

    public void Dispose()
    {
        _extensionDisposedEvent.Set();
    }
}
