extends Control

# Game Scene Script for RogueMine
# Handles main gameplay logic

var score = 0

func _ready():
	print("Game Scene loaded")
	update_score_display()

func _on_back_button_pressed():
	print("Back to main menu")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_game_area_gui_input(event):
	if event is InputEventScreenTouch and event.pressed:
		# Handle touch input
		_handle_touch(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Handle mouse input (for testing in editor)
		_handle_touch(event.position)

func _handle_touch(position: Vector2):
	print("Touch detected at: ", position)
	# Simple demo: increase score on tap
	score += 10
	update_score_display()
	
	# Create a simple visual feedback
	_create_tap_effect(position)

func update_score_display():
	var score_label = $UI/TopPanel/ScoreLabel
	if score_label:
		score_label.text = "Score: " + str(score)

func _create_tap_effect(position: Vector2):
	# Create a simple visual effect at tap position
	var effect_label = Label.new()
	effect_label.text = "+10"
	effect_label.position = position - Vector2(20, 20)
	effect_label.modulate = Color.YELLOW
	$GameArea.add_child(effect_label)
	
	# Animate the effect
	var tween = create_tween()
	tween.parallel().tween_property(effect_label, "position:y", position.y - 100, 1.0)
	tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 1.0)
	
	# Remove the effect after animation
	await tween.finished
	if effect_label and is_instance_valid(effect_label):
		effect_label.queue_free()

# Handle mobile back button
func _input(event):
	# Only handle back button on mobile platforms, or allow Escape key on desktop for navigation
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
