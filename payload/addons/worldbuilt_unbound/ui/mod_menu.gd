extends Node2D

const MODS_FOLDER_NAME := "mods"

const TITLE_POSITION := Vector2(35.0, 92.0)
const MESSAGE_POSITION := Vector2(35.0, 118.0)
const OPEN_FOLDER_POSITION := Vector2(35.0, 141.0)
const BACK_POSITION := Vector2(35.0, 168.0)

const LABEL_WIDTH := 134.0
const LABEL_HEIGHT := 20.0

var _main_menu_buttons: Array[Button] = []
var _button_template: Button


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


func _open_mods_folder() -> void:
	var game_directory := OS.get_executable_path().get_base_dir()
	var mods_directory := game_directory.path_join(
		MODS_FOLDER_NAME
	)

	var create_error := DirAccess.make_dir_recursive_absolute(
		mods_directory
	)

	if create_error != OK:
		push_error(
			"[Unbound] Could not create the mods folder."
		)
		return

	var open_error := OS.shell_open(mods_directory)

	if open_error != OK:
		push_error(
			"[Unbound] Could not open the mods folder."
		)