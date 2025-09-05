extends Control

# HighscoreMenu Script
# Displays the highscore ranking list with player names, scores, and statistics

@onready var title_label = $MainContainer/TitleContainer/Title
@onready var scroll_container = $MainContainer/ScrollContainer
@onready var highscore_list = $MainContainer/ScrollContainer/HighscoreList
@onready var back_button = $MainContainer/ButtonContainer/BackButton
@onready var no_scores_label = $MainContainer/NoScoresLabel
@onready var bgm_player = $BGMPlayer

func _ready():
	print("HighscoreMenu loaded")
	
	# Set up button connections
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	
	# Start entrance animations
	_animate_entrance()
	
	# Load and display highscores
	_populate_highscore_list()

func _animate_entrance():
	# Fade in animation similar to MainMenu
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.set_ease(Tween.EASE_OUT)

func _populate_highscore_list():
	# Clear existing entries
	for child in highscore_list.get_children():
		child.queue_free()
	
	var highscores = HighscoreManager.get_highscores()
	
	if highscores.is_empty():
		# Show "no scores" message
		if no_scores_label:
			no_scores_label.visible = true
		if scroll_container:
			scroll_container.visible = false
		return
	
	# Hide "no scores" message and show scroll container
	if no_scores_label:
		no_scores_label.visible = false
	if scroll_container:
		scroll_container.visible = true
	
	# Create highscore entries
	for i in range(highscores.size()):
		var entry = highscores[i]
		var rank = i + 1
		_create_highscore_entry(rank, entry)

func _create_highscore_entry(rank: int, entry):
	# Create a container for this highscore entry
	var entry_container = VBoxContainer.new()
	entry_container.add_theme_constant_override("separation", 5)
	
	# Create main info container (horizontal layout)
	var main_info = HBoxContainer.new()
	main_info.add_theme_constant_override("separation", 10)
	
	# Rank label
	var rank_label = Label.new()
	rank_label.text = str(rank) + "."
	rank_label.custom_minimum_size = Vector2(30, 0)
	rank_label.add_theme_font_size_override("font_size", 24)
	rank_label.add_theme_color_override("font_color", _get_rank_color(rank))
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_info.add_child(rank_label)
	
	# Player name and score container
	var name_score_container = VBoxContainer.new()
	name_score_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Player name
	var name_label = Label.new()
	name_label.text = entry.player_name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_score_container.add_child(name_label)
	
	# Score
	var score_label = Label.new()
	score_label.text = "Score: " + str(entry.score)
	score_label.add_theme_font_size_override("font_size", 18)
	score_label.add_theme_color_override("font_color", Color.YELLOW)
	name_score_container.add_child(score_label)
	
	main_info.add_child(name_score_container)
	
	# Date
	var date_label = Label.new()
	date_label.text = _format_date(entry.date_achieved)
	date_label.add_theme_font_size_override("font_size", 12)
	date_label.add_theme_color_override("font_color", Color.GRAY)
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	main_info.add_child(date_label)
	
	entry_container.add_child(main_info)
	
	# Create stats container (smaller text)
	var stats_container = HBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 15)
	
	# Time
	var time_label = Label.new()
	var minutes = int(entry.time_taken) / 60
	var seconds = int(entry.time_taken) % 60
	time_label.text = "Time: %02d:%02d" % [minutes, seconds]
	time_label.add_theme_font_size_override("font_size", 14)
	time_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	stats_container.add_child(time_label)
	
	# Tiles revealed
	var tiles_label = Label.new()
	tiles_label.text = "Tiles: " + str(entry.tiles_revealed)
	tiles_label.add_theme_font_size_override("font_size", 14)
	tiles_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	stats_container.add_child(tiles_label)
	
	# Chords performed
	var chords_label = Label.new()
	chords_label.text = "Chords: " + str(entry.chords_performed)
	chords_label.add_theme_font_size_override("font_size", 14)
	chords_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	stats_container.add_child(chords_label)
	
	entry_container.add_child(stats_container)
	
	# Add separator line
	var separator = HSeparator.new()
	separator.add_theme_color_override("separator", Color(0.3, 0.3, 0.3, 0.5))
	entry_container.add_child(separator)
	
	# Add spacing
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	entry_container.add_child(spacer)
	
	highscore_list.add_child(entry_container)

func _get_rank_color(rank: int) -> Color:
	match rank:
		1: return Color.GOLD
		2: return Color.SILVER
		3: return Color(0.8, 0.5, 0.2)  # Bronze
		_: return Color.WHITE

func _format_date(date_string: String) -> String:
	# Extract just the date part (YYYY-MM-DD) from the datetime string
	if date_string.length() >= 10:
		return date_string.substr(0, 10)
	return date_string

func _on_back_button_pressed():
	print("Back to main menu")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
