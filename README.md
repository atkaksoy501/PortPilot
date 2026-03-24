<div align="center">

# ⚓ PortPilot

**Find and free dev server ports — right from PowerToys Command Palette.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![.NET 9](https://img.shields.io/badge/.NET-9.0-purple.svg)](https://dotnet.microsoft.com/)
[![PowerToys](https://img.shields.io/badge/PowerToys-Command%20Palette-0078D4.svg)](https://learn.microsoft.com/windows/powertoys/command-palette/)

</div>

---

Ever typed `netstat -ano | findstr LISTENING` just to find what's hogging port 3000? **PortPilot** puts that workflow inside PowerToys Command Palette — search, spot, and kill dev server processes in seconds.

## ✨ Features

| Feature | Description |
|---|---|
| 🔍 **Port scanning** | Lists all TCP listening ports in the 3000–10000 range |
| 📋 **Process info** | Shows process name, PID, and protocol for each port |
| ⚠️ **Safe kill** | Confirmation dialog before terminating any process |
| 🔎 **Fuzzy search** | Filter by port number or process name |
| 📌 **Dock support** | Pin to the Command Palette Dock for one-click access |
| 🔄 **Auto-refresh** | List refreshes automatically after killing a process |

## 🚀 Quick Start

### Prerequisites

- **Windows 11** with [PowerToys](https://github.com/microsoft/PowerToys) installed (Command Palette enabled)
- **Developer Mode** enabled — *Settings → System → For developers → Developer Mode → ON*
- [**.NET 9 SDK**](https://dotnet.microsoft.com/download/dotnet/9.0)

### Install & Deploy

```powershell
git clone https://github.com/atkaksoy501/PortPilot.git
cd PortPilot
.\Deploy.ps1
```

The deploy script builds a self-contained executable and registers it as a loose-file MSIX package. No admin rights required.

After deploying:
1. Open Command Palette (`Win+Alt+Space`)
2. Type **Reload** → select **Reload Command Palette extensions**
3. Search for **PortPilot**

### Rebuild after changes

```powershell
.\Deploy.ps1           # Build + register
.\Deploy.ps1 -SkipBuild   # Re-register only (no rebuild)
```

## 🎯 Usage

1. Open **PowerToys Command Palette**
2. Search for **PortPilot** and press Enter
3. Browse listening ports — each entry shows `:PORT — ProcessName`
4. Select a port → confirm the kill dialog → process terminated
5. Optionally **pin to the Dock** for one-click access

## 🏗️ Project Structure

```
PortPilot/
├── Deploy.ps1                        # Build & deploy script
├── PortPilot.sln                     # Solution file
└── PortPilot/
    ├── Program.cs                    # COM server entry point
    ├── PortPilotExtension.cs         # IExtension implementation
    ├── PortPilotCommandsProvider.cs  # Top-level commands + dock bands
    ├── Pages/
    │   └── PortListPage.cs           # ListPage showing active ports
    ├── Commands/
    │   └── KillProcessCommand.cs     # Kill with confirmation dialog
    ├── Helpers/
    │   └── PortScanner.cs            # Port scanning via netstat
    ├── Package.appxmanifest          # MSIX / COM registration
    └── Assets/                       # Extension icons
```

## ⚙️ How It Works

1. **PortScanner** runs `netstat -ano -p TCP` and parses LISTENING connections
2. Filters to the 3000–10000 port range (typical dev server ports)
3. Resolves each PID to a process name via `Process.GetProcessById()`
4. Displays results as a searchable `ListPage` in Command Palette
5. Kill commands use `Process.Kill(entireProcessTree: true)` with a `CommandResult.Confirm()` dialog

## 🔧 Configuration

| Setting | Default | Location |
|---|---|---|
| Port range | 3000–10000 | `PortScanner.cs` (`MinPort` / `MaxPort`) |
| Protocol | TCP only | `PortScanner.cs` |

To customize the port range, edit the constants in `Helpers/PortScanner.cs` and redeploy.

## 🤝 Contributing

Contributions welcome! Some ideas:

- [ ] Configurable port range via Command Palette settings
- [ ] UDP port support
- [ ] Show which command started the process (e.g., `node server.js`)
- [ ] Port conflict detection (find what *will* conflict before starting a server)
- [ ] Custom icons per process type (Node.js, Python, Java, etc.)

## 📄 License

[MIT](LICENSE)

