extends Node
## Manages all UI updates based on game events
## Keeps UI logic separate from game logic

class_name UIController

# ── Theme Colors ─────────────────────────────────────────────────────────────
const C_BONE    := Color("#E8D5A3")
const C_GOLD    := Color("#C9A84C")
const C_GOLD_DIM:= Color("#7A6030")
const C_CRIMSON := Color("#8B1A1A")
const C_ASH     := Color("#5A4E3A")
const C_PANEL   := Color("#16100A")
const C_BG      := Color("#0C0906")

@onready var bones_label = get_node_or_null("../UI/BonesLabel")
@onready var result_label = get_node_or_null("../UI/ResultLabel")
@onready var spawn_buttons = get_node_or_null("../UI/SpawnButtons")

var _game_state: Node
var _unit_catalog: Node
var _event_bus: Node
var _game_controller: Node

# Track button data for cooldown updates
var _button_data: Array[Dictionary] = []  # {button: Button, unit_id: String, overlay: ColorRect, label: Label, stats: UnitStats}

func _ready():
	add_to_group("ui_controller")
	# Wait a frame for parent to fully initialize
	await get_tree().process_frame
	
	_game_state = get_tree().get_first_node_in_group("game_state")
	_unit_catalog = get_tree().get_first_node_in_group("unit_catalog")
	_event_bus = get_tree().get_first_node_in_group("game_event_bus")
	_game_controller = get_tree().get_first_node_in_group("main")
	
	# Re-resolve node paths since they couldn't resolve in @onready (parent was being initialized)
	bones_label = get_parent().get_node_or_null("UI/BonesLabel")
	result_label = get_parent().get_node_or_null("UI/ResultLabel")
	spawn_buttons = get_parent().get_node_or_null("UI/SpawnButtons")
	
	# Subscribe to game state changes
	if _game_state:
		_game_state.bones_changed.connect(_on_bones_changed)
		_game_state.result_changed.connect(_on_result_changed)
	
	# Subscribe to events
	if _event_bus:
		_event_bus.game_ended.connect(_on_game_ended)
	
	# Initial UI setup
	_on_bones_changed(_game_state.bones if _game_state else 0)
	_on_result_changed("", false)
	
	#print("DEBUG UIController: Ready. Bones: ", _game_state.bones if _game_state else "UNKNOWN")

func _process(_delta: float) -> void:
	_update_button_cooldowns()

#var _debug_frame_count = 0

## Build player spawn buttons from catalog
func build_spawn_buttons(on_spawn_pressed: Callable) -> void:
	if spawn_buttons == null:
		return
	
	for child in spawn_buttons.get_children():
		child.queue_free()
	
	_button_data.clear()

	if _unit_catalog == null:
		return

	spawn_buttons.add_theme_constant_override("separation", 12)

	var units = _unit_catalog.get_player_spawn_units()
	#print("DEBUG UIController: Creating spawn buttons for ", units.size(), " units")
	
	for stats in units:
		var button_container = _create_stylized_button(stats, on_spawn_pressed)
		spawn_buttons.add_child(button_container)
		#print("DEBUG UIController: Added button for ", stats.unit_id)

