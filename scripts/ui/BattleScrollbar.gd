extends Control
## Battle Scrollbar UI - Shows camera position, units, and bases on a horizontal bar
## Displays at the bottom of the screen as a minimap/timeline view

class_name BattleScrollbar

# UI dimensions
const BAR_HEIGHT: int = 40
const BAR_MARGIN: int = 10
const INDICATOR_SIZE: int = 6
const BASE_SIZE: int = 12

# Colors
const COLOR_CAMERA: Color = Color(0.7, 0.9, 1.0, 0.3)  # Light blue (more transparent)
const COLOR_FRIENDLY: Color = Color(0.2, 0.9, 0.2, 0.9)  # Green
const COLOR_ENEMY: Color = Color(1.0, 0.2, 0.2, 0.9)  # Red
const COLOR_BASE_FRIENDLY: Color = Color(0.1, 0.7, 0.1, 0.95)  # Dark green
const COLOR_BASE_ENEMY: Color = Color(0.8, 0.1, 0.1, 0.95)  # Dark red
const COLOR_MINE_FRIENDLY: Color = Color(0.5, 1.0, 0.5, 0.8)  # Light green
const COLOR_MINE_ENEMY: Color = Color(1.0, 0.5, 0.5, 0.8)  # Light red
const COLOR_BG: Color = Color(0.1, 0.1, 0.1, 0.7)  # Dark background
const COLOR_BORDER: Color = Color(0.3, 0.3, 0.3, 0.9)

# Game references
var camera: Camera2D
var unit_manager: Node
var event_bus: Node
var player_base: Node
var enemy_base: Node
var player_mine: Node
var enemy_mine: Node
var camera_controller: Node

# Map bounds (set at runtime)
var map_min_x: float = 140.0
var map_max_x: float = 1140.0
var map_range: float = map_max_x - map_min_x

func _ready() -> void:
	# Setup UI properties
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	custom_minimum_size = Vector2(0, BAR_HEIGHT + BAR_MARGIN * 2)
	mouse_filter = Control.MOUSE_FILTER_STOP  # Allow input handling
	
	# Get game references
	var main = get_tree().get_first_node_in_group("main")
	if main:
		camera = main.find_child("Camera2D")
		player_base = main.find_child("PlayerBase")
		enemy_base = main.find_child("EnemyBase")
		player_mine = main.find_child("PlayerMine")
		enemy_mine = main.find_child("EnemyMine")
		camera_controller = main.find_child("CameraController")
		unit_manager = get_tree().get_first_node_in_group("unit_manager")
		event_bus = get_tree().get_first_node_in_group("game_event_bus")
		
		# Calculate map bounds from bases/anchors
		if player_base and enemy_base:
			var player_x = player_base.global_position.x
			var enemy_x = enemy_base.global_position.x
			map_min_x = min(player_x, enemy_x) - 80
			map_max_x = max(player_x, enemy_x) + 80
			map_range = map_max_x - map_min_x

func _process(_delta: float) -> void:

	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	# Handle clicks on the scrollbar to move camera
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_x = get_local_mouse_position().x
		var bar_rect = Rect2(BAR_MARGIN, BAR_MARGIN, size.x - BAR_MARGIN * 2, BAR_HEIGHT)
		
		# Check if click is within the bar vertically
		if get_local_mouse_position().y >= BAR_MARGIN and get_local_mouse_position().y <= BAR_MARGIN + BAR_HEIGHT:
			# Clamp click position to bar bounds
			click_x = clamp(click_x, bar_rect.position.x, bar_rect.position.x + bar_rect.size.x)
			
			# Convert bar click position to world position
			if bar_rect.size.x > 0:
				var normalized = (click_x - bar_rect.position.x) / bar_rect.size.x
				var world_x = map_min_x + (normalized * map_range)
				
				# Move camera to that position
				if camera:
					camera.global_position.x = world_x
					get_tree().root.set_input_as_handled()

