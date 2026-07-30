extends RefCounted

const MODS_FOLDER_NAME := "mods"

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

	var entrypoint := str(
		manifest["entrypoint"]
	)

	var pack_loaded := (
		ProjectSettings.load_resource_pack(
			archive_path,
			false
		)
	)

	if not pack_loaded:
		push_error(
			"[Unbound] Could not mount mod archive: %s"
			% archive_path.get_file()
		)
		return

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

	# Each mod starts through a separate deferred call.
	# An error in one mod is less likely to block later mods.
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