extends Node
## Central game state management
## Tracks bones, game status, and emits state change signals

class_name GameState

signal bones_changed(new_bones: int)
signal enemy_bones_changed(new_bones: int)
signal result_changed(new_text: String, is_visible: bool)

@export var starting_bones: int = 500
@export var starting_enemy_bones: int = 500

var bones: int
var enemy_bones: int
var game_over: bool = false
var result_text: String = ""

var _event_bus: Node

func _ready():
	add_to_group("game_state")
	_event_bus = get_tree().get_first_node_in_group("game_event_bus")
	
	bones = starting_bones
	enemy_bones = starting_enemy_bones
	bones_changed.emit(bones)
	enemy_bones_changed.emit(enemy_bones)
	result_changed.emit("", false)
	
	# Listen for worker bone earnings
	if _event_bus:
		_event_bus.bones_gathered.connect(_on_bones_gathered)

func add_bones(amount: int) -> void:
	bones += amount
	bones_changed.emit(bones)

func add_enemy_bones(amount: int) -> void:
	enemy_bones += amount
	enemy_bones_changed.emit(enemy_bones)

func try_spend_bones(cost: int) -> bool:
	if bones < cost:
		return false
	bones -= cost
	bones_changed.emit(bones)
	return true

func try_spend_enemy_bones(cost: int) -> bool:
	if enemy_bones < cost:
		return false
	enemy_bones -= cost
	enemy_bones_changed.emit(enemy_bones)
	return true

func set_game_result(text: String) -> void:
	game_over = true
	result_text = text
	result_changed.emit(result_text, true)
	if _event_bus:
		_event_bus.game_ended.emit(text)

func _on_bones_gathered(amount: int, team: String) -> void:
	if team == "player":
		add_bones(amount)
	else:
		add_enemy_bones(amount)
