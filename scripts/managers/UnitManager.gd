extends Node
## Tracks all units and provides queries/updates for unit state
## Centralizes unit lifecycle management

class_name UnitManager

var _units: Array[Node] = []
var _event_bus: Node

func _ready():
	add_to_group("unit_manager")
	_event_bus = get_tree().get_first_node_in_group("game_event_bus")
	_event_bus.unit_spawned.connect(_on_unit_spawned)
	_event_bus.unit_died.connect(_on_unit_died)

func _process(_delta: float) -> void:
	_prune_invalid_units()

## Get all units (can be filtered by team/type)
func get_all_units() -> Array[Node]:
	return _units

func get_team_units(team: String) -> Array[Node]:
	return _units.filter(func(u): return u.team == team)

func get_worker_units(team: String) -> Array[Node]:
	return _units.filter(func(u): return u.team == team and u.is_worker)

func get_combat_units(team: String) -> Array[Node]:
	return _units.filter(func(u): return u.team == team and not u.is_worker)

func get_nearest_enemy_to(unit: Node) -> Node:
	if not is_instance_valid(unit):
		return null

	var closest = null
	var closest_dist = 999999.0
	
	for other in _units:
		if other.team == unit.team:
			continue
		var dist = unit.global_position.distance_to(other.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = other
	
	return closest

## Count units by team and optionally type
func count_team_units(team: String, is_worker: bool = false) -> int:
	return _units.filter(
		func(u): return u.team == team and (is_worker == u.is_worker if not is_worker else true)
	).size()

func count_workers(team: String) -> int:
	return _units.filter(func(u): return u.team == team and u.is_worker).size()

func count_combat_units(team: String) -> int:
	return _units.filter(func(u): return u.team == team and not u.is_worker).size()

## Remove dead units from tracking
func _on_unit_spawned(unit: Node, _team: String, _unit_type: String) -> void:
	if _units.has(unit):
		return

	if unit.has_signal("died"):
		unit.died.connect(_on_unit_died_internal)
	unit.tree_exited.connect(_on_unit_exited.bind(unit))

	_units.append(unit)

func _on_unit_died(unit: Node, _team: String) -> void:
	_units.erase(unit)

func _on_unit_died_internal(unit: Node) -> void:
	_units.erase(unit)

func _on_unit_exited(unit: Node) -> void:
	_units.erase(unit)

func _prune_invalid_units() -> void:
	_units = _units.filter(func(u): return is_instance_valid(u))
