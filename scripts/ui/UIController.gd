extends Node
## Manages all UI updates based on game events
## Keeps UI logic separate from game logic

class_name UIController

@onready var bones_label = get_node_or_null("../UI/BonesLabel")
@onready var result_label = get_node_or_null("../UI/ResultLabel")
@onready var spawn_buttons = get_node_or_null("../UI/SpawnButtons")

var _game_state: Node
var _unit_catalog: Node
var _event_bus: Node

func _ready():
	add_to_group("ui_controller")
	# Wait a frame for parent to fully initialize
	await get_tree().process_frame
	
	_game_state = get_tree().get_first_node_in_group("game_state")
	_unit_catalog = get_tree().get_first_node_in_group("unit_catalog")
	_event_bus = get_tree().get_first_node_in_group("game_event_bus")
	
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

## Build player spawn buttons from catalog
func build_spawn_buttons(on_spawn_pressed: Callable) -> void:
	if spawn_buttons == null:
		return
	
	for child in spawn_buttons.get_children():
		child.queue_free()

	if _unit_catalog == null:
		return

	for stats in _unit_catalog.get_player_spawn_units():
		var button = Button.new()
		button.text = "%s (%d)" % [stats.player_name, stats.cost]
		button.pressed.connect(on_spawn_pressed.bind(stats.unit_id))
		spawn_buttons.add_child(button)

## Update bones display
func _on_bones_changed(new_bones: int) -> void:
	if bones_label != null:
		bones_label.text = "Bones: " + str(new_bones)

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
