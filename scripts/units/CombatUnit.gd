extends "res://scripts/units/Unit.gd"
## Combat unit that attacks enemy units and bases

class_name CombatUnit

var _combat_system: Node
var _unit_manager: Node
var _event_bus: Node

func _ready():
	super._ready()
	# Wait one frame for systems to initialize
	await get_tree().process_frame
	_combat_system = get_tree().get_first_node_in_group("combat_system")
	_unit_manager = get_tree().get_first_node_in_group("unit_manager")
	_event_bus = get_tree().get_first_node_in_group("game_event_bus")

func process_unit(delta: float) -> void:
	if _combat_system == null or _unit_manager == null:
		return
	
	attack_timer -= delta
	
	# Find target and engage
	var target = find_target()
	if target == null:
		velocity = Vector2.ZERO
		return
	
	var dist = _combat_system.get_attack_distance_to(self, target)
	
	# Move to attack range
	if dist > attack_range:
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()
	# Attack
	else:
		velocity = Vector2.ZERO
		if attack_timer <= 0:
			_combat_system.execute_attack(self, target)
			attack_timer = attack_cooldown

## Find nearest enemy or their base
func find_target() -> Node:
	# Check nearby units first
	var closest_unit = _unit_manager.get_nearest_enemy_to(self)
	var closest_dist = 999999.0
	
	if closest_unit:
		closest_dist = global_position.distance_to(closest_unit.global_position)
	
	# Check enemy base
	var main = get_tree().get_first_node_in_group("main")
	if main:
		var enemy_base = main.get_node_or_null("EnemyBase") if team == "player" else main.get_node_or_null("PlayerBase")
		if enemy_base:
			var base_dist = global_position.distance_to(enemy_base.global_position)
			if closest_unit == null or base_dist < closest_dist:
				return enemy_base
	
	return closest_unit
