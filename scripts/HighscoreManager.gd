extends Node

# HighscoreManager - Global singleton for managing highscores
# Handles saving/loading highscore data and maintaining rankings
# Now supports both local storage and online backend synchronization

const SAVE_FILE_PATH = "user://highscores.save"
const MAX_HIGHSCORES = 10  # Keep top 10 scores

# Backend configuration
const BACKEND_URL = "https://mine-api.12389012.xyz"
const ENCODING_SECRET = "roguemine-secret-key-2024-change-in-production"

# Online functionality
var api_client: RogueMineAPIClient
var is_online_enabled: bool = true
var last_sync_attempt: float = 0.0
var sync_cooldown: float = 30.0  # 30 seconds between sync attempts

# Signals for online operations
signal online_score_submitted(success: bool, data: Dictionary)
signal online_scores_received(success: bool, scores: Array)
signal connection_status_changed(is_connected: bool)

# Highscore entry structure
class HighscoreEntry:
	var player_name: String
	var score: int
	var time_taken: float
	var tiles_revealed: int
	var chords_performed: int
	var date_achieved: String
	
	func _init(name: String, final_score: int, game_time: float, tiles: int, chords: int):
		player_name = name
		score = final_score
		time_taken = game_time
		tiles_revealed = tiles
		chords_performed = chords
		date_achieved = Time.get_datetime_string_from_system()

var highscores: Array[HighscoreEntry] = []

func _ready():
	# Initialize API client for online functionality
	if is_online_enabled:
		api_client = RogueMineAPIClient.new(BACKEND_URL, ENCODING_SECRET)
		api_client.setup_http_request(self)
		api_client.request_completed.connect(_on_api_request_completed)
		api_client.connection_error.connect(_on_api_connection_error)

		# Test connection on startup
		_test_backend_connection()

	load_highscores()

func add_highscore(player_name: String, final_score: int, game_time: float, tiles_revealed: int, chords_performed: int) -> int:
	"""Add a new highscore entry and return its rank (1-based), or 0 if not in top 10"""
	var new_entry = HighscoreEntry.new(player_name, final_score, game_time, tiles_revealed, chords_performed)

	# Find insertion position (scores are sorted in descending order)
	var insert_position = highscores.size()
	for i in range(highscores.size()):
		if final_score > highscores[i].score:
			insert_position = i
			break

	# Insert the new entry
	highscores.insert(insert_position, new_entry)

	# Keep only top MAX_HIGHSCORES entries
	if highscores.size() > MAX_HIGHSCORES:
		highscores = highscores.slice(0, MAX_HIGHSCORES)

	# Save the updated highscores locally
	save_highscores()

	# Submit to online backend if enabled
	if is_online_enabled and api_client:
		submit_score_online(player_name, final_score, game_time, tiles_revealed, chords_performed)

	# Return rank (1-based) or 0 if not in top 10
	if insert_position < MAX_HIGHSCORES:
		return insert_position + 1
	else:
		return 0

func get_highscores() -> Array[HighscoreEntry]:
	"""Get the current highscore list"""
	return highscores

func is_highscore(score: int) -> bool:
	"""Check if a score qualifies for the highscore list"""
	if highscores.size() < MAX_HIGHSCORES:
		return true
	return score > highscores[MAX_HIGHSCORES - 1].score

func save_highscores():
	"""Save highscores to file"""
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		print("Error: Could not open highscore file for writing")
		return
	
	var save_data = []
	for entry in highscores:
		save_data.append({
			"player_name": entry.player_name,
			"score": entry.score,
			"time_taken": entry.time_taken,
			"tiles_revealed": entry.tiles_revealed,
			"chords_performed": entry.chords_performed,
			"date_achieved": entry.date_achieved
		})
	
	file.store_string(JSON.stringify(save_data))
	file.close()
	print("Highscores saved successfully")

func load_highscores():
	"""Load highscores from file"""
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("No highscore file found, starting with empty list")
		return
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		print("Error: Could not open highscore file for reading")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("Error parsing highscore file")
		return
	
	var save_data = json.data
	highscores.clear()
	
	for entry_data in save_data:
		var entry = HighscoreEntry.new(
			entry_data.get("player_name", "Unknown"),
			entry_data.get("score", 0),
			entry_data.get("time_taken", 0.0),
			entry_data.get("tiles_revealed", 0),
			entry_data.get("chords_performed", 0)
		)
		entry.date_achieved = entry_data.get("date_achieved", "Unknown")
		highscores.append(entry)
	
	print("Loaded ", highscores.size(), " highscore entries")

func clear_highscores():
	"""Clear all highscores (for testing purposes)"""
	highscores.clear()
	save_highscores()
	print("All highscores cleared")

# Online functionality methods

func submit_score_online(player_name: String, score: int, time_taken: float, tiles_revealed: int, chords_performed: int):
	"""Submit score to online backend"""
	if not api_client:
		print("API client not initialized")
		return

	print("Submitting score online: ", player_name, " - ", score)
	api_client.submit_highscore(player_name, score, time_taken, tiles_revealed, chords_performed)

func fetch_online_highscores(limit: int = 10):
	"""Fetch highscores from online backend"""
	if not api_client:
		print("API client not initialized")
		return

	print("Fetching online highscores...")
	api_client.get_highscores(limit)

func _test_backend_connection():
	"""Test connection to backend server"""
	if not api_client:
		return

	print("Testing backend connection...")
	api_client.test_connection()

func _on_api_request_completed(success: bool, data: Dictionary):
	"""Handle API request completion"""
	print("API request completed - Success: ", success, " Data: ", data)

	if success:
		if data.has("highscores"):
			# Received highscores list
			online_scores_received.emit(true, data.highscores)
			print("Received ", data.highscores.size(), " online highscores")
		elif data.has("rank"):
			# Score submission response
			online_score_submitted.emit(true, data)
			print("Score submitted successfully - Rank: ", data.rank)
		elif data.has("status"):
			# Health check response
			connection_status_changed.emit(true)
			print("Backend connection successful")
	else:
		# Handle different types of failures
		if data.has("error"):
			print("API request failed: ", data.error)

		# Emit appropriate signals
		if data.has("highscores"):
			online_scores_received.emit(false, [])
		else:
			online_score_submitted.emit(false, data)

func _on_api_connection_error(error_message: String):
	"""Handle API connection errors"""
	print("API connection error: ", error_message)
	connection_status_changed.emit(false)

	# Could implement retry logic here
	last_sync_attempt = Time.get_ticks_msec() / 1000.0

func set_online_enabled(enabled: bool):
	"""Enable or disable online functionality"""
	is_online_enabled = enabled
	if not enabled and api_client:
		api_client.cleanup()
		api_client = null
	elif enabled and not api_client:
		api_client = RogueMineAPIClient.new(BACKEND_URL, ENCODING_SECRET)
		api_client.setup_http_request(self)
		api_client.request_completed.connect(_on_api_request_completed)
		api_client.connection_error.connect(_on_api_connection_error)

func is_backend_available() -> bool:
	"""Check if backend is available"""
	return api_client != null and is_online_enabled
