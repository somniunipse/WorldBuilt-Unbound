extends Node2D

const MODS_FOLDER_NAME := "mods"
const MAX_VISIBLE_MODS := 3

const MOD_CATALOG_SCRIPT := preload(
	"res://addons/worldbuilt_unbound/core/mod_catalog.gd"
)

const MOD_SETTINGS_SCRIPT := preload(
	"res://addons/worldbuilt_unbound/core/mod_settings.gd"
)

const TITLE_POSITION := Vector2(35.0, 92.0)
const EMPTY_MESSAGE_POSITION := Vector2(35.0, 118.0)
const MOD_ROW_START_POSITION := Vector2(35.0, 116.0)
const RESTART_MESSAGE_POSITION := Vector2(35.0, 148.0)
const OPEN_FOLDER_POSITION := Vector2(35.0, 160.0)
const BACK_POSITION := Vector2(35.0, 187.0)

const MOD_ROW_SIZE := Vector2(220.0, 10.0)
const MOD_ROW_SPACING := 10.0

const LABEL_WIDTH := 220.0
const LABEL_HEIGHT := 20.0

var _main_menu_buttons: Array[Button] = []
var _mod_row_buttons: Array[Button] = []

var _button_template: Button
var _mod_catalog := MOD_CATALOG_SCRIPT.new()
var _mod_settings := MOD_SETTINGS_SCRIPT.new()

var _installed_mods: Array[Dictionary] = []
var _restart_required := false


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
		EMPTY_MESSAGE_POSITION,
		5
	)

	_add_label(
		"RestartMessage",
		"RESTART REQUIRED",
		RESTART_MESSAGE_POSITION,
		5
	)

	var restart_message := get_node(
		"RestartMessage"
	) as Label

	restart_message.hide()

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
	label.size = Vector2(
		LABEL_WIDTH,
		LABEL_HEIGHT
	)

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
) -> Button:
	var button := _button_template.duplicate(0) as Button

	if button == null:
		push_error(
			"[Unbound] Could not create button: %s"
			% node_name
		)
		return null

	button.name = node_name
	button.text = button_text
	button.position = button_position
	button.pressed.connect(callback)

	add_child(button)

	return button


func _refresh_mod_list() -> void:
	_clear_mod_rows()

	var empty_message := get_node_or_null(
		"EmptyMessage"
	) as Label

	if empty_message == null:
		push_warning(
			"[Unbound] Could not find EmptyMessage."
		)
		return

	if not _ensure_mods_directory():
		empty_message.text = "MOD FOLDER ERROR"
		empty_message.show()
		return

	_installed_mods = _mod_catalog.scan_directory(
		_get_mods_directory()
	)

	for manifest in _installed_mods:
		var mod_id := str(manifest["id"])

		manifest["enabled"] = _mod_settings.is_enabled(
			mod_id
		)

	if _installed_mods.is_empty():
		empty_message.text = "NO VALID MODS"
		empty_message.show()
		return

	empty_message.hide()

	var visible_count := mini(
		_installed_mods.size(),
		MAX_VISIBLE_MODS
	)

	for index in range(visible_count):
		_add_mod_row(
			index,
			_installed_mods[index]
		)


func _add_mod_row(
	index: int,
	manifest: Dictionary
) -> void:
	var mod_id := str(manifest["id"])

	var row_position := (
		MOD_ROW_START_POSITION
		+ Vector2(
			0.0,
			MOD_ROW_SPACING * index
		)
	)

	var row_button := _button_template.duplicate(0) as Button

	if row_button == null:
		push_error(
			"[Unbound] Could not create a row for %s."
			% mod_id
		)
		return

	row_button.show()

	row_button.name = "ModRow%d" % index
	row_button.position = row_position
	row_button.size = MOD_ROW_SIZE
	row_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row_button.clip_text = true
	row_button.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND
	)

	_hide_button_frame(row_button)
	_update_mod_row_text(row_button, manifest)

	row_button.pressed.connect(
		_toggle_mod.bind(mod_id)
	)

	add_child(row_button)
	_mod_row_buttons.append(row_button)


func _hide_button_frame(button: Button) -> void:
	var frame := button.get_node_or_null(
		"NinePatchRect"
	) as CanvasItem

	if frame != null:
		frame.hide()


func _update_mod_row_text(
	button: Button,
	manifest: Dictionary
) -> void:
	var state_marker := (
		"[X]"
		if bool(manifest["enabled"])
		else "[ ]"
	)

	button.text = "%s %s V%s" % [
		state_marker,
		str(manifest["name"]).to_upper(),
		str(manifest["version"])
	]


func _toggle_mod(mod_id: String) -> void:
	var manifest := _find_mod(mod_id)

	if manifest.is_empty():
		push_warning(
			"[Unbound] Could not find mod: %s"
			% mod_id
		)
		return

	var new_state := not bool(
		manifest["enabled"]
	)

	if not _mod_settings.set_enabled(
		mod_id,
		new_state
	):
		return

	manifest["enabled"] = new_state
	_restart_required = true

	var restart_message := get_node_or_null(
		"RestartMessage"
	) as Label

	if restart_message != null:
		restart_message.show()

	_refresh_mod_list()


func _find_mod(mod_id: String) -> Dictionary:
	for manifest in _installed_mods:
		if str(manifest["id"]) == mod_id:
			return manifest

	return {}


func _clear_mod_rows() -> void:
	for button in _mod_row_buttons:
		button.queue_free()

	_mod_row_buttons.clear()


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
		"[Unbound] Could not create the mods folder: %s"
		% error_string(create_error)
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
			"[Unbound] Could not open the mods folder: %s"
			% error_string(open_error)
		)