extends RefCounted

const MANIFEST_FILE := "manifest.json"

const MODE_ENTRYPOINT := "entrypoint"
const MODE_PATCH := "patch"

const SUPPORTED_ARCHIVE_EXTENSIONS := [
    "zip",
    "pck"
]

const REQUIRED_FIELDS := [
    "id",
    "name",
    "version",
    "author",
    "game_version"
]

const INVALID_ID_CHARACTERS := [
    "/",
    "\\",
    ":",
    " ",
    "\t",
    "\n",
    "\r"
]


func scan_directory(mods_directory: String) -> Array[Dictionary]:
    var installed_mods: Array[Dictionary] = []
    var seen_ids := {}

    var directory := DirAccess.open(mods_directory)

    if directory == null:
        push_error(
            "[Unbound] Could not open the mods directory."
        )
        return installed_mods

    directory.list_dir_begin()

    var file_name := directory.get_next()

    while not file_name.is_empty():
        var archive_extension := (
            file_name.get_extension().to_lower()
        )

        if (
            not directory.current_is_dir()
            and archive_extension in SUPPORTED_ARCHIVE_EXTENSIONS
        ):
            var archive_path := mods_directory.path_join(
                file_name
            )

            var manifest := _read_manifest(
                archive_path,
                archive_extension
            )

            if not manifest.is_empty():
                var mod_id := str(
                    manifest["id"]
                )

                var normalized_id := mod_id.to_lower()

                if seen_ids.has(normalized_id):
                    push_warning(
                        "[Unbound] Duplicate mod ID '%s' in %s; already provided by %s. Skipping it."
                        % [
                            mod_id,
                            file_name,
                            seen_ids[normalized_id]
                        ]
                    )
                else:
                    seen_ids[normalized_id] = file_name

                    manifest["archive_name"] = file_name
                    manifest["archive_path"] = archive_path
                    manifest["archive_type"] = archive_extension

                    installed_mods.append(manifest)

                    print(
                        "[Unbound] Valid mod: %s %s (%s)"
                        % [
                            manifest["name"],
                            manifest["version"],
                            archive_extension.to_upper()
                        ]
                    )

        file_name = directory.get_next()

    directory.list_dir_end()

    installed_mods.sort_custom(
        _sort_by_name
    )

    return installed_mods


func _read_manifest(
    archive_path: String,
    archive_extension: String
) -> Dictionary:
    match archive_extension:
        "zip":
            return _read_zip_manifest(
                archive_path
            )

        "pck":
            return _read_sidecar_manifest(
                archive_path
            )

    push_warning(
        "[Unbound] Unsupported archive type: %s"
        % archive_path.get_file()
    )

    return {}


func _read_zip_manifest(
    archive_path: String
) -> Dictionary:
    var zip_reader := ZIPReader.new()
    var open_error := zip_reader.open(
        archive_path
    )

    if open_error != OK:
        push_warning(
            "[Unbound] Could not open %s: %s"
            % [
                archive_path.get_file(),
                error_string(open_error)
            ]
        )
        return {}

    if not zip_reader.file_exists(MANIFEST_FILE):
        push_warning(
            "[Unbound] %s has no %s."
            % [
                archive_path.get_file(),
                MANIFEST_FILE
            ]
        )

        zip_reader.close()
        return {}

    var manifest_bytes := zip_reader.read_file(
        MANIFEST_FILE
    )

    zip_reader.close()

    if manifest_bytes.is_empty():
        push_warning(
            "[Unbound] %s contains an empty manifest."
            % archive_path.get_file()
        )
        return {}

    return _parse_manifest(
        manifest_bytes.get_string_from_utf8(),
        archive_path.get_file()
    )


