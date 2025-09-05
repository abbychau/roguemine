extends Node

# HighscoreManager - Global singleton for managing highscores
# Handles saving/loading highscore data and maintaining rankings

const SAVE_FILE_PATH = "user://highscores.save"
const MAX_HIGHSCORES = 10  # Keep top 10 scores

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
	
	# Save the updated highscores
	save_highscores()
	
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
