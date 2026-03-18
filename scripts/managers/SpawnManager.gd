extends Node
## Manages all unit instantiation, configuration, and lifecycle
## Decouples unit creation from game logic

class_name SpawnManager

var _combat_unit_scene: PackedScene
var _worker_unit_scene: PackedScene
var _unit_catalog: Node
var _event_bus: Node
var _player_spawn_pos: Vector2
var _enemy_spawn_pos: Vector2

func _ready():
	add_to_group("spawn_manager")
	_combat_unit_scene = preload("res://scenes/units/CombatUnit.tscn")
	_worker_unit_scene = preload("res://scenes/units/WorkerUnit.tscn")
	_unit_catalog = get_tree().get_first_node_in_group("unit_catalog")
	_event_bus = get_tree().get_first_node_in_group("game_event_bus")
	
	# Get spawn positions from main scene
	var main = get_tree().get_first_node_in_group("main")
	if main:
		_player_spawn_pos = main.get_node_or_null("PlayerSpawn").global_position
		_enemy_spawn_pos = main.get_node_or_null("EnemySpawn").global_position

## Spawn a unit with stats applied - creates CombatUnit or WorkerUnit based on stats
func spawn_unit(unit_id: String, team: String, position: Vector2) -> Node:
	if _unit_catalog == null:
		push_error("UnitCatalog not available")
		return null
	
	var stats = _unit_catalog.get_stats(unit_id)
	if stats == null:
		push_error("Unit stats not found: %s" % unit_id)
		return null
	
	# Choose scene based on unit type
	var scene = _combat_unit_scene if not stats.is_worker else _worker_unit_scene
	var unit = scene.instantiate()
	
	apply_unit_stats(unit, stats, team)
	unit.global_position = position + Vector2(randf_range(-10, 10), 0)  # Small offset to prevent stacking
	
	get_parent().add_child(unit)
	_event_bus.unit_spawned.emit(unit, team, unit_id)
	
	return unit

## Apply stats from UnitTypeStats to a unit instance
func apply_unit_stats(unit: Node, stats, team: String) -> void:
	unit.team = team
	unit.unit_name = stats.player_name if team == "player" else stats.enemy_name
	unit.max_health = stats.max_health
	unit.current_health = stats.max_health
	unit.damage = stats.damage
	unit.move_speed = stats.move_speed
	unit.attack_range = stats.attack_range
	unit.attack_cooldown = stats.attack_cooldown
	unit.is_worker = stats.is_worker
	unit.gather_rate = stats.gather_rate
	unit.gather_cooldown = stats.gather_cooldown
	unit.update_label()

## Spawn for player
func spawn_player_unit(unit_id: String) -> Node:
	return spawn_unit(unit_id, "player", _player_spawn_pos)

## Spawn for enemy
func spawn_enemy_unit(unit_id: String) -> Node:
	return spawn_unit(unit_id, "enemy", _enemy_spawn_pos)
