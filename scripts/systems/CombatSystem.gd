extends Node
## Handles combat logic and attack resolution
## Coordinates between attacking units and their targets

class_name CombatSystem

var _event_bus: Node

func _ready():
	add_to_group("combat_system")
	_event_bus = get_tree().get_first_node_in_group("game_event_bus")

## Execute an attack from attacker to target
func execute_attack(attacker: Node, target: Node) -> void:
	if attacker == null or target == null:
		return
	if not target.has_method("take_damage"):
		return
	
	var damage = attacker.damage
	target.take_damage(damage)
	_event_bus.unit_attacked.emit(attacker, target, damage)

## Find attack distance accounting for collision radii
func get_attack_distance_to(attacker: Node, target: Node) -> float:
	var center_dist = attacker.global_position.distance_to(target.global_position)
	var attacker_radius = get_collision_radius(attacker)
	var target_radius = get_collision_radius(target)
	return max(0.0, center_dist - attacker_radius - target_radius)

## Get effective collision radius for a body
func get_collision_radius(body: Node) -> float:
	var collision_shape: CollisionShape2D = body.get_node_or_null("CollisionShape2D")
	if collision_shape == null or collision_shape.shape == null:
		return 0.0

	var shape = collision_shape.shape
	if shape is RectangleShape2D:
		return min(shape.size.x, shape.size.y) * 0.5
	if shape is CircleShape2D:
		return shape.radius
	if shape is CapsuleShape2D:
		return shape.radius

	return 0.0
