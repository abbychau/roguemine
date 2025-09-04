extends Control

# Main Menu Script for RogueMine
# Handles menu navigation and scene transitions

@onready var title_container = $MainContainer/TitleContainer
@onready var button_container = $MainContainer/ButtonContainer
@onready var play_button = $MainContainer/ButtonContainer/PlayButton
@onready var options_button = $MainContainer/ButtonContainer/OptionsButton
@onready var quit_button = $MainContainer/ButtonContainer/QuitButton
@onready var bgm_player = $BGMPlayer

func _ready():
	# Ensure the main menu is properly configured for mobile
	print("Main Menu loaded - Mobile configuration active")

	# Start entrance animations
	_animate_entrance()

	# Set up button hover effects
	_setup_button_effects()

func _on_play_button_pressed():
	print("Play button pressed")
	_animate_button_press(play_button)
	await get_tree().create_timer(0.1).timeout
	# Change to minesweeper game scene
	get_tree().change_scene_to_file("res://scenes/Minesweeper.tscn")

func _on_options_button_pressed():
	print("Options button pressed")
	_animate_button_press(options_button)
	await get_tree().create_timer(0.1).timeout
	# TODO: Change to options scene when created
	# get_tree().change_scene_to_file("res://scenes/OptionsMenu.tscn")
	_show_message("plurk.com/abbychau")

func _on_quit_button_pressed():
	print("Quit button pressed")
	_animate_button_press(quit_button)
	await get_tree().create_timer(0.1).timeout
	# On mobile, we typically don't quit but minimize
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		# On mobile, send to background instead of quitting
		get_tree().quit()
	else:
		# On desktop, actually quit
		get_tree().quit()

func _animate_button_press(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.05)

func _animate_entrance():
	# Start with elements invisible/scaled down
	title_container.modulate.a = 0.0
	title_container.scale = Vector2(0.8, 0.8)
	button_container.modulate.a = 0.0
	button_container.position.y += 50

	# Animate title entrance
	var title_tween = create_tween()
	title_tween.set_parallel(true)
	title_tween.tween_property(title_container, "modulate:a", 1.0, 0.8)
	title_tween.tween_property(title_container, "scale", Vector2(1.0, 1.0), 0.8)
	title_tween.set_ease(Tween.EASE_OUT)
	title_tween.set_trans(Tween.TRANS_BACK)

	# Animate buttons entrance with delay
	await get_tree().create_timer(0.3).timeout
	var button_tween = create_tween()
	button_tween.set_parallel(true)
	button_tween.tween_property(button_container, "modulate:a", 1.0, 0.6)
	button_tween.tween_property(button_container, "position:y", button_container.position.y - 50, 0.6)
	button_tween.set_ease(Tween.EASE_OUT)
	button_tween.set_trans(Tween.TRANS_CUBIC)

func _setup_button_effects():
	# Add subtle scale effects on hover
	for button in [play_button, options_button, quit_button]:
		if button:
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_button_hover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	tween.set_ease(Tween.EASE_OUT)

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
	tween.set_ease(Tween.EASE_OUT)

func _show_message(message: String):
	# Simple feedback for placeholder functions
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()

	# Auto-close after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if dialog and is_instance_valid(dialog):
		dialog.queue_free()
