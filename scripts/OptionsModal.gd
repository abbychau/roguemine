extends ColorRect
class_name OptionsModal

## Options Modal - Audio settings dialog
## Provides UI for adjusting BGM and SE volume and mute settings

signal options_closed

# UI References
@onready var bgm_volume_slider: HSlider
@onready var se_volume_slider: HSlider
@onready var bgm_mute_button: CheckBox
@onready var se_mute_button: CheckBox
@onready var bgm_volume_label: Label
@onready var se_volume_label: Label
@onready var close_button: Button
@onready var background_panel: Panel

# Animation
var tween: Tween

func _ready():
	# Make the modal fill the entire screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Add semi-transparent background
	color = Color(0, 0, 0, 0.5)  # Semi-transparent black overlay

	# Get UI references
	_setup_ui_references()

	# Connect signals
	_connect_signals()

	# Load current settings
	_load_current_settings()

	# Ensure consistent font sizes across scenes regardless of parent theme
	_apply_theme_overrides()

	# Setup initial state
	modulate.a = 0.0
	if background_panel:
		background_panel.scale = Vector2(0.8, 0.8)

	# Animate in
	_animate_in()

func _setup_ui_references():
	"""Setup references to UI elements"""
	# Try to find UI elements
	bgm_volume_slider = get_node_or_null("Panel/VBox/BGMContainer/BGMVolumeSlider")
	se_volume_slider = get_node_or_null("Panel/VBox/SEContainer/SEVolumeSlider")
	bgm_mute_button = get_node_or_null("Panel/VBox/BGMContainer/BGMMuteButton")
	se_mute_button = get_node_or_null("Panel/VBox/SEContainer/SEMuteButton")
	bgm_volume_label = get_node_or_null("Panel/VBox/BGMContainer/BGMVolumeLabel")
	se_volume_label = get_node_or_null("Panel/VBox/SEContainer/SEVolumeLabel")
	close_button = get_node_or_null("Panel/VBox/CloseButton")
	background_panel = get_node_or_null("Panel")
	
	# Create UI elements if they don't exist
	if not background_panel:
		_create_ui()

func _create_ui():
	"""Create the UI elements programmatically"""
	# Main panel - centered in the modal
	background_panel = Panel.new()
	background_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	background_panel.size = Vector2(400, 300)
	background_panel.position = Vector2(-200, -150)  # Center it properly
	add_child(background_panel)
	
	# Main container
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 20)
	background_panel.add_child(main_vbox)
	
	# Title
	var title_label = Label.new()
	title_label.text = "Audio Options"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	main_vbox.add_child(title_label)
	
	# BGM Container
	var bgm_container = VBoxContainer.new()
	bgm_container.name = "BGMContainer"
	main_vbox.add_child(bgm_container)
	
	var bgm_title = Label.new()
	bgm_title.text = "Background Music"
	bgm_title.add_theme_font_size_override("font_size", 18)
	bgm_container.add_child(bgm_title)
	
	var bgm_hbox = HBoxContainer.new()
	bgm_container.add_child(bgm_hbox)
	
	bgm_volume_label = Label.new()
	bgm_volume_label.name = "BGMVolumeLabel"
	bgm_volume_label.text = "Volume: 80%"
	bgm_volume_label.custom_minimum_size.x = 100
	bgm_hbox.add_child(bgm_volume_label)
	
	bgm_volume_slider = HSlider.new()
	bgm_volume_slider.name = "BGMVolumeSlider"
	bgm_volume_slider.min_value = 0.0
	bgm_volume_slider.max_value = 1.0
	bgm_volume_slider.step = 0.01
	bgm_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bgm_hbox.add_child(bgm_volume_slider)
	
	bgm_mute_button = CheckBox.new()
	bgm_mute_button.name = "BGMMuteButton"
	bgm_mute_button.text = "Mute"
	bgm_mute_button.add_theme_font_size_override("font_size", 28)
	bgm_hbox.add_child(bgm_mute_button)
	
	# SE Container
	var se_container = VBoxContainer.new()
	se_container.name = "SEContainer"
	main_vbox.add_child(se_container)
	
	var se_title = Label.new()
	se_title.text = "Sound Effects"
	se_title.add_theme_font_size_override("font_size", 18)
	se_container.add_child(se_title)
	
	var se_hbox = HBoxContainer.new()
	se_container.add_child(se_hbox)
	
	se_volume_label = Label.new()
	se_volume_label.name = "SEVolumeLabel"
	se_volume_label.text = "Volume: 80%"
	se_volume_label.custom_minimum_size.x = 100
	se_hbox.add_child(se_volume_label)
	
	se_volume_slider = HSlider.new()
	se_volume_slider.name = "SEVolumeSlider"
	se_volume_slider.min_value = 0.0
	se_volume_slider.max_value = 1.0
	se_volume_slider.step = 0.01
	se_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	se_hbox.add_child(se_volume_slider)
	
	se_mute_button = CheckBox.new()
	se_mute_button.name = "SEMuteButton"
	se_mute_button.text = "Mute"
	se_mute_button.add_theme_font_size_override("font_size", 28)
	se_hbox.add_child(se_mute_button)
	
	# Close button
	close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "Close"
	close_button.add_theme_font_size_override("font_size", 28)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(close_button)

