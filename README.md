# SteamRelief

SteamRelief is a Windows tray app that reduces the resident memory used by Steam's Chromium WebHelpers while Steam is in the background. This fork of [Fooly-Cooly's SteamRelief](https://github.com/Fooly-Cooly/SteamRelief) uses native Windows process APIs and keeps watching across Steam and WebHelper restarts.

## Download and update

Download the **Windows x64** ZIP for 64-bit Windows or the **Windows x86** ZIP for 32-bit Windows from the [latest release](https://github.com/C1yHAX/SteamRelief/releases/latest). Extract it to a permanent folder and run `SteamRelief.exe`. The executable includes its AutoHotkey runtime.

To update an existing installation, exit SteamRelief from the tray and replace its EXE in the same folder. Keep your existing `SteamRelief.ini` to preserve your settings. Missing keys use the defaults below. An existing startup shortcut will continue to use that location.

## Using SteamRelief

Run `SteamRelief.exe`. Hover over the tray icon to see the combined memory for the Steam client and its WebHelpers, the WebHelpers' subtotal and the result of the last trim. Click the icon to open Steam. Right-click for configuration, autostart and exit.

Every ten seconds SteamRelief checks whether the Steam client, a WebHelper or Steam's overlay owns the foreground window. By default, once Steam has been in the background for a minute and its WebHelpers together use at least 256 MiB, SteamRelief asks Windows to trim their working sets. It waits five minutes before another attempt. A game or the main Steam client can keep running throughout.

The tooltip uses the private working set on Windows versions that expose it. On older versions it labels the total working set, which includes shared pages. A trim lets Windows reuse resident pages. Steam retains its allocations and can bring pages back into RAM when a window, download or background task needs them. The threshold triggers an attempt and usage can rise above it.

## Configuration

Edit `SteamRelief.ini` next to the executable, then exit and relaunch SteamRelief to apply changes. Existing INI files use the following defaults for missing settings.

| Setting | Default | Behavior |
| --- | --- | --- |
| `NoTray` | `0` | Set to `1` to hide the tray icon. |
| `StartSteam` | `1` | Start Steam if needed. Set to `0` to wait quietly for Steam. |
| `LaunchParams` | `open/minigameslist` | Steam URI path to open at startup. Other examples are in the INI. |
| `IdleSeconds` | `60` | Minimum time in the background before a trim. |
| `MinWebHelperMiB` | `256` | Combined WebHelper working set that triggers a trim. |
| `CooldownSeconds` | `300` | Minimum time between trim attempts while the helpers are running. |

## Build from source

The release uses [AutoHotkey v1.1.37.02](https://github.com/AutoHotkey/AutoHotkey/releases/tag/v1.1.37.02) and its bundled Ahk2Exe compiler. With a portable installation, set `AHK_DIR` to the folder that contains `Compiler`. Run `make.bat x64` or `make.bat x86` to build `SteamRelief.exe` next to the script. To run the scripts directly, open `SteamRelief.ahk` with Unicode AutoHotkey v1.1.33 or later in the v1 series and keep `SteamProcesses.ahk` alongside it.

SteamRelief is distributed under the [GNU GPL v3](LICENSE). The portable packages include the license for the bundled AutoHotkey runtime. Its corresponding source is available at the [AutoHotkey v1.1.37.02 tag](https://github.com/AutoHotkey/AutoHotkey/tree/v1.1.37.02).
