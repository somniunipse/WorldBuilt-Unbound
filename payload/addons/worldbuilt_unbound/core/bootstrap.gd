extends Node

const LOADER_NAME := "Worldbuilt: Unbound"
const LOADER_VERSION := "0.1.0"


func _ready() -> void:
    var game_name := str(
        ProjectSettings.get_setting("application/config/name")
    )

    DisplayServer.window_set_title(
        "%s [Unbound %s]" % [game_name, LOADER_VERSION]
    )

    print(
        "[%s] Bootstrap loaded. Version %s"
        % [LOADER_NAME, LOADER_VERSION]
    )