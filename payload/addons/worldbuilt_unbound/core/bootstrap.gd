extends Node

const LOADER_NAME := "Worldbuilt: Unbound"
const LOADER_VERSION := "0.1.0"

const MAIN_MENU_PATH := "res://scenes/menu.tscn"
const SOURCE_BUTTON_PATH := NodePath("StartButton")
const MODS_BUTTON_PATH := NodePath("ModsButton")
const MODS_BUTTON_OFFSET := Vector2(0.0, 54.0)


func _ready() -> void:
    print("[%s] Bootstrap loaded. Version %s" % [
        LOADER_NAME,
        LOADER_VERSION
    ])

    get_tree().scene_changed.connect(_on_scene_changed)
    call_deferred("_add_mods_button")


func _on_scene_changed() -> void:
    call_deferred("_add_mods_button")


func _add_mods_button() -> void:
    var current_scene := get_tree().current_scene

    if current_scene == null:
        return

    if current_scene.scene_file_path != MAIN_MENU_PATH:
        return

    if current_scene.has_node(MODS_BUTTON_PATH):
        return

    var source_button := current_scene.get_node_or_null(
        SOURCE_BUTTON_PATH
    ) as Button

    if source_button == null:
        push_warning(
            "[Unbound] Could not find the StartButton."
        )
        return

    var mods_button := source_button.duplicate(0) as Button

    if mods_button == null:
        push_warning(
            "[Unbound] Could not duplicate the StartButton."
        )
        return

    mods_button.name = "ModsButton"
    mods_button.text = "MODS"

    current_scene.add_child(mods_button)

    mods_button.position = (
        source_button.position
        + MODS_BUTTON_OFFSET
    )

    mods_button.pressed.connect(_on_mods_button_pressed)

    print("[Unbound] Added the MODS button.")


func _on_mods_button_pressed() -> void:
    print("[Unbound] MODS button pressed.")