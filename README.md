# Worldbuilt: Unbound

An unofficial mod loader for **Worldbuilt**.

Worldbuilt: Unbound adds an in-game mod menu and supports ZIP entrypoint mods and PCK patch mods without distributing a modified copy of the game.

## Current Version

**0.1.0 MVP**

## Features

- In-game Mods menu
- Enable and disable installed mods
- Persistent enabled states
- ZIP entrypoint mods
- PCK patch mods
- Multiple mods loaded together
- Sidecar manifests for PCK mods
- Manifest-defined input actions
- Duplicate mod ID protection
- Manifest and entrypoint validation
- PowerShell installer and uninstaller
- Existing mods are preserved during uninstall

## Requirements

- Windows
- Worldbuilt Alpha 0.1
- Mods built for a compatible Godot version

Worldbuilt Alpha 0.1 currently uses Godot 4.7.dev1.

## Installation

Open PowerShell in the repository folder and run:

```powershell
powershell -ExecutionPolicy Bypass `
  -File .\installer\install.ps1 `
  -GameDirectory "C:\Path\To\Worldbuilt"
```

The selected folder must contain the Worldbuilt executable.

## Installing Mods

Place compatible mods inside:

```text
Worldbuilt\mods
```

Launch Worldbuilt and open the `MODS` menu.

```text
[X] Enabled
[ ] Disabled
```

Restart the game after changing a mod's enabled state.

## Supported Formats

### ZIP Entrypoint Mods

```text
ExampleMod.zip
├── manifest.json
└── mods/
    └── author.example_mod/
        └── mod_main.gd
```

### PCK Patch Mods

```text
ExamplePatch.pck
ExamplePatch.json
```

PCK patch mods can replace existing game resources and may conflict with other patch mods.

See [`docs/MODDING.md`](docs/MODDING.md) for the full format.

## Uninstallation

```powershell
powershell -ExecutionPolicy Bypass `
  -File .\installer\uninstall.ps1 `
  -GameDirectory "C:\Path\To\Worldbuilt"
```

The loader is removed, but the `mods` folder is preserved.

## Current Limitations

- Mods require a restart to enable or disable.
- Mods cannot be unloaded while the game is running.
- Patch mods may conflict when replacing the same resource.
- There is no dependency resolver yet.
- There is no graphical installer yet.

## Disclaimer

Worldbuilt: Unbound is an unofficial community project and is not affiliated with or endorsed by the developer of Worldbuilt.

Back up save files before testing unfinished mods.