func _draw() -> void:
	var bar_rect = Rect2(BAR_MARGIN, BAR_MARGIN, size.x - BAR_MARGIN * 2, BAR_HEIGHT)
	
	# Draw background
	draw_rect(bar_rect, COLOR_BG)
	draw_rect(bar_rect, COLOR_BORDER, false, 1.0)
	
	# Draw camera view range first (so it appears behind everything)
	if camera:
		_draw_camera_indicator(bar_rect)
	
	# Draw map scale markers (optional grid)
	var section_count = 4
	for i in range(1, section_count):
		var x = bar_rect.position.x + (bar_rect.size.x * i / section_count)
		draw_line(Vector2(x, bar_rect.position.y), Vector2(x, bar_rect.position.y + 4), COLOR_BORDER, 0.5)
	
	# Draw friendly and enemy units
	if unit_manager:
		var friendly_units = unit_manager.get_team_units("player")
		var enemy_units = unit_manager.get_team_units("enemy")
		
		for unit in friendly_units:
			_draw_unit_indicator(bar_rect, unit.global_position.x, COLOR_FRIENDLY)
		
		for unit in enemy_units:
			_draw_unit_indicator(bar_rect, unit.global_position.x, COLOR_ENEMY)
	
	# Draw bases
	if player_base:
		_draw_base_indicator(bar_rect, player_base.global_position.x, COLOR_BASE_FRIENDLY)
	if enemy_base:
		_draw_base_indicator(bar_rect, enemy_base.global_position.x, COLOR_BASE_ENEMY)
	
	# Draw mines
	if player_mine:
		_draw_mine_indicator(bar_rect, player_mine.global_position.x, COLOR_MINE_FRIENDLY)
	if enemy_mine:
		_draw_mine_indicator(bar_rect, enemy_mine.global_position.x, COLOR_MINE_ENEMY)

func _draw_unit_indicator(bar_rect: Rect2, world_x: float, color: Color) -> void:
	var bar_x = _world_to_bar(world_x, bar_rect)
	var center = Vector2(bar_x, bar_rect.get_center().y)
	draw_circle(center, INDICATOR_SIZE / 2.0, color)

func _draw_base_indicator(bar_rect: Rect2, world_x: float, color: Color) -> void:
	var bar_x = _world_to_bar(world_x, bar_rect)
	var center = Vector2(bar_x, bar_rect.get_center().y)
	draw_rect(Rect2(center - Vector2(BASE_SIZE / 2, BASE_SIZE / 2), Vector2(BASE_SIZE, BASE_SIZE)), color)
	draw_rect(Rect2(center - Vector2(BASE_SIZE / 2, BASE_SIZE / 2), Vector2(BASE_SIZE, BASE_SIZE)), Color.WHITE, false, 1.0)

func _draw_mine_indicator(bar_rect: Rect2, world_x: float, color: Color) -> void:
	var bar_x = _world_to_bar(world_x, bar_rect)
	var center = Vector2(bar_x, bar_rect.get_center().y)
	# Draw as a diamond shape (rotated square)
	var mine_size = 8
	var points = [
		center + Vector2(mine_size / 2.0, 0),
		center + Vector2(0, mine_size / 2.0),
		center - Vector2(mine_size / 2.0, 0),
		center - Vector2(0, mine_size / 2.0),
	]
	draw_colored_polygon(points, color)
	draw_polyline(PackedVector2Array(points + [points[0]]), Color.WHITE, 1.0)

func _draw_camera_indicator(bar_rect: Rect2) -> void:
	# Get camera bounds (approximate viewport width)
	var viewport_half_width = get_viewport_rect().size.x * 0.5 / camera.zoom.x
	var camera_left = camera.global_position.x - viewport_half_width
	var camera_right = camera.global_position.x + viewport_half_width
	
	var bar_left = _world_to_bar(camera_left, bar_rect)
	var bar_right = _world_to_bar(camera_right, bar_rect)
	
	# Draw camera view indicator
	var camera_rect = Rect2(bar_left, bar_rect.position.y, bar_right - bar_left, bar_rect.size.y)
	draw_rect(camera_rect, COLOR_CAMERA)
	draw_rect(camera_rect, Color.WHITE, false, 1.5)

func _world_to_bar(world_x: float, bar_rect: Rect2) -> float:
	# Map world coordinates to bar coordinates (no clamping - let it overflow naturally)
	var normalized
	if map_range != 0:
		normalized = (world_x - map_min_x) / map_range
	else: 
		normalized = 0
	
	return bar_rect.position.x + normalized * bar_rect.size.x

## Update scrollbar bounds based on stage configuration
func set_stage_bounds(stage_config) -> void:
	if stage_config == null:
		return
	
	# Set fixed bounds based on base_distance with 250 unit padding on each side
	var padding = 250.0
	map_min_x = -stage_config.base_distance - padding
	map_max_x = stage_config.base_distance + padding
	map_range = map_max_x - map_min_x