func _create_stylized_button(stats, on_spawn_pressed: Callable) -> Control:
	# Main container for the button
	var container = MarginContainer.new()
	container.custom_minimum_size = Vector2(140, 80)
	
	# The actual button
	var button = Button.new()
	button.custom_minimum_size = Vector2(140, 80)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Style the button
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = C_PANEL
	normal_style.set_border_width_all(2)
	normal_style.border_color = C_GOLD_DIM
	normal_style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = C_PANEL.lightened(0.15)
	hover_style.set_border_width_all(2)
	hover_style.border_color = C_GOLD
	hover_style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = C_PANEL.darkened(0.2)
	pressed_style.set_border_width_all(2)
	pressed_style.border_color = C_GOLD
	pressed_style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	var disabled_style := StyleBoxFlat.new()
	disabled_style.bg_color = C_PANEL.darkened(0.3)
	disabled_style.set_border_width_all(2)
	disabled_style.border_color = C_ASH.darkened(0.3)
	disabled_style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("disabled", disabled_style)
	
	container.add_child(button)
	
	# Label overlay with unit info
	var label = Label.new()
	label.text = stats.player_name + "\n💀 " + str(stats.cost)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", C_BONE)
	label.add_theme_constant_override("line_spacing", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(label)
	
	# Cooldown overlay (initially hidden)
	var cooldown_overlay = ColorRect.new()
	cooldown_overlay.color = Color(0, 0, 0, 0.7)
	cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cooldown_overlay.visible = false
	button.add_child(cooldown_overlay)
	
	# Cooldown timer text
	var cooldown_label = Label.new()
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_font_size_override("font_size", 24)
	cooldown_label.add_theme_color_override("font_color", C_CRIMSON)
	cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cooldown_overlay.add_child(cooldown_label)
	
	# Connect button press
	button.pressed.connect(on_spawn_pressed.bind(stats.unit_id))
	
	# Store button data for cooldown tracking
	_button_data.append({
		"button": button,
		"unit_id": stats.unit_id,
		"overlay": cooldown_overlay,
		"cooldown_label": cooldown_label,
		"info_label": label,
		"stats": stats
	})
	
	return container

## Update bones display
func _on_bones_changed(new_bones: int) -> void:
	if bones_label != null:
		bones_label.text = "💀 Bones: " + str(new_bones)
		bones_label.add_theme_font_size_override("font_size", 20)
		bones_label.add_theme_color_override("font_color", C_BONE)

## Update button states based on cooldowns and affordability
func _update_button_cooldowns() -> void:
	if _game_controller == null or _game_state == null:
		return
	
	#_debug_frame_count += 1
	#if _debug_frame_count <= 3:
		#print("DEBUG UIController: Frame %d, Bones: %d, Button count: %d" % [_debug_frame_count, _game_state.bones, _button_data.size()])
	
	for data in _button_data:
		var button: Button = data.button
		var unit_id: String = data.unit_id
		var overlay: ColorRect = data.overlay
		var cooldown_label: Label = data.cooldown_label
		var info_label: Label = data.info_label
		var stats = data.stats
		
		var cooldown_remaining = _game_controller.get_unit_cooldown(unit_id)
		var can_afford = _game_state.bones >= stats.cost
		
		#if _debug_frame_count <= 3:
			#print("  %s: cost=%d, can_afford=%s, cooldown=%.1f" % [unit_id, stats.cost, can_afford, cooldown_remaining])
		
		# Update cooldown overlay
		if cooldown_remaining > 0:
			overlay.visible = true
			cooldown_label.text = "%.1f" % cooldown_remaining
			button.disabled = true
		else:
			overlay.visible = false
			button.disabled = not can_afford
		
		# Update text color based on affordability
		if can_afford and cooldown_remaining <= 0:
			info_label.add_theme_color_override("font_color", C_BONE)
		else:
			info_label.add_theme_color_override("font_color", C_ASH)

## Update result display
func _on_result_changed(new_text: String, is_visible: bool) -> void:
	if result_label != null:
		result_label.text = new_text
		result_label.visible = is_visible

## Handle game end
func _on_game_ended(result: String) -> void:
	if result_label != null:
		result_label.text = result
		result_label.visible = true


		if result == "YOU WIN":
			var main = get_tree().get_first_node_in_group("main")
			if main and main._music:
				main._music.stop()
			var victory_sfx = AudioStreamPlayer.new()
			victory_sfx.stream = preload("res://audio/244022__deathtomayo__victory-rock-guitar-tapping.wav")
			victory_sfx.volume_db = -55.0
			add_child(victory_sfx)
			victory_sfx.play()
			
		elif result == "YOU LOSE":
			var main = get_tree().get_first_node_in_group("main")
			if main and main._music:
				main._music.stop()
			var defeat_sfx = AudioStreamPlayer.new()
			defeat_sfx.stream = preload("res://audio/171673__leszek_szary__failure-1.wav")
			defeat_sfx.volume_db = -50.0
			add_child(defeat_sfx)
			defeat_sfx.play()
