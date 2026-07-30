# Worldbuilt: Unbound Modding Guide

This guide describes the mod formats supported by Worldbuilt: Unbound 0.1.0.

## Supported Mod Types

Unbound supports two modes:

- `entrypoint`
- `patch`

### Entrypoint Mods

Entrypoint mods add new code and resources under a unique mod directory. They are the safer and preferred format.

### Patch Mods

Patch mods replace existing Worldbuilt resources. They are more likely to conflict with each other.

## Mod IDs

Use a unique ID in this format:

```text
author.mod_name
```

Examples:

```text
somnium.example_mod
mineventures.jbuild
```

Entrypoint resources must live under:

```text
res://mods/<mod_id>/
```

## ZIP Entrypoint Mods

Structure:

```text
Example Mod.zip
├── manifest.json
└── mods/
    └── somnium.example_mod/
        └── mod_main.gd
```

Manifest:

```json
{
  "id": "somnium.example_mod",
  "name": "Example Mod",
  "version": "0.1.0",
  "author": "Somnium.Ipse",
  "game_version": "0.1",
  "mode": "entrypoint",
  "entrypoint": "res://mods/somnium.example_mod/mod_main.gd"
}
```

Entrypoint:

```gdscript
extends Node

func _ready() -> void:
    print("[Example Mod] Mod loaded.")
```

## PCK Patch Mods

Structure:

```text
WorldbuiltAlphaJBUILD.pck
WorldbuiltAlphaJBUILD.json
```

The base filenames must match exactly.

Manifest:

```json
{
  "id": "mineventures.jbuild",
  "name": "JBUILD Dev Keybinds",
  "version": "0.1.0",
  "author": "Mineventures",
  "game_version": "0.1",
  "mode": "patch"
}
```

Patch mods do not require an entrypoint. They may replace resources such as:

```text
res://scripts/player.gd
res://scenes/player.tscn
res://textures/example.png
```

## Input Actions

A mod can request InputMap actions:

```json
{
  "input_actions": {
    "toggle_low_gravity": "G",
    "toggle_noclip": "N"
  }
}
```

Use unique action names when possible.

## Manifest Fields

Required:

- `id`
- `name`
- `version`
- `author`
- `game_version`

Optional:

- `mode`
- `entrypoint`
- `input_actions`

`entrypoint` is required when `mode` is `entrypoint`.

## Testing

Place the mod in the game's `mods` folder, enable it, fully close Worldbuilt, and launch it again.

Use `--verbose` during development so loader messages and errors are visible.

## Recommendations

- Prefer entrypoint mods when possible.
- Keep entrypoint resources under the mod's unique namespace.
- Avoid generic InputMap action names.
- Document every Worldbuilt resource replaced by a patch mod.
- Test alongside other mods.
- Back up saves before testing unfinished patch mods.
