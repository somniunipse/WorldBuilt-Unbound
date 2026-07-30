extends Node2D

const MODS_FOLDER_NAME := "mods"
const MAX_VISIBLE_MODS := 3
const MOD_CATALOG_SCRIPT := preload(
	"res://addons/worldbuilt_unbound/core/mod_catalog.gd"
)

const TITLE_POSITION := Vector2(35.0, 92.0)
const MESSAGE_POSITION := Vector2(35.0, 118.0)
const OPEN_FOLDER_POSITION := Vector2(35.0, 141.0)
const BACK_POSITION := Vector2(35.0, 168.0)

const LABEL_WIDTH := 134.0
const LABEL_HEIGHT := 20.0

var _main_menu_buttons: Array[Button] = []
var _button_template: Button
var _mod_catalog := MOD_CATALOG_SCRIPT.new()


func setup(
	start_button: Button,
	delete_button: Button,
	mods_button: Button
) -> void:
	_button_template = start_button
	_main_menu_buttons = [
		start_button,
		delete_button,
		mods_button
	]

	_add_label(
		"ModsTitle",
		"MODS",
		TITLE_POSITION,
		10
	)

	_add_label(
		"EmptyMessage",
		"NO MODS INSTALLED",
		MESSAGE_POSITION,
		5
	)

	var mod_list_label := get_node("EmptyMessage") as Label
	mod_list_label.size = Vector2(220.0, 28.0)

	_add_button(
		"OpenFolderButton",
		"OPEN FOLDER",
		OPEN_FOLDER_POSITION,
		_open_mods_folder
	)

	_add_button(
		"BackButton",
		"BACK",
		BACK_POSITION,
		close
	)

	hide()


func open() -> void:
	_refresh_mod_list()

	for button in _main_menu_buttons:
		button.hide()

	show()


func close() -> void:
	hide()

	for button in _main_menu_buttons:
		button.show()


func _add_label(
	node_name: String,
	label_text: String,
	label_position: Vector2,
	font_size: int
) -> void:
	var label := Label.new()

	label.name = node_name
	label.text = label_text
	label.position = label_position
	label.size = Vector2(LABEL_WIDTH, LABEL_HEIGHT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	label.add_theme_font_override(
		"font",
		_button_template.get_theme_font("font")
	)

	label.add_theme_font_size_override(
		"font_size",
		font_size
	)

	add_child(label)


func _add_button(
	node_name: String,
	button_text: String,
	button_position: Vector2,
	callback: Callable
) -> void:
	var button := _button_template.duplicate(0) as Button

	if button == null:
		push_error(
			"[Unbound] Could not create button: %s"
			% node_name
		)
		return

	button.name = node_name
	button.text = button_text
	button.position = button_position
	button.pressed.connect(callback)

	add_child(button)


func _refresh_mod_list() -> void:
	var mod_list_label := get_node_or_null(
		"EmptyMessage"
	) as Label

	if mod_list_label == null:
		push_warning(
			"[Unbound] Could not find the mod list label."
		)
		return

	if not _ensure_mods_directory():
		mod_list_label.text = "MOD FOLDER ERROR"
		return

	var installed_mods := _mod_catalog.scan_directory(
		_get_mods_directory()
	)

	if installed_mods.is_empty():
		mod_list_label.text = "NO VALID MODS"
		return

	mod_list_label.text = _format_mod_list(
		installed_mods
	)


func _format_mod_list(
	installed_mods: Array[Dictionary]
) -> String:
	var output := ""
	var visible_count := mini(
		installed_mods.size(),
		MAX_VISIBLE_MODS
	)

	for index in range(visible_count):
		var manifest := installed_mods[index]

		if not output.is_empty():
			output += "\n"

		output += "%s V%s" % [
			str(manifest["name"]).to_upper(),
			str(manifest["version"])
		]

	var hidden_count := (
		installed_mods.size()
		- visible_count
	)

	if hidden_count > 0:
		output += "\n+%d MORE" % hidden_count

	return output


func _get_mods_directory() -> String:
	var game_directory := (
		OS.get_executable_path().get_base_dir()
	)

	return game_directory.path_join(
		MODS_FOLDER_NAME
	)


func _ensure_mods_directory() -> bool:
	var create_error := DirAccess.make_dir_recursive_absolute(
		_get_mods_directory()
	)

	if create_error == OK:
		return true

	push_error(
		"[Unbound] Could not create the mods folder."
	)

	return false


func _open_mods_folder() -> void:
	if not _ensure_mods_directory():
		return

	var open_error := OS.shell_open(
		_get_mods_directory()
	)

	if open_error != OK:
		push_error(
			"[Unbound] Could not open the mods folder."
		)