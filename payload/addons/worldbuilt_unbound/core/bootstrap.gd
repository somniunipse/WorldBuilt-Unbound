extends Node

const LOADER_NAME := "Worldbuilt: Unbound"
const LOADER_VERSION := "0.1.0"

const MAIN_MENU_PATH := "res://scenes/menu.tscn"
const MOD_MENU_SCRIPT_PATH := (
	"res://addons/worldbuilt_unbound/ui/mod_menu.gd"
)

const MOD_RUNTIME_SCRIPT := preload(
	"res://addons/worldbuilt_unbound/core/mod_runtime.gd"
)

const START_BUTTON_PATH := NodePath("StartButton")
const DELETE_BUTTON_PATH := NodePath("DeleteSave")
const MODS_BUTTON_PATH := NodePath("ModsButton")
const MODS_BUTTON_OFFSET := Vector2(0.0, 54.0)

var _mod_runtime := MOD_RUNTIME_SCRIPT.new()

func _init() -> void:
	_mod_runtime.load_enabled_mods(self)

func _ready() -> void:
	print(
		"[%s] Bootstrap loaded. Version %s"
		% [LOADER_NAME, LOADER_VERSION]
	)

	get_tree().scene_changed.connect(
		_on_scene_changed
	)

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

	var start_button := current_scene.get_node_or_null(
		START_BUTTON_PATH
	) as Button

	var delete_button := current_scene.get_node_or_null(
		DELETE_BUTTON_PATH
	) as Button

	if start_button == null:
		push_warning(
			"[Unbound] Could not find StartButton."
		)
		return

	if delete_button == null:
		push_warning(
			"[Unbound] Could not find DeleteSave."
		)
		return

	var mods_button := start_button.duplicate(0) as Button

	if mods_button == null:
		push_warning(
			"[Unbound] Could not create ModsButton."
		)
		return

	mods_button.name = "ModsButton"
	mods_button.text = "MODS"

	current_scene.add_child(mods_button)

	mods_button.position = (
		start_button.position
		+ MODS_BUTTON_OFFSET
	)

	var mod_menu := _create_mod_menu(
		current_scene,
		start_button,
		delete_button,
		mods_button
	)

	if mod_menu == null:
		mods_button.queue_free()
		return

	mods_button.pressed.connect(
		Callable(mod_menu, "open")
	)

	print("[Unbound] Added the MODS button and menu.")


func _create_mod_menu(
	current_scene: Node,
	start_button: Button,
	delete_button: Button,
	mods_button: Button
) -> Node2D:
	var mod_menu_script := load(
		MOD_MENU_SCRIPT_PATH
	) as Script

	if mod_menu_script == null:
		push_error(
			"[Unbound] Could not load mod_menu.gd."
		)
		return null

	var mod_menu := mod_menu_script.new() as Node2D

	if mod_menu == null:
		push_error(
			"[Unbound] Could not create the mod menu."
		)
		return null

	mod_menu.name = "UnboundModMenu"
	current_scene.add_child(mod_menu)

	mod_menu.call(
		"setup",
		start_button,
		delete_button,
		mods_button
	)

	return mod_menu