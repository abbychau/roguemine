extends Node

# HighscoreManager - Global singleton for managing highscores
# Fully online-based system using REST API endpoints
# No local storage - all data comes from the backend server

const MAX_HIGHSCORES = 10  # Keep top 10 scores

# Backend configuration
const BACKEND_URL = "https://mine-api.12389012.xyz"
const ENCODING_SECRET = "roguemine-secret-key-2024-change-in-production"

# Online functionality (required)
var api_client: RogueMineAPIClient
var cached_highscores: Array[HighscoreEntry] = []  # Cache for display purposes only
var last_fetch_time: float = 0.0
var cache_duration: float = 60.0  # Cache for 60 seconds
var is_fetching: bool = false  # Prevent multiple simultaneous fetches

# Signals for operations
signal score_submitted(success: bool, data: Dictionary)
signal highscores_received(success: bool, scores: Array)
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
	# Initialize API client (required for all functionality)
	api_client = RogueMineAPIClient.new(BACKEND_URL, ENCODING_SECRET)
	api_client.setup_http_request(self)
	api_client.request_completed.connect(_on_api_request_completed)
	api_client.connection_error.connect(_on_api_connection_error)

	# Test connection on startup
	_test_backend_connection()

	# Don't fetch highscores here - let the menu fetch when needed

func add_highscore(player_name: String, final_score: int, game_time: float, tiles_revealed: int, chords_performed: int) -> void:
	"""Submit a new highscore to the online backend"""
	if not api_client:
		print("Error: API client not initialized")
		score_submitted.emit(false, {"error": "API client not available"})
		return

	print("Submitting score online: ", player_name, " - ", final_score)
	submit_score_online(player_name, final_score, game_time, tiles_revealed, chords_performed)

func get_highscores() -> Array[HighscoreEntry]:
	"""Get the current cached highscore list"""
	return cached_highscores

func fetch_highscores(limit: int = 10) -> void:
	"""Fetch highscores from the online backend"""
	if not api_client:
		print("Error: API client not initialized")
		highscores_received.emit(false, [])
		return

	# Prevent multiple simultaneous fetches
	if is_fetching:
		print("Already fetching highscores, skipping request")
		return

	# Check cache validity
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_fetch_time < cache_duration and cached_highscores.size() > 0:
		print("Using cached highscores")
		highscores_received.emit(true, cached_highscores)
		return

	print("Fetching highscores from server...")
	is_fetching = true
	fetch_online_highscores(limit)

func is_highscore(score: int) -> bool:
	"""Check if a score qualifies for the highscore list (based on cached data)"""
	if cached_highscores.size() < MAX_HIGHSCORES:
		return true
	return score > cached_highscores[MAX_HIGHSCORES - 1].score

# Local storage functions removed - using online-only approach

func clear_highscores():
	"""Clear cached highscores (for testing purposes)"""
	cached_highscores.clear()
	last_fetch_time = 0.0  # Force refresh on next fetch
	print("Cached highscores cleared")

# Online functionality methods

func submit_score_online(player_name: String, score: int, time_taken: float, tiles_revealed: int, chords_performed: int):
	"""Submit score to online backend"""
	if not api_client:
		print("API client not initialized")
		return

	print("MANAGER DEBUG: Starting score submission")
	print("MANAGER DEBUG: Data - Name:", player_name, "Score:", score, "Time:", time_taken, "Tiles:", tiles_revealed, "Chords:", chords_performed)
	print("MANAGER DEBUG: Using encoder secret:", ENCODING_SECRET)
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
			# Received highscores list - update cache
			_update_cache_from_server_data(data.highscores)
			highscores_received.emit(true, cached_highscores)
			print("Received ", data.highscores.size(), " online highscores")
			is_fetching = false  # Reset fetch flag
		elif data.has("rank"):
			# Score submission response
			score_submitted.emit(true, data)
			print("Score submitted successfully - Rank: ", data.rank)
			# Refresh highscores after successful submission (but don't create infinite loop)
			if not is_fetching:
				fetch_highscores()
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
			is_fetching = false  # Reset fetch flag on error
			highscores_received.emit(false, [])
		else:
			score_submitted.emit(false, data)

func _update_cache_from_server_data(server_highscores: Array):
	"""Update local cache from server data"""
	cached_highscores.clear()

	for score_data in server_highscores:
		var entry = HighscoreEntry.new(
			score_data.get("player_name", "Unknown"),
			score_data.get("score", 0),
			score_data.get("time_taken", 0.0),
			score_data.get("tiles_revealed", 0),
			score_data.get("chords_performed", 0)
		)
		entry.date_achieved = score_data.get("created_at", "Unknown")
		cached_highscores.append(entry)

	last_fetch_time = Time.get_ticks_msec() / 1000.0
	print("Updated cache with ", cached_highscores.size(), " entries")

func _on_api_connection_error(error_message: String):
	"""Handle API connection errors"""
	print("API connection error: ", error_message)
	connection_status_changed.emit(false)
	is_fetching = false  # Reset fetch flag on connection error

func is_backend_available() -> bool:
	"""Check if backend is available"""
	return api_client != null