func _read_sidecar_manifest(
    archive_path: String
) -> Dictionary:
    var manifest_path := (
        archive_path.get_basename()
        + ".json"
    )

    if not FileAccess.file_exists(manifest_path):
        push_warning(
            "[Unbound] %s has no matching sidecar manifest: %s"
            % [
                archive_path.get_file(),
                manifest_path.get_file()
            ]
        )
        return {}

    var manifest_file := FileAccess.open(
        manifest_path,
        FileAccess.READ
    )

    if manifest_file == null:
        push_warning(
            "[Unbound] Could not open %s: %s"
            % [
                manifest_path.get_file(),
                error_string(FileAccess.get_open_error())
            ]
        )
        return {}

    var manifest_text := manifest_file.get_as_text()

    manifest_file.close()

    return _parse_manifest(
        manifest_text,
        manifest_path.get_file()
    )


func _parse_manifest(
    manifest_text: String,
    source_name: String
) -> Dictionary:
    if manifest_text.strip_edges().is_empty():
        push_warning(
            "[Unbound] %s is empty."
            % source_name
        )
        return {}

    var json := JSON.new()
    var parse_error := json.parse(
        manifest_text
    )

    if parse_error != OK:
        push_warning(
            "[Unbound] Invalid JSON in %s at line %d: %s"
            % [
                source_name,
                json.get_error_line(),
                json.get_error_message()
            ]
        )
        return {}

    if typeof(json.data) != TYPE_DICTIONARY:
        push_warning(
            "[Unbound] %s must contain a JSON object."
            % source_name
        )
        return {}

    var manifest: Dictionary = json.data

    if not _validate_manifest(
        manifest,
        source_name
    ):
        return {}

    return manifest


func _validate_manifest(
    manifest: Dictionary,
    source_name: String
) -> bool:
    for field_name in REQUIRED_FIELDS:
        var field_value: Variant = manifest.get(
            field_name
        )

        if (
            typeof(field_value) != TYPE_STRING
            or str(field_value).strip_edges().is_empty()
        ):
            push_warning(
                "[Unbound] %s has an invalid or missing '%s' field."
                % [
                    source_name,
                    field_name
                ]
            )
            return false

    var mod_id := str(
        manifest["id"]
    ).strip_edges()

    if not _is_valid_mod_id(mod_id):
        push_warning(
            "[Unbound] %s has an unsafe mod ID: %s"
            % [
                source_name,
                mod_id
            ]
        )
        return false

    var mode := str(
        manifest.get(
            "mode",
            MODE_ENTRYPOINT
        )
    ).strip_edges().to_lower()

    if (
        mode != MODE_ENTRYPOINT
        and mode != MODE_PATCH
    ):
        push_warning(
            "[Unbound] %s has an unsupported mode: %s"
            % [
                source_name,
                mode
            ]
        )
        return false

    if mode == MODE_ENTRYPOINT:
        var entrypoint_value: Variant = manifest.get(
            "entrypoint"
        )

        if (
            typeof(entrypoint_value) != TYPE_STRING
            or str(entrypoint_value).strip_edges().is_empty()
        ):
            push_warning(
                "[Unbound] %s is missing its entrypoint."
                % source_name
            )
            return false

        var entrypoint := str(
            entrypoint_value
        ).strip_edges()

        var required_prefix := (
            "res://mods/%s/" % mod_id
        )

        if (
            not entrypoint.begins_with(required_prefix)
            or not entrypoint.ends_with(".gd")
            or entrypoint.contains("..")
            or entrypoint.contains("\\")
        ):
            push_warning(
                "[Unbound] %s has an unsafe entrypoint: %s"
                % [
                    source_name,
                    entrypoint
                ]
            )
            return false

        manifest["entrypoint"] = entrypoint

    manifest["id"] = mod_id
    manifest["mode"] = mode

    return true


func _is_valid_mod_id(mod_id: String) -> bool:
    if (
        mod_id.begins_with(".")
        or mod_id.ends_with(".")
        or mod_id.contains("..")
    ):
        return false

    for invalid_character in INVALID_ID_CHARACTERS:
        if mod_id.contains(invalid_character):
            return false

    return true


func _sort_by_name(
    first_mod: Dictionary,
    second_mod: Dictionary
) -> bool:
    return (
        str(first_mod["name"]).naturalnocasecmp_to(
            str(second_mod["name"])
        ) < 0
    )