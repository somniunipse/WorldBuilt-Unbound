extends RefCounted

const MODS_FOLDER_NAME := "mods"

const MODE_ENTRYPOINT := "entrypoint"
const MODE_PATCH := "patch"

const MOD_CATALOG_SCRIPT := preload(
	"res://addons/worldbuilt_unbound/core/mod_catalog.gd"
)

const MOD_SETTINGS_SCRIPT := preload(
	"res://addons/worldbuilt_unbound/core/mod_settings.gd"
)

var _mod_catalog := MOD_CATALOG_SCRIPT.new()
var _mod_settings := MOD_SETTINGS_SCRIPT.new()


func load_enabled_mods(host: Node) -> void:
	var mods_directory := (
		OS.get_executable_path()
		.get_base_dir()
		.path_join(MODS_FOLDER_NAME)
	)

	var directory_error := (
		DirAccess.make_dir_recursive_absolute(
			mods_directory
		)
	)

	if directory_error != OK:
		push_error(
			"[Unbound] Could not prepare the mods folder: %s"
			% error_string(directory_error)
		)
		return

	var installed_mods := _mod_catalog.scan_directory(
		mods_directory
	)

	for manifest in installed_mods:
		var mod_id := str(
			manifest["id"]
		)

		if not _mod_settings.is_enabled(mod_id):
			print(
				"[Unbound] Skipping disabled mod: %s"
				% mod_id
			)
			continue

		_mount_mod(
			host,
			manifest
		)


func _mount_mod(
	host: Node,
	manifest: Dictionary
) -> void:
	var mod_id := str(
		manifest["id"]
	)

	var archive_path := str(
		manifest["archive_path"]
	)

	var mode := str(
		manifest.get(
			"mode",
			MODE_ENTRYPOINT
		)
	)

	var replace_files := (
		mode == MODE_PATCH
	)

	var pack_loaded := (
		ProjectSettings.load_resource_pack(
			archive_path,
			replace_files
		)
	)

	if not pack_loaded:
		push_error(
			"[Unbound] Could not mount mod archive: %s"
			% archive_path.get_file()
		)
		return

	_register_input_actions(manifest)

	if mode == MODE_PATCH:
		print(
			"[Unbound] Mounted patch mod: %s"
			% mod_id
		)
		return

	_prepare_entrypoint(
		host,
		manifest
	)


func _register_input_actions(
	manifest: Dictionary
) -> void:
	var input_actions_value: Variant = manifest.get(
		"input_actions",
		{}
	)

	if typeof(input_actions_value) != TYPE_DICTIONARY:
		push_warning(
			"[Unbound] Mod '%s' has invalid input_actions."
			% str(manifest["id"])
		)
		return

	var input_actions: Dictionary = input_actions_value

	for action_value in input_actions:
		var action_name := str(
			action_value
		).strip_edges()

		var key_name := str(
			input_actions[action_value]
		).strip_edges()

		if action_name.is_empty() or key_name.is_empty():
			push_warning(
				"[Unbound] Mod '%s' contains an invalid input action."
				% str(manifest["id"])
			)
			continue

		var keycode := OS.find_keycode_from_string(
			key_name
		)

		if keycode == KEY_NONE:
			push_warning(
				"[Unbound] Unknown key '%s' for action '%s'."
				% [
					key_name,
					action_name
				]
			)
			continue

		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)

		var key_event := InputEventKey.new()
		key_event.keycode = keycode

		if not InputMap.action_has_event(
			action_name,
			key_event
		):
			InputMap.action_add_event(
				action_name,
				key_event
			)

		print(
			"[Unbound] Registered input action: %s = %s"
			% [
				action_name,
				key_name
			]
		)


func _prepare_entrypoint(
	host: Node,
	manifest: Dictionary
) -> void:
	var mod_id := str(
		manifest["id"]
	)

	var entrypoint := str(
		manifest["entrypoint"]
	)

	if not ResourceLoader.exists(
		entrypoint,
		"Script"
	):
		push_error(
			"[Unbound] Entrypoint does not exist for %s: %s"
			% [
				mod_id,
				entrypoint
			]
		)
		return

	var entry_script := load(
		entrypoint
	) as Script

	if entry_script == null:
		push_error(
			"[Unbound] Could not load entrypoint for %s: %s"
			% [
				mod_id,
				entrypoint
			]
		)
		return

	if not entry_script.can_instantiate():
		push_error(
			"[Unbound] Entrypoint cannot be instantiated: %s"
			% mod_id
		)
		return

	call_deferred(
		"_start_mod",
		host,
		entry_script,
		manifest
	)


func _start_mod(
	host: Node,
	entry_script: Script,
	manifest: Dictionary
) -> void:
	var mod_id := str(
		manifest["id"]
	)

	if not is_instance_valid(host):
		push_error(
			"[Unbound] Loader host disappeared before %s started."
			% mod_id
		)
		return

	var mod_node := entry_script.new() as Node

	if mod_node == null:
		push_error(
			"[Unbound] Entrypoint must extend Node: %s"
			% mod_id
		)
		return

	mod_node.name = (
		"Mod_%s"
		% mod_id.replace(".", "_")
	)

	host.add_child(mod_node)

	print(
		"[Unbound] Loaded mod: %s"
		% mod_id
	)