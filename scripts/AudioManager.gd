extends Node

## AudioManager - Global singleton for managing audio settings
## Handles BGM and SE volume, mute states, and persistence

signal bgm_volume_changed(volume: float)
signal se_volume_changed(volume: float)
signal bgm_mute_changed(is_muted: bool)
signal se_mute_changed(is_muted: bool)

# Audio settings
var bgm_volume: float = 0.8
var se_volume: float = 0.8
var bgm_muted: bool = false
var se_muted: bool = false

# Audio buses
const BGM_BUS = "BGM"
const SE_BUS = "SFX"

# Save file path
const SETTINGS_FILE = "user://audio_settings.save"

func _ready():
	print("AudioManager initializing...")

	# Create audio buses if they don't exist
	_setup_audio_buses()

	# Load saved settings
	load_settings()

	# Apply initial settings
	_apply_audio_settings()

	print("AudioManager initialized. BGM volume: ", bgm_volume, ", SFX volume: ", se_volume)
	print("Available audio buses:")
	for i in range(AudioServer.get_bus_count()):
		print("  Bus ", i, ": ", AudioServer.get_bus_name(i))

func _setup_audio_buses():
	"""Setup audio buses for BGM and SFX"""
	var audio_server = AudioServer

	# Check if BGM bus exists, create if not
	var bgm_bus_index = audio_server.get_bus_index(BGM_BUS)
	if bgm_bus_index == -1:
		# Add bus at the end and rename it
		bgm_bus_index = audio_server.get_bus_count()
		audio_server.add_bus(bgm_bus_index)
		audio_server.set_bus_name(bgm_bus_index, BGM_BUS)
		print("Created BGM bus at index: ", bgm_bus_index)

	# Check if SFX bus exists, create if not
	var sfx_bus_index = audio_server.get_bus_index(SE_BUS)
	if sfx_bus_index == -1:
		# Add bus at the end and rename it
		sfx_bus_index = audio_server.get_bus_count()
		audio_server.add_bus(sfx_bus_index)
		audio_server.set_bus_name(sfx_bus_index, SE_BUS)
		print("Created SFX bus at index: ", sfx_bus_index)

func set_bgm_volume(volume: float):
	"""Set BGM volume (0.0 to 1.0)"""
	bgm_volume = clamp(volume, 0.0, 1.0)
	_apply_bgm_settings()
	bgm_volume_changed.emit(bgm_volume)
	save_settings()

func set_se_volume(volume: float):
	"""Set SE volume (0.0 to 1.0)"""
	se_volume = clamp(volume, 0.0, 1.0)
	_apply_se_settings()
	se_volume_changed.emit(se_volume)
	save_settings()

func set_bgm_muted(muted: bool):
	"""Set BGM mute state"""
	bgm_muted = muted
	_apply_bgm_settings()
	bgm_mute_changed.emit(bgm_muted)
	save_settings()

func set_se_muted(muted: bool):
	"""Set SE mute state"""
	se_muted = muted
	_apply_se_settings()
	se_mute_changed.emit(se_muted)
	save_settings()

func toggle_bgm_mute():
	"""Toggle BGM mute state"""
	set_bgm_muted(not bgm_muted)

func toggle_se_mute():
	"""Toggle SE mute state"""
	set_se_muted(not se_muted)

func _apply_audio_settings():
	"""Apply current audio settings to the audio server"""
	_apply_bgm_settings()
	_apply_se_settings()

func _apply_bgm_settings():
	"""Apply BGM volume and mute settings"""
	var bgm_bus_index = AudioServer.get_bus_index(BGM_BUS)
	if bgm_bus_index != -1:
		AudioServer.set_bus_mute(bgm_bus_index, bgm_muted)
		if not bgm_muted:
			# Convert linear volume to decibels
			var db_volume = linear_to_db(bgm_volume)
			AudioServer.set_bus_volume_db(bgm_bus_index, db_volume)
			print("BGM volume set to: ", bgm_volume, " (", db_volume, " dB) on bus index: ", bgm_bus_index)
		else:
			print("BGM muted (bus index: ", bgm_bus_index, ")")
	else:
		print("ERROR: BGM bus not found!")

	# Also apply directly to players not on the BGM bus (group-based fallback)
	_apply_settings_to_players(BGM_BUS, bgm_muted, bgm_volume)

func _apply_se_settings():
	"""Apply SE volume and mute settings"""
	var se_bus_index = AudioServer.get_bus_index(SE_BUS)
	if se_bus_index != -1:
		AudioServer.set_bus_mute(se_bus_index, se_muted)
		if not se_muted:
			# Convert linear volume to decibels
			var db_volume = linear_to_db(se_volume)
			AudioServer.set_bus_volume_db(se_bus_index, db_volume)
			print("SFX volume set to: ", se_volume, " (", db_volume, " dB) on bus index: ", se_bus_index)
		else:
			print("SFX muted (bus index: ", se_bus_index, ")")
	else:
		print("ERROR: SFX bus not found!")

	# Also apply directly to players not on the SFX bus (group-based fallback)
	_apply_settings_to_players(SE_BUS, se_muted, se_volume)

func _apply_settings_to_players(bus_name: String, is_muted: bool, volume_linear: float):
	"""Find all AudioStreamPlayers on a given bus and apply volume/mute directly.

	Preserves each player's base volume_db by storing it in metadata on first touch.
	"""
	var root = get_tree().get_root()
	if root == null:
		return

	for node in _iter_audio_players(root):
		# If node is already on the intended bus, the bus volume handles it
		if node.bus == bus_name:
			continue
		# Otherwise, if the node is tagged in the corresponding group, apply directly
		if node.is_in_group(bus_name):
			# Preserve base volume on first modification
			if not node.has_meta("_base_volume_db"):
				node.set_meta("_base_volume_db", node.volume_db)
			var base_db: float = float(node.get_meta("_base_volume_db"))
			if is_muted:
				node.volume_db = -80.0
			else:
				var adj_db = linear_to_db(clamp(volume_linear, 0.0, 1.0))
				node.volume_db = base_db + adj_db

func _iter_audio_players(start: Node) -> Array:
	"""Depth-first iterate all AudioStreamPlayer nodes under start."""
	var results: Array = []
	var stack: Array = [start]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		if n is AudioStreamPlayer:
			results.append(n)
		for child in n.get_children():
			stack.append(child)
	return results

func save_settings():
	"""Save audio settings to file"""
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file == null:
		print("Error: Could not save audio settings")
		return
	
	var settings_data = {
		"bgm_volume": bgm_volume,
		"se_volume": se_volume,
		"bgm_muted": bgm_muted,
		"se_muted": se_muted
	}
	
	var json_string = JSON.stringify(settings_data)
	file.store_string(json_string)
	file.close()
	print("Audio settings saved")

func load_settings():
	"""Load audio settings from file"""
	if not FileAccess.file_exists(SETTINGS_FILE):
		print("No audio settings file found, using defaults")
		return
	
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	if file == null:
		print("Error: Could not load audio settings")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("Error parsing audio settings file")
		return
	
	var settings_data = json.data
	bgm_volume = settings_data.get("bgm_volume", 0.8)
	se_volume = settings_data.get("se_volume", 0.8)
	bgm_muted = settings_data.get("bgm_muted", false)
	se_muted = settings_data.get("se_muted", false)
	
	print("Audio settings loaded")

func get_bgm_volume() -> float:
	return bgm_volume

func get_se_volume() -> float:
	return se_volume

func is_bgm_muted() -> bool:
	return bgm_muted

func is_se_muted() -> bool:
	return se_muted
