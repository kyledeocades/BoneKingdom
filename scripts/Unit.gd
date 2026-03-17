extends CharacterBody2D

@export var team: String = "player"
@export var unit_name: String = "Unit"
@export var max_health: int = 100
@export var damage: int = 10
@export var move_speed: float = 50.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.0
@export var is_worker: bool = false
@export var gather_rate: int = 10
@export var gather_cooldown: float = 2.0

var current_health: int
var attack_timer: float = 0.0
var gather_timer: float = 0.0
var carrying_bones: bool = false

@onready var info_label = get_node_or_null("Label")

func _ready():
	current_health = max_health
	configure_collision_behavior()
	update_label()

func configure_collision_behavior():
	# Unit-to-unit physics blocking causes lane deadlocks; combat is range-driven.
	collision_layer = 0
	collision_mask = 0

func _physics_process(delta):
	attack_timer -= delta
	gather_timer -= delta

	if is_worker:
		handle_worker(delta)
	else:
		handle_combat_unit(delta)

func handle_combat_unit(_delta):
	var target = get_nearest_enemy()
	if target == null:
		return

	var dist = get_attack_distance_to(target)

	if dist > attack_range:
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		if attack_timer <= 0:
			target.take_damage(damage)
			attack_timer = attack_cooldown

func handle_worker(_delta):
	var main = get_tree().get_first_node_in_group("main")
	if main == null:
		return

	var pile = main.get_node("BonePile")

	if team == "player":
		var base = main.get_node("PlayerBase")

		if not carrying_bones:
			move_toward_target(pile.global_position)
			if global_position.distance_to(pile.global_position) < 20:
				if gather_timer <= 0:
					carrying_bones = true
					gather_timer = gather_cooldown
		else:
			move_toward_target(base.global_position)
			if global_position.distance_to(base.global_position) < 40:
				main.add_bones(gather_rate)
				carrying_bones = false

	elif team == "enemy":
		var enemy_base = main.get_node("EnemyBase")

		if not carrying_bones:
			move_toward_target(pile.global_position)
			if global_position.distance_to(pile.global_position) < 20:
				if gather_timer <= 0:
					carrying_bones = true
					gather_timer = gather_cooldown
		else:
			move_toward_target(enemy_base.global_position)
			if global_position.distance_to(enemy_base.global_position) < 40:
				main.enemy_bones += gather_rate
				carrying_bones = false

func move_toward_target(target_pos: Vector2):
	var direction = (target_pos - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

func get_attack_distance_to(target: Node2D) -> float:
	var center_dist = global_position.distance_to(target.global_position)
	var self_radius = get_collision_radius(self)
	var target_radius = get_collision_radius(target)
	return max(0.0, center_dist - self_radius - target_radius)

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

func get_nearest_enemy():
	var units = get_tree().get_nodes_in_group("units")
	var closest = null
	var closest_dist = 999999.0

	for unit in units:
		if unit == self:
			continue
		if unit.team != team:
			var dist = global_position.distance_to(unit.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = unit

	var main = get_tree().get_first_node_in_group("main")
	if main:
		var enemy_base = main.get_node("EnemyBase") if team == "player" else main.get_node("PlayerBase")
		var base_dist = global_position.distance_to(enemy_base.global_position)
		if closest == null or base_dist < closest_dist:
			closest = enemy_base

	return closest

func take_damage(amount: int):
	current_health -= amount

	if current_health < 0:
		current_health = 0

	update_label()

	if current_health <= 0:
		die()

func update_label():
	if info_label != null:
		info_label.text = unit_name + "\nHP: " + str(current_health)

func die():
	queue_free()
