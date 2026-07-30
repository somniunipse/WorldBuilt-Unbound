extends RefCounted

const SETTINGS_DIRECTORY := "user://worldbuilt_unbound"
const SETTINGS_PATH := SETTINGS_DIRECTORY + "/mods.cfg"
const MODS_SECTION := "mods"

var _config := ConfigFile.new()


func _init() -> void:
	_load()


func is_enabled(mod_id: String) -> bool:
	return bool(
		_config.get_value(
			MODS_SECTION,
			mod_id,
			true
		)
	)


func set_enabled(
	mod_id: String,
	enabled: bool
) -> bool:
	_config.set_value(
		MODS_SECTION,
		mod_id,
		enabled
	)

	return _save()


func _load() -> void:
	var load_error := _config.load(
		SETTINGS_PATH
	)

	if (
		load_error == OK
		or load_error == ERR_FILE_NOT_FOUND
	):
		return

	push_warning(
		"[Unbound] Could not load mod settings: %s"
		% error_string(load_error)
	)


func _save() -> bool:
	var absolute_directory := ProjectSettings.globalize_path(
		SETTINGS_DIRECTORY
	)

	var directory_error := (
		DirAccess.make_dir_recursive_absolute(
			absolute_directory
		)
	)

	if directory_error != OK:
		push_error(
			"[Unbound] Could not create the settings folder: %s"
			% error_string(directory_error)
		)
		return false

	var save_error := _config.save(
		SETTINGS_PATH
	)

	if save_error != OK:
		push_error(
			"[Unbound] Could not save mod settings: %s"
			% error_string(save_error)
		)
		return false

	return true