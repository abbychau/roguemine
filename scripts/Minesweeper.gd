extends Control

# Minesweeper Game Script
# Creates a large minefield that can be viewed through a 15x15 viewport
# Player can swipe to move around the larger field

# Grid settings
const VIEWPORT_SIZE = 15  # 15x15 visible area
const FIELD_SIZE = 500     # 50x50 total minefield (can be made larger)
const CELL_SIZE = 26      # Size of each cell in pixels (smaller for coordinates)
const MINE_COUNT = FIELD_SIZE * FIELD_SIZE / 10.0  # 10% of the field size
const COORD_SIZE = 20     # Size of coordinate labels

# Minimap settings
const MINIMAP_SIZE = 200  # Size of the minimap in pixels
const MINIMAP_CELL_SIZE = float(MINIMAP_SIZE) / float(FIELD_SIZE)  # Each cell size in minimap

# Game state
var minefield = []        # 2D array of mine data
var revealed = []         # 2D array of revealed cells
var flagged = []          # 2D array of flagged cells
var cell_buttons = []     # 2D array of button references
var flag_mode = false     # Toggle for flag placement mode

# Upgrade system
var flood_radius = 5      # Variable flood radius (can be upgraded)
var coins = 0.0           # Player's coins (now float for multiplier efficiency)
var flood_upgrade_cost = 10  # Cost to upgrade flood radius
var flood_upgrade_level = 1  # Current upgrade level

# New upgrade systems
var coin_multiplier = 1.0  # Coins per reveal multiplier (starts at 1.0)
var coin_multiplier_upgrade_cost = 15  # Cost to upgrade coin multiplier
var coin_multiplier_upgrade_level = 1  # Current coin multiplier upgrade level

var chord_bonus = 0  # Bonus coins per chord play (starts at 0)
var chord_bonus_upgrade_cost = 20  # Cost to upgrade chord bonus
var chord_bonus_upgrade_level = 1  # Current chord bonus upgrade level

# End game bonus system
var end_game_bonus = 100  # Bonus score for ending game early (starts at 100)
var end_game_bonus_upgrade_cost = 30  # Cost to upgrade end game bonus
var end_game_bonus_upgrade_level = 1  # Current end game bonus upgrade level

# Score system
var score = 0  # Player's total score
var tiles_revealed = 0  # Total tiles revealed this game
var chords_performed = 0  # Number of successful chord plays
var game_start_time = 0.0  # When the game started
var game_time = 0.0  # Current game time
var game_over = false  # Is the game over?
var is_timing = false  # Is the timer running?

# Camera/viewport position
var camera_x = 0
var camera_y = 0

# Touch/swipe handling
var is_dragging = false
var drag_start_pos = Vector2.ZERO
var last_camera_pos = Vector2.ZERO
var last_touch_time = 0.0
var touch_threshold = 0.3  # Time threshold for distinguishing tap vs drag

# Double-click detection for chord feature
var last_click_time = 0.0
var last_clicked_cell = Vector2(-1, -1)
var double_click_threshold = 0.5  # Time window for double-click

# Mouse button state tracking for left+right chord
var left_button_pressed = false
var right_button_pressed = false
var current_chord_cell = Vector2(-1, -1)  # Track which cell is being chorded

# UI references
var grid_container
var info_label
var flag_mode_button
var x_coord_labels = []   # Array of X coordinate labels
var y_coord_labels = []   # Array of Y coordinate labels
var coord_container       # Container for coordinates and grid

# Upgrade panel UI references
var upgrade_panel
var coins_label
var flood_upgrade_button
var flood_level_label
var coin_multiplier_upgrade_button
var coin_multiplier_level_label
var chord_bonus_upgrade_button
var chord_bonus_level_label
var end_game_bonus_upgrade_button
var end_game_bonus_level_label

# Game over UI references
var game_over_panel
var game_over_title
var final_score_label
var stats_label
var restart_button
var menu_button

# Time and end game UI references
var time_label
var end_game_button

# Minimap UI references
var minimap_panel
var minimap_container
var minimap_texture_rect
var minimap_viewport_rect
var minimap_image
var minimap_texture
var minimap_is_dragging = false

func _ready():
	print("Minesweeper loaded")
	grid_container = $GameArea/GridContainer/MineGrid
	coord_container = $GameArea/GridContainer
	
	# Initialize UI elements - no longer using TopPanel
	info_label = get_node_or_null("UI/InfoLabel")  # Now at bottom
	flag_mode_button = get_node_or_null("UI/FlagModeButton")  # Direct reference
	var back_button = get_node_or_null("UI/BackButton")  # Direct reference
	time_label = get_node_or_null("UI/TimeLabel")  # Time display
	end_game_button = get_node_or_null("UI/EndGameButton")  # End game button
	
	# Connect button signals if they exist
	if end_game_button:
		end_game_button.pressed.connect(_on_end_game_button_pressed)
	
	# Initialize upgrade panel UI
	upgrade_panel = $UI/UpgradePanel
	coins_label = $UI/UpgradePanel/CoinsLabel
	flood_upgrade_button = $UI/UpgradePanel/FloodUpgradeButton
	flood_level_label = $UI/UpgradePanel/FloodLevelLabel
	
	# Initialize new upgrade UI elements (will be null until we add them to scene)
	coin_multiplier_upgrade_button = get_node_or_null("UI/UpgradePanel/CoinMultiplierUpgradeButton")
	coin_multiplier_level_label = get_node_or_null("UI/UpgradePanel/CoinMultiplierLevelLabel")
	chord_bonus_upgrade_button = get_node_or_null("UI/UpgradePanel/ChordBonusUpgradeButton")
	chord_bonus_level_label = get_node_or_null("UI/UpgradePanel/ChordBonusLevelLabel")
	end_game_bonus_upgrade_button = get_node_or_null("UI/UpgradePanel/EndGameBonusUpgradeButton")
	end_game_bonus_level_label = get_node_or_null("UI/UpgradePanel/EndGameBonusLevelLabel")
	
	# Connect upgrade button signals
	if end_game_bonus_upgrade_button:
		end_game_bonus_upgrade_button.pressed.connect(_on_end_game_bonus_upgrade_button_pressed)
	
	# Initialize game over UI (will be null until we add them to scene)
	game_over_panel = get_node_or_null("UI/GameOverPanel")
	game_over_title = get_node_or_null("UI/GameOverPanel/GameOverTitle")
	final_score_label = get_node_or_null("UI/GameOverPanel/FinalScoreLabel")
	stats_label = get_node_or_null("UI/GameOverPanel/StatsLabel")
	restart_button = get_node_or_null("UI/GameOverPanel/RestartButton")
	menu_button = get_node_or_null("UI/GameOverPanel/MenuButton")
	
	print("UI nodes initialized:")  # Debug
	print("  upgrade_panel: ", upgrade_panel)
	print("  coins_label: ", coins_label)
	print("  flood_upgrade_button: ", flood_upgrade_button)
	print("  flood_level_label: ", flood_level_label)
	print("  coin_multiplier_upgrade_button: ", coin_multiplier_upgrade_button)
	print("  chord_bonus_upgrade_button: ", chord_bonus_upgrade_button)
	print("  game_over_panel: ", game_over_panel)
	
	# Set up the main container size
	var total_size = VIEWPORT_SIZE * CELL_SIZE + COORD_SIZE
	coord_container.size = Vector2(total_size, total_size)
	
	# Initialize the game
	_initialize_minefield()
	_create_coordinate_labels()
	_create_visible_grid()
	
	# Initialize minimap UI (after minefield is created)
	_create_minimap()
	
	# Center the camera in the middle of the field
	camera_x = int((FIELD_SIZE - VIEWPORT_SIZE) / 2)
	camera_y = int((FIELD_SIZE - VIEWPORT_SIZE) / 2)
	
	_update_camera_position()
	_update_info_display()
	_update_flag_mode_button()
	_update_upgrade_ui()
	_update_time_display()
	_update_minimap()
	
	# Start the game timer
	game_start_time = Time.get_ticks_msec() / 1000.0
	is_timing = true

func _process(_delta):
	# Update game time and display if timer is running
	if is_timing and not game_over:
		game_time = Time.get_ticks_msec() / 1000.0 - game_start_time
		_update_time_display()

func _input(event: InputEvent):
	# Global input handler to reset mouse button states when released anywhere
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			left_button_pressed = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			right_button_pressed = false

func _initialize_minefield():
	# Create empty minefield
	minefield = []
	revealed = []
	flagged = []
	
	for x in range(FIELD_SIZE):
		minefield.append([])
		revealed.append([])
		flagged.append([])
		for y in range(FIELD_SIZE):
			minefield[x].append(0)  # 0 = no mine, 1 = mine
			revealed[x].append(false)
			flagged[x].append(false)
	
	# Place mines randomly
	var mines_placed = 0
	while mines_placed < MINE_COUNT:
		var x = randi() % FIELD_SIZE
		var y = randi() % FIELD_SIZE
		
		if minefield[x][y] == 0:  # Don't place mine on existing mine
			minefield[x][y] = 1
			mines_placed += 1
	
	print("Minefield initialized: ", FIELD_SIZE, "x", FIELD_SIZE, " with ", MINE_COUNT, " mines")

func _create_coordinate_labels():
	# Clear existing coordinate labels
	for label in x_coord_labels:
		if label:
			label.queue_free()
	for label in y_coord_labels:
		if label:
			label.queue_free()
	
	x_coord_labels.clear()
	y_coord_labels.clear()
	
	# Create X coordinate labels (top row)
	for x in range(VIEWPORT_SIZE):
		var label = Label.new()
		label.text = str(camera_x + x)
		label.size = Vector2(CELL_SIZE, COORD_SIZE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.position = Vector2(COORD_SIZE + x * CELL_SIZE, 0)
		coord_container.add_child(label)
		x_coord_labels.append(label)
	
	# Create Y coordinate labels (left column)  
	for y in range(VIEWPORT_SIZE):
		var label = Label.new()
		label.text = str(camera_y + y)
		label.size = Vector2(COORD_SIZE, CELL_SIZE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.position = Vector2(0, COORD_SIZE + y * CELL_SIZE)
		coord_container.add_child(label)
		y_coord_labels.append(label)

func _create_visible_grid():
	# Clear existing grid
	for child in grid_container.get_children():
		child.queue_free()
	
	cell_buttons = []
	
	# Set fixed grid container size and position
	var total_grid_size = VIEWPORT_SIZE * CELL_SIZE
	grid_container.size = Vector2(total_grid_size, total_grid_size)
	grid_container.position = Vector2(COORD_SIZE, COORD_SIZE)
	
	# Create 15x15 grid of buttons for the viewport
	for y in range(VIEWPORT_SIZE):
		cell_buttons.append([])
		for x in range(VIEWPORT_SIZE):
			var button = Button.new()
			button.size = Vector2(CELL_SIZE, CELL_SIZE)
			button.position = Vector2(x * CELL_SIZE, y * CELL_SIZE)
			button.text = ""
			button.flat = false
			
			# Store grid position in the button
			button.set_meta("grid_x", x)
			button.set_meta("grid_y", y)
			
			# Connect signals
			button.pressed.connect(_on_cell_pressed.bind(x, y))
			button.gui_input.connect(_on_cell_input.bind(x, y))
			
			grid_container.add_child(button)
			cell_buttons[y].append(button)
	
	print("Grid created with fixed positioning")

func _update_camera_position():
	# Clamp camera position to valid bounds
	camera_x = int(clamp(camera_x, 0, FIELD_SIZE - VIEWPORT_SIZE))
	camera_y = int(clamp(camera_y, 0, FIELD_SIZE - VIEWPORT_SIZE))
	
	# Update coordinate labels
	_update_coordinate_labels()
	
	# Update all visible buttons to show correct field data
	for y in range(VIEWPORT_SIZE):
		for x in range(VIEWPORT_SIZE):
			var field_x = camera_x + x
			var field_y = camera_y + y
			var button = cell_buttons[y][x]
			
			_update_cell_display(button, field_x, field_y)
	
	# Update minimap viewport indicator position
	if minimap_viewport_rect:
		var viewport_pos_on_minimap = Vector2(
			camera_x * MINIMAP_CELL_SIZE,
			camera_y * MINIMAP_CELL_SIZE
		)
		minimap_viewport_rect.position = viewport_pos_on_minimap

func _update_coordinate_labels():
	# Update X coordinate labels (top row)
	for x in range(VIEWPORT_SIZE):
		if x < x_coord_labels.size():
			x_coord_labels[x].text = str(camera_x + x)
	
	# Update Y coordinate labels (left column)
	for y in range(VIEWPORT_SIZE):
		if y < y_coord_labels.size():
			y_coord_labels[y].text = str(camera_y + y)

func _update_cell_display(button: Button, field_x: int, field_y: int):
	if field_x >= FIELD_SIZE or field_y >= FIELD_SIZE or field_x < 0 or field_y < 0:
		button.text = ""
		button.disabled = true
		button.modulate = Color.GRAY
		return
	
	button.disabled = false
	button.modulate = Color.WHITE
	
	if flagged[field_x][field_y]:
		button.text = "🚩"
		button.modulate = Color.YELLOW
	elif revealed[field_x][field_y]:
		if minefield[field_x][field_y] == 1:
			button.text = "💣"
			button.modulate = Color.RED
		else:
			var adjacent_mines = _count_adjacent_mines(field_x, field_y)
			button.text = str(adjacent_mines) if adjacent_mines > 0 else ""
			button.modulate = Color.LIGHT_GRAY
			button.flat = true
	else:
		button.text = ""
		button.modulate = Color.WHITE
		button.flat = false

func _count_adjacent_mines(x: int, y: int) -> int:
	var count = 0
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = x + dx
			var ny = y + dy
			if nx >= 0 and nx < FIELD_SIZE and ny >= 0 and ny < FIELD_SIZE:
				if minefield[nx][ny] == 1:
					count += 1
	return count

func _count_adjacent_flags(x: int, y: int) -> int:
	var count = 0
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = x + dx
			var ny = y + dy
			if nx >= 0 and nx < FIELD_SIZE and ny >= 0 and ny < FIELD_SIZE:
				if flagged[nx][ny]:
					count += 1
	return count

func _chord_reveal(x: int, y: int):
	# Reveal all unflagged adjacent cells (chord/middle-click functionality)
	var cells_revealed_by_chord = 0
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = x + dx
			var ny = y + dy
			if nx >= 0 and nx < FIELD_SIZE and ny >= 0 and ny < FIELD_SIZE:
				if not flagged[nx][ny] and not revealed[nx][ny]:
					_reveal_cell(nx, ny)
					cells_revealed_by_chord += 1
	
	# Award chord bonus if any cells were revealed
	if cells_revealed_by_chord > 0:
		chords_performed += 1  # Track successful chords for score
		if chord_bonus > 0:
			var bonus_coins = float(chord_bonus)  # Convert to float
			coins += bonus_coins
			score += int(bonus_coins * 15)  # 15 points per chord bonus coin
			print("Chord bonus awarded: +", bonus_coins, " coins!")
			# Show floating chord bonus text
			_show_floating_chord_bonus_text(x, y, bonus_coins)

func _perform_chord_if_valid(grid_x: int, grid_y: int):
	# Perform chord action if the cell is valid for chording (left+right click)
	var field_x = camera_x + grid_x
	var field_y = camera_y + grid_y
	
	if field_x >= FIELD_SIZE or field_y >= FIELD_SIZE:
		return
	
	# Only chord on revealed numbered tiles
	if revealed[field_x][field_y] and minefield[field_x][field_y] == 0:
		var adjacent_mines = _count_adjacent_mines(field_x, field_y)
		if adjacent_mines > 0:  # Only chord if it's a numbered tile
			var adjacent_flags = _count_adjacent_flags(field_x, field_y)
			if adjacent_flags == adjacent_mines:
				# Number of flags matches the number on the tile - perform chord
				_chord_reveal(field_x, field_y)
				_update_camera_position()
				_update_info_display()
				print("Left+Right chord performed at (", field_x, ",", field_y, ")")

func _on_cell_pressed(grid_x: int, grid_y: int):
	# Only process if we're not dragging (to avoid accidental reveals while swiping)
	if is_dragging:
		return
	
	# Additional check: ensure this is a deliberate tap, not accidental during drag
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_since_touch_start = current_time - last_touch_time
	if time_since_touch_start > touch_threshold:
		return  # Too long since touch start, likely not a tap
		
	var field_x = camera_x + grid_x
	var field_y = camera_y + grid_y
	
	if field_x >= FIELD_SIZE or field_y >= FIELD_SIZE:
		return
	
	# Check for double-click (chord feature)
	var is_double_click = false
	if current_time - last_click_time < double_click_threshold and last_clicked_cell == Vector2(field_x, field_y):
		is_double_click = true
	
	last_click_time = current_time
	last_clicked_cell = Vector2(field_x, field_y)
	
	# Handle double-click on revealed numbered tiles (chord feature)
	if is_double_click and revealed[field_x][field_y] and minefield[field_x][field_y] == 0:
		var adjacent_mines = _count_adjacent_mines(field_x, field_y)
		if adjacent_mines > 0:  # Only chord if it's a numbered tile
			var adjacent_flags = _count_adjacent_flags(field_x, field_y)
			if adjacent_flags == adjacent_mines:
				# Number of flags matches the number on the tile - perform chord
				_chord_reveal(field_x, field_y)
				_update_camera_position()
				_update_info_display()
				return
	
	# Regular single-click behavior
	# Check flag mode
	if flag_mode:
		_toggle_flag(grid_x, grid_y)
	else:
		if flagged[field_x][field_y]:
			return  # Can't reveal flagged cells
		
		_reveal_cell(field_x, field_y)
	
	_update_camera_position()
	_update_info_display()

func _on_cell_input(event: InputEvent, grid_x: int, grid_y: int):
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_touch_start(event.position, grid_x, grid_y)
		else:
			_handle_touch_end(grid_x, grid_y)
	elif event is InputEventScreenDrag:
		_handle_drag(event.position)
	elif event is InputEventMouseButton:
		# Desktop support
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				left_button_pressed = true
				current_chord_cell = Vector2(camera_x + grid_x, camera_y + grid_y)
				# Check if both buttons are now pressed (chord)
				if right_button_pressed:
					_perform_chord_if_valid(grid_x, grid_y)
				else:
					_handle_touch_start(event.position, grid_x, grid_y)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				right_button_pressed = true
				current_chord_cell = Vector2(camera_x + grid_x, camera_y + grid_y)
				# Check if both buttons are now pressed (chord)
				if left_button_pressed:
					_perform_chord_if_valid(grid_x, grid_y)
				else:
					# Right click to flag (desktop only)
					_toggle_flag(grid_x, grid_y)
		else:
			# Button released
			if event.button_index == MOUSE_BUTTON_LEFT:
				left_button_pressed = false
				if not right_button_pressed:
					_handle_touch_end(grid_x, grid_y)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				right_button_pressed = false
				# Don't call handle_touch_end for right button release
	elif event is InputEventMouseMotion and is_dragging:
		_handle_drag(event.position)

func _toggle_flag(grid_x: int, grid_y: int):
	var field_x = camera_x + grid_x
	var field_y = camera_y + grid_y
	
	if field_x >= FIELD_SIZE or field_y >= FIELD_SIZE:
		return
	
	if revealed[field_x][field_y]:
		return  # Can't flag revealed cells
	
	flagged[field_x][field_y] = !flagged[field_x][field_y]
	_update_camera_position()
	_update_info_display()
	_update_minimap()  # Update minimap when flags change

func _reveal_cell(x: int, y: int):
	# Limited flood reveal - use variable flood radius
	var origin_x = x
	var origin_y = y
	var cells_revealed = 0  # Count cells revealed for coin reward
	
	# Use iterative approach with a queue to avoid stack overflow
	var cells_to_reveal = []
	cells_to_reveal.push_back(Vector2(x, y))
	
	while cells_to_reveal.size() > 0:
		var current_cell = cells_to_reveal.pop_front()
		var current_x = int(current_cell.x)
		var current_y = int(current_cell.y)
		
		# Check bounds
		if current_x < 0 or current_x >= FIELD_SIZE or current_y < 0 or current_y >= FIELD_SIZE:
			continue
		
		# Check if we're within the flood radius from the origin (Manhattan distance)
		var distance_from_origin = abs(current_x - origin_x) + abs(current_y - origin_y)
		if distance_from_origin > flood_radius:
			continue
		
		# Skip if already revealed or flagged
		if revealed[current_x][current_y] or flagged[current_x][current_y]:
			continue
		
		# Reveal the cell and award coin with multiplier
		revealed[current_x][current_y] = true
		cells_revealed += 1
		tiles_revealed += 1  # Track total tiles revealed for score
		var coins_earned = 1.0 * coin_multiplier  # Use float calculation
		coins += coins_earned
		score += int(coins_earned * 10)  # 10 points per coin earned (convert to int for score)
		
		# Show floating coin text for this cell
		_show_floating_coin_text(current_x, current_y, coins_earned)
		
		# Check if it's a mine
		if minefield[current_x][current_y] == 1:
			print("Game Over! Hit a mine at (", current_x, ",", current_y, ")")
			game_over = true
			_show_all_mines()
			_show_game_over()
			return
		
		# If cell has no adjacent mines, add adjacent cells to the queue
		var adjacent_mines = _count_adjacent_mines(current_x, current_y)
		if adjacent_mines == 0:
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var next_x = current_x + dx
					var next_y = current_y + dy
					# Only add to queue if within bounds, within flood radius, and not already revealed/flagged
					var next_distance = abs(next_x - origin_x) + abs(next_y - origin_y)
					if (next_x >= 0 and next_x < FIELD_SIZE and 
						next_y >= 0 and next_y < FIELD_SIZE and
						next_distance <= flood_radius and
						not revealed[next_x][next_y] and not flagged[next_x][next_y]):
						cells_to_reveal.push_back(Vector2(next_x, next_y))
	
	# Update UI after revealing cells
	_update_upgrade_ui()
	_update_minimap()  # Update minimap when cells are revealed
	print("Revealed ", cells_revealed, " cells, earned ", "%.1f" % (cells_revealed * coin_multiplier), " coins. Total coins: ", "%.1f" % coins)

func _show_floating_coin_text(world_x: int, world_y: int, coin_amount: float = 1.0):
	# Create floating "+$X.X" text at the world coordinates
	var floating_label = Label.new()
	floating_label.text = "+$" + str("%.1f" % coin_amount)
	floating_label.add_theme_color_override("font_color", Color.YELLOW)
	floating_label.add_theme_font_size_override("font_size", 10)
	
	# Convert world coordinates to screen position
	var screen_x = (world_x - camera_x) * CELL_SIZE + COORD_SIZE
	var screen_y = (world_y - camera_y) * CELL_SIZE + COORD_SIZE
	
	# Only show if the cell is visible on screen
	if screen_x >= 0 and screen_x < VIEWPORT_SIZE * CELL_SIZE and screen_y >= 0 and screen_y < VIEWPORT_SIZE * CELL_SIZE:
		floating_label.position = Vector2(screen_x, screen_y)
		floating_label.size = Vector2(CELL_SIZE, CELL_SIZE)
		floating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		floating_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# Add to the grid container (temporary)
		grid_container.add_child(floating_label)
		
		# Create animation
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(floating_label, "position", Vector2(screen_x, screen_y - 30), 1.0)
		tween.tween_property(floating_label, "modulate", Color.TRANSPARENT, 1.0)
		tween.tween_callback(floating_label.queue_free).set_delay(1.0)

func _show_floating_chord_bonus_text(world_x: int, world_y: int, bonus_amount: float):
	# Create floating "CHORD BONUS +$X.X" text at the world coordinates
	var floating_label = Label.new()
	floating_label.text = "CHORD +$" + str("%.1f" % bonus_amount)
	floating_label.add_theme_color_override("font_color", Color.CYAN)
	floating_label.add_theme_font_size_override("font_size", 16)
	
	# Convert world coordinates to screen position
	var screen_x = (world_x - camera_x) * CELL_SIZE + COORD_SIZE
	var screen_y = (world_y - camera_y) * CELL_SIZE + COORD_SIZE
	
	# Only show if the cell is visible on screen
	if screen_x >= 0 and screen_x < VIEWPORT_SIZE * CELL_SIZE and screen_y >= 0 and screen_y < VIEWPORT_SIZE * CELL_SIZE:
		floating_label.position = Vector2(screen_x - 20, screen_y - 10)  # Offset slightly
		floating_label.size = Vector2(CELL_SIZE + 40, CELL_SIZE)
		floating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		floating_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# Add to the grid container (temporary)
		grid_container.add_child(floating_label)
		
		# Create animation (larger movement for bonus)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(floating_label, "position", Vector2(screen_x - 20, screen_y - 50), 1.5)
		tween.tween_property(floating_label, "modulate", Color.TRANSPARENT, 1.5)
		tween.tween_callback(floating_label.queue_free).set_delay(1.5)

func _show_all_mines():
	for x in range(FIELD_SIZE):
		for y in range(FIELD_SIZE):
			if minefield[x][y] == 1:
				revealed[x][y] = true

func _handle_touch_start(pos: Vector2, grid_x: int = -1, grid_y: int = -1):
	is_dragging = false  # Start as not dragging
	drag_start_pos = pos
	last_camera_pos = Vector2(camera_x, camera_y)
	last_touch_time = Time.get_ticks_msec() / 1000.0

func _handle_touch_end(grid_x: int = -1, grid_y: int = -1):
	var current_time = Time.get_ticks_msec() / 1000.0
	var touch_duration = current_time - last_touch_time
	
	# If it was a quick tap and we weren't dragging much, treat as a tap
	if not is_dragging and touch_duration < touch_threshold and grid_x >= 0 and grid_y >= 0:
		# This was a tap - let the button press handle it
		pass
	# Remove the long press flag toggle to prevent accidental flagging during drag
	# elif is_dragging and touch_duration > 0.5 and grid_x >= 0 and grid_y >= 0:
	#	# Long press while not moving much - toggle flag
	#	_toggle_flag(grid_x, grid_y)
	
	is_dragging = false

func _handle_drag(pos: Vector2):
	var delta = drag_start_pos - pos
	var drag_distance = delta.length()
	
	# If we've moved enough, start treating this as a drag
	if drag_distance > 15:  # Reduced threshold for more responsive drag detection
		is_dragging = true
	
	if is_dragging:
		var sensitivity = 0.08  # Slightly increased sensitivity for smoother dragging
		
		var new_camera_x = int(last_camera_pos.x + delta.x * sensitivity)
		var new_camera_y = int(last_camera_pos.y + delta.y * sensitivity)
		
		# Only update if position actually changed
		if new_camera_x != camera_x or new_camera_y != camera_y:
			camera_x = new_camera_x
			camera_y = new_camera_y
			_update_camera_position()

func _update_info_display():
	var total_mines = MINE_COUNT
	var flags_used = 0
	var revealed_count = 0
	
	for x in range(FIELD_SIZE):
		for y in range(FIELD_SIZE):
			if flagged[x][y]:
				flags_used += 1
			if revealed[x][y]:
				revealed_count += 1
	
	if info_label:
		info_label.text = "Mines: %d | Flags: %d | Pos: (%d,%d)" % [total_mines, flags_used, camera_x, camera_y]
	else:
		print("Warning: info_label not found in scene!")

func _update_flag_mode_button():
	if flag_mode_button:
		if flag_mode:
			flag_mode_button.text = "ON"
			flag_mode_button.modulate = Color.YELLOW
		else:
			flag_mode_button.text = "OFF"
			flag_mode_button.modulate = Color.WHITE
	else:
		print("Warning: flag_mode_button not found in scene!")

func _on_flag_mode_button_pressed():
	flag_mode = !flag_mode
	_update_flag_mode_button()
	print("Flag mode: ", "ON" if flag_mode else "OFF")

func _on_back_button_pressed():
	print("Back to main menu")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_game_area_input(event: InputEvent):
	# Handle swipe gestures on the game area
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_touch_start(event.position)
		else:
			_handle_touch_end()
	elif event is InputEventScreenDrag:
		_handle_drag(event.position)
	elif event is InputEventMouseButton:
		if event.pressed:
			_handle_touch_start(event.position)
		else:
			_handle_touch_end()
	elif event is InputEventMouseMotion and is_dragging:
		_handle_drag(event.position)

# Upgrade system functions
func _update_upgrade_ui():
	print("Updating upgrade UI - Coins: ", coins)  # Debug print
	if coins_label:
		coins_label.text = "Coins: " + str("%.1f" % coins)  # Show 1 decimal place
		print("Coins label updated to: ", coins_label.text)  # Debug print
	else:
		print("Warning: coins_label is null!")  # Debug warning
	
	# Flood upgrade
	if flood_level_label:
		flood_level_label.text = "Flood Level: " + str(flood_upgrade_level) + " (Radius: " + str(flood_radius) + ")"
	if flood_upgrade_button:
		flood_upgrade_button.text = "Upgrade Flood (" + str(flood_upgrade_cost) + " coins)"
		flood_upgrade_button.disabled = coins < flood_upgrade_cost
	
	# Coin multiplier upgrade
	if coin_multiplier_level_label:
		coin_multiplier_level_label.text = "Multiplier: x" + str("%.1f" % coin_multiplier) + " (Level " + str(coin_multiplier_upgrade_level) + ")"
	if coin_multiplier_upgrade_button:
		coin_multiplier_upgrade_button.text = "Upgrade Multiplier (" + str(coin_multiplier_upgrade_cost) + " coins)"
		coin_multiplier_upgrade_button.disabled = coins < coin_multiplier_upgrade_cost
	
	# Chord bonus upgrade
	if chord_bonus_level_label:
		chord_bonus_level_label.text = "Chord Bonus: +" + str(chord_bonus) + " (Level " + str(chord_bonus_upgrade_level) + ")"
	if chord_bonus_upgrade_button:
		chord_bonus_upgrade_button.text = "Upgrade Chord (" + str(chord_bonus_upgrade_cost) + " coins)"
		chord_bonus_upgrade_button.disabled = coins < chord_bonus_upgrade_cost
	
	# End game bonus upgrade
	if end_game_bonus_level_label:
		end_game_bonus_level_label.text = "End Game Bonus: +" + str(end_game_bonus) + " (Level " + str(end_game_bonus_upgrade_level) + ")"
	if end_game_bonus_upgrade_button:
		end_game_bonus_upgrade_button.text = "Upgrade End Bonus (" + str(end_game_bonus_upgrade_cost) + " coins)"
		end_game_bonus_upgrade_button.disabled = coins < end_game_bonus_upgrade_cost

func _on_flood_upgrade_button_pressed():
	if coins >= flood_upgrade_cost:
		coins -= flood_upgrade_cost
		flood_upgrade_level += 1
		flood_radius += 2  # Increase radius by 2 each upgrade
		flood_upgrade_cost = int(flood_upgrade_cost * 1.5)  # Increase cost by 50% each upgrade
		_update_upgrade_ui()
		print("Flood upgraded! New radius: ", flood_radius, ", Next upgrade cost: ", flood_upgrade_cost)

func _on_coin_multiplier_upgrade_button_pressed():
	if coins >= coin_multiplier_upgrade_cost:
		coins -= coin_multiplier_upgrade_cost
		coin_multiplier_upgrade_level += 1
		coin_multiplier += 0.1  # Increase multiplier by 0.1 each upgrade (1.0 -> 1.1 -> 1.2 ...)
		coin_multiplier_upgrade_cost = int(coin_multiplier_upgrade_cost * 1.6)  # Increase cost by 60% each upgrade
		_update_upgrade_ui()
		print("Coin multiplier upgraded! New multiplier: x", "%.1f" % coin_multiplier, ", Next upgrade cost: ", coin_multiplier_upgrade_cost)

func _on_chord_bonus_upgrade_button_pressed():
	if coins >= chord_bonus_upgrade_cost:
		coins -= chord_bonus_upgrade_cost
		chord_bonus_upgrade_level += 1
		chord_bonus += 3  # Increase bonus by 3 each upgrade (0 -> 3 -> 6 -> 9 ...)
		chord_bonus_upgrade_cost = int(chord_bonus_upgrade_cost * 1.7)  # Increase cost by 70% each upgrade
		_update_upgrade_ui()
		print("Chord bonus upgraded! New bonus: +", "%.1f" % float(chord_bonus), ", Next upgrade cost: ", chord_bonus_upgrade_cost)

func _on_end_game_bonus_upgrade_button_pressed():
	if coins >= end_game_bonus_upgrade_cost:
		coins -= end_game_bonus_upgrade_cost
		end_game_bonus_upgrade_level += 1
		end_game_bonus += 100  # Increase bonus by 100 each upgrade (100 -> 200 -> 300 ...)
		end_game_bonus_upgrade_cost += 30  # Increase cost by 30 each upgrade (30 -> 60 -> 90 ...)
		_update_upgrade_ui()
		print("End game bonus upgraded! New bonus: +", end_game_bonus, ", Next upgrade cost: ", end_game_bonus_upgrade_cost)

# Game over and score functions
func _show_game_over():
	game_over = true
	is_timing = false  # Stop the timer
	var current_time = Time.get_ticks_msec() / 1000.0 - game_start_time
	game_time = current_time  # Update the global game_time
	var final_score = _calculate_final_score(current_time)
	
	if game_over_panel:
		game_over_panel.visible = true
		
		if game_over_title:
			game_over_title.text = "GAME OVER!"
		
		if final_score_label:
			final_score_label.text = "Final Score: " + str(final_score)
		
		if stats_label:
			var minutes = int(game_time) / 60.0
			var seconds = int(game_time) % 60
			stats_label.text = "Time: %02d:%02d\nTiles Revealed: %d\nChords Performed: %d\nCoins Earned: %.1f" % [minutes, seconds, tiles_revealed, chords_performed, coins]
	else:
		# Fallback if no game over panel - print to console
		print("=== GAME OVER ===")
		print("Final Score: ", final_score)
		print("Time: ", game_time, " seconds")
		print("Tiles Revealed: ", tiles_revealed)
		print("Chords Performed: ", chords_performed)
		print("Coins Earned: ", "%.1f" % coins)

func _calculate_final_score(time_taken: float) -> int:
	# Score calculation:
	# Base score from current score
	# Time bonus: 1000 points - (time in seconds * 5)
	# Efficiency bonus: (tiles_revealed / game_time) * 100
	# Chord bonus: chords_performed * 500
	
	var time_bonus = max(0, 1000 - int(time_taken * 5))
	var efficiency_bonus = 0
	if time_taken > 0:
		efficiency_bonus = int((tiles_revealed / time_taken) * 100)
	var chord_score_bonus = chords_performed * 500
	
	var final_score = score + time_bonus + efficiency_bonus + chord_score_bonus
	
	print("Score breakdown:")
	print("  Base score: ", score)
	print("  Time bonus: ", time_bonus)
	print("  Efficiency bonus: ", efficiency_bonus)
	print("  Chord bonus: ", chord_score_bonus)
	print("  Final score: ", final_score)
	
	return final_score

func _on_restart_button_pressed():
	# Reset all game variables
	game_over = false
	score = 0
	tiles_revealed = 0
	chords_performed = 0
	coins = 0.0  # Reset to float
	game_time = 0.0
	is_timing = false
	
	# Reset upgrades to initial values
	flood_radius = 5
	flood_upgrade_cost = 10
	flood_upgrade_level = 1
	coin_multiplier = 1.0
	coin_multiplier_upgrade_cost = 15
	coin_multiplier_upgrade_level = 1
	chord_bonus = 0
	chord_bonus_upgrade_cost = 20
	chord_bonus_upgrade_level = 1
	
	# Hide game over panel
	if game_over_panel:
		game_over_panel.visible = false
	
	# Reinitialize the game
	_initialize_minefield()
	_update_camera_position()
	_update_info_display()
	_update_upgrade_ui()
	
	# Restart the timer
	game_start_time = Time.get_ticks_msec() / 1000.0
	is_timing = true
	_update_minimap()  # Update minimap after restart
	
	# Restart timer
	game_start_time = Time.get_ticks_msec() / 1000.0
	
	print("Game restarted!")

func _on_game_over_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# Minimap functions
func _create_minimap():
	# Get minimap panel reference from scene instead of creating it
	minimap_panel = get_node_or_null("UI/MinimapPanel")
	if not minimap_panel:
		print("Warning: MinimapPanel not found in scene!")
		return
	
	# Get or create minimap title
	var minimap_title = minimap_panel.get_node_or_null("MinimapTitle")
	if not minimap_title:
		minimap_title = Label.new()
		minimap_title.text = "MINIMAP"
		minimap_title.name = "MinimapTitle"
		minimap_title.position = Vector2(10, 5)
		minimap_title.size = Vector2(MINIMAP_SIZE, 20)
		minimap_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		minimap_title.add_theme_font_size_override("font_size", 12)
		minimap_panel.add_child(minimap_title)
	
	# Get or create minimap container
	minimap_container = minimap_panel.get_node_or_null("MinimapContainer")
	if not minimap_container:
		minimap_container = Control.new()
		minimap_container.name = "MinimapContainer"
		minimap_container.position = Vector2(10, 25)
		minimap_container.size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
		minimap_panel.add_child(minimap_container)
	
	# Create texture rect for minimap image
	minimap_texture_rect = TextureRect.new()
	minimap_texture_rect.size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
	minimap_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP
	minimap_container.add_child(minimap_texture_rect)
	
	# Create viewport rectangle indicator
	minimap_viewport_rect = ColorRect.new()
	minimap_viewport_rect.color = Color.RED
	minimap_viewport_rect.modulate = Color(1, 0, 0, 0.5)  # Semi-transparent red
	var viewport_size_on_minimap = Vector2(
		VIEWPORT_SIZE * MINIMAP_CELL_SIZE,
		VIEWPORT_SIZE * MINIMAP_CELL_SIZE
	)
	minimap_viewport_rect.size = viewport_size_on_minimap
	minimap_container.add_child(minimap_viewport_rect)
	
	# Connect input events for minimap navigation
	minimap_container.gui_input.connect(_on_minimap_input)
	
	# Create initial minimap image
	_generate_minimap_image()

func _generate_minimap_image():
	# Safety check: ensure arrays are initialized
	if revealed.is_empty() or flagged.is_empty() or minefield.is_empty():
		print("Warning: Minimap called before minefield initialization")
		return
	
	# Create image for minimap
	minimap_image = Image.create(FIELD_SIZE, FIELD_SIZE, false, Image.FORMAT_RGB8)
	
	# Fill minimap with game state
	for x in range(FIELD_SIZE):
		for y in range(FIELD_SIZE):
			var color = Color.GRAY  # Default unrevealed color
			
			if revealed[x][y]:
				if minefield[x][y] == 1:
					color = Color.RED  # Mine
				else:
					var adjacent_mines = _count_adjacent_mines(x, y)
					if adjacent_mines == 0:
						color = Color.WHITE  # Empty revealed
					else:
						# Color based on number (gradient from light blue to dark blue)
						var intensity = float(adjacent_mines) / 8.0  # Max 8 adjacent mines
						color = Color(0.5 - intensity * 0.3, 0.5 - intensity * 0.3, 1.0)  # Light to dark blue
			elif flagged[x][y]:
				color = Color.YELLOW  # Flagged
			# else remains gray for unrevealed
			
			minimap_image.set_pixel(x, y, color)
	
	# Create texture from image
	minimap_texture = ImageTexture.new()
	minimap_texture.create_from_image(minimap_image)
	minimap_texture_rect.texture = minimap_texture

func _update_minimap():
	if minimap_image and minimap_texture and minimap_texture_rect and minimap_viewport_rect:
		# Safety check: ensure arrays are initialized
		if revealed.is_empty() or flagged.is_empty() or minefield.is_empty():
			return
		
		# Regenerate minimap image with current game state
		_generate_minimap_image()
		
		# Update viewport indicator position
		var viewport_pos_on_minimap = Vector2(
			camera_x * MINIMAP_CELL_SIZE,
			camera_y * MINIMAP_CELL_SIZE
		)
		minimap_viewport_rect.position = viewport_pos_on_minimap

func _on_minimap_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			minimap_is_dragging = true
			_navigate_to_minimap_position(event.position)
		else:
			minimap_is_dragging = false
	elif event is InputEventMouseMotion and minimap_is_dragging:
		_navigate_to_minimap_position(event.position)

func _navigate_to_minimap_position(minimap_pos: Vector2):
	# Convert minimap position to field coordinates
	var field_x = int(minimap_pos.x / MINIMAP_CELL_SIZE)
	var field_y = int(minimap_pos.y / MINIMAP_CELL_SIZE)
	
	# Center the viewport on the clicked position
	camera_x = int(field_x - VIEWPORT_SIZE / 2)
	camera_y = int(field_y - VIEWPORT_SIZE / 2)
	
	# Clamp to valid bounds
	camera_x = int(clamp(camera_x, 0, FIELD_SIZE - VIEWPORT_SIZE))
	camera_y = int(clamp(camera_y, 0, FIELD_SIZE - VIEWPORT_SIZE))
	
	# Update the main view
	_update_camera_position()
	_update_minimap()  # Update minimap viewport indicator

func _update_time_display():
	if time_label:
		var minutes = int(game_time) / 60.0
		var seconds = int(game_time) % 60
		time_label.text = "Time: %02d:%02d" % [minutes, seconds]

func _on_end_game_button_pressed():
	if not game_over:
		# Player chose to end game early - give bonus
		var bonus = end_game_bonus
		coins += bonus
		
		print("Player ended game early. Bonus: +", bonus, " coins")
		_show_game_over()
