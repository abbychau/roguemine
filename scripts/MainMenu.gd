extends Control

# Main Menu Script for RogueMine
# Handles menu navigation and scene transitions

func _ready():
	# Ensure the main menu is properly configured for mobile
	print("Main Menu loaded - Mobile configuration active")
	
	# Make sure we don't accidentally quit on startup
	# No auto-input handling in _ready to avoid immediate closure

func _on_play_button_pressed():
	print("Play button pressed")
	# Change to minesweeper game scene
	get_tree().change_scene_to_file("res://scenes/Minesweeper.tscn")

func _on_options_button_pressed():
	print("Options button pressed")
	# TODO: Change to options scene when created
	# get_tree().change_scene_to_file("res://scenes/OptionsMenu.tscn")
	_show_message("plurk.com/abbychau")

func _on_quit_button_pressed():
	print("Quit button pressed")
	# On mobile, we typically don't quit but minimize
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		# On mobile, send to background instead of quitting
		get_tree().quit()
	else:
		# On desktop, actually quit
		get_tree().quit()

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