func _apply_theme_overrides():
	"""Apply consistent font sizes for modal controls regardless of scene theme."""
	var button_font_size := 28
	if bgm_mute_button:
		bgm_mute_button.add_theme_font_size_override("font_size", button_font_size)
	if se_mute_button:
		se_mute_button.add_theme_font_size_override("font_size", button_font_size)
	if close_button:
		close_button.add_theme_font_size_override("font_size", button_font_size)

func _connect_signals():
	"""Connect UI signals"""
	# Listen to AudioManager changes to keep UI in sync
	if Engine.has_singleton("AudioManager") or get_node_or_null("/root/AudioManager"):
		AudioManager.bgm_volume_changed.connect(_on_bgm_volume_signal)
		AudioManager.se_volume_changed.connect(_on_se_volume_signal)
		AudioManager.bgm_mute_changed.connect(_on_bgm_mute_signal)
		AudioManager.se_mute_changed.connect(_on_se_mute_signal)
	if bgm_volume_slider:
		bgm_volume_slider.value_changed.connect(_on_bgm_volume_changed)
	if se_volume_slider:
		se_volume_slider.value_changed.connect(_on_se_volume_changed)
	if bgm_mute_button:
		bgm_mute_button.toggled.connect(_on_bgm_mute_toggled)
	if se_mute_button:
		se_mute_button.toggled.connect(_on_se_mute_toggled)
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

func _on_bgm_volume_signal(value: float):
	if bgm_volume_slider and not is_queued_for_deletion():
		bgm_volume_slider.value = value
		_update_volume_labels()

func _on_se_volume_signal(value: float):
	if se_volume_slider and not is_queued_for_deletion():
		se_volume_slider.value = value
		_update_volume_labels()

func _on_bgm_mute_signal(is_muted: bool):
	if bgm_mute_button and not is_queued_for_deletion():
		bgm_mute_button.button_pressed = is_muted

func _on_se_mute_signal(is_muted: bool):
	if se_mute_button and not is_queued_for_deletion():
		se_mute_button.button_pressed = is_muted

func _load_current_settings():
	"""Load current audio settings into UI"""
	# Check if AudioManager exists (autoload)
	var audio_manager = get_node_or_null("/root/AudioManager")

	if bgm_volume_slider:
		bgm_volume_slider.value = audio_manager.get_bgm_volume() if audio_manager else 0.8
	if se_volume_slider:
		se_volume_slider.value = audio_manager.get_se_volume() if audio_manager else 0.8
	if bgm_mute_button:
		bgm_mute_button.button_pressed = audio_manager.is_bgm_muted() if audio_manager else false
	if se_mute_button:
		se_mute_button.button_pressed = audio_manager.is_se_muted() if audio_manager else false

	_update_volume_labels()

func _update_volume_labels():
	"""Update volume percentage labels"""
	if bgm_volume_label and bgm_volume_slider:
		var percentage = int(bgm_volume_slider.value * 100)
		bgm_volume_label.text = "Volume: %d%%" % percentage
	
	if se_volume_label and se_volume_slider:
		var percentage = int(se_volume_slider.value * 100)
		se_volume_label.text = "Volume: %d%%" % percentage

func _animate_in():
	"""Animate the modal appearing"""
	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	if background_panel:
		tween.tween_property(background_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animate_out():
	"""Animate the modal disappearing"""
	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	if background_panel:
		tween.tween_property(background_panel, "scale", Vector2(0.8, 0.8), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	await tween.finished
	queue_free()

func _on_bgm_volume_changed(value: float):
	"""Handle BGM volume slider change"""
	print("BGM volume slider changed to: ", value)
	AudioManager.set_bgm_volume(value)
	_update_volume_labels()

func _on_se_volume_changed(value: float):
	"""Handle SE volume slider change"""
	print("SFX volume slider changed to: ", value)
	AudioManager.set_se_volume(value)
	_update_volume_labels()

func _on_bgm_mute_toggled(pressed: bool):
	"""Handle BGM mute button toggle"""
	AudioManager.set_bgm_muted(pressed)

func _on_se_mute_toggled(pressed: bool):
	"""Handle SE mute button toggle"""
	AudioManager.set_se_muted(pressed)

func _on_close_button_pressed():
	"""Handle close button press"""
	close_options()

func close_options():
	"""Close the options modal"""
	options_closed.emit()
	_animate_out()

func _input(event):
	"""Handle input events"""
	if event.is_action_pressed("ui_cancel"):  # ESC key
		close_options()
		get_viewport().set_input_as_handled()
