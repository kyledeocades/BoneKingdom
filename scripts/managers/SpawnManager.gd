extends Node
## Manages all unit instantiation, configuration, and lifecycle
## Decouples unit creation from game logic

class_name SpawnManager

var _combat_unit_scene: PackedScene
var _worker_unit_scene: PackedScene
var _unit_catalog: Node
var _event_bus: Node
var _player_resource_rate: float = 1.0
var _enemy_resource_rate: float = 1.0

func _ready():
	add_to_group("spawn_manager")

	_combat_unit_scene = preload("res://scenes/units/CombatUnit.tscn")
	_worker_unit_scene = preload("res://scenes/units/WorkerUnit.tscn")

	_unit_catalog = get_tree().get_first_node_in_group("unit_catalog")
	_event_bus = get_tree().get_first_node_in_group("game_event_bus")


## Set player resource gathering rate multiplier from stage config
func set_player_resource_rate(rate: float) -> void:
	_player_resource_rate = rate

## Set enemy resource gathering rate multiplier from stage config
func set_enemy_resource_rate(rate: float) -> void:
	_enemy_resource_rate = rate

## Legacy: Set resource rate (applies to player for backward compatibility)
func set_resource_rate(rate: float) -> void:
	_player_resource_rate = rate


## Spawn a unit with stats applied - creates CombatUnit or WorkerUnit based on stats
func spawn_unit(unit_id: String, team: String, position: Vector2) -> Node:
	if _unit_catalog == null:
		push_error("UnitCatalog not available")
		return null

	var stats = _unit_catalog.get_stats(unit_id)

	if stats == null:
		push_error("Unit stats not found: %s" % unit_id)
		return null

	var scene = _combat_unit_scene if not stats.is_worker else _worker_unit_scene
	var unit = scene.instantiate()

	apply_unit_stats(unit, stats, team)

	unit.global_position = position + Vector2(randf_range(-10, 10), 0)

	get_parent().add_child(unit)

	if _event_bus != null:
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
	unit.unit_stats = stats  # Store stats reference for later access
	
	# Apply team-specific resource rate
	var resource_rate = _player_resource_rate if team == "player" else _enemy_resource_rate
	unit.gather_rate = stats.gather_rate * resource_rate
	unit.gather_cooldown = stats.gather_cooldown

	apply_sprite_resource(unit, stats)

	unit.update_label()


## Supports both static Texture2D sprites and animated SpriteFrames.
## Put SpriteFrames .tres paths in stats.sprite_resource for full animation support.
func apply_sprite_resource(unit: Node, stats) -> void:
	if not ("sprite_resource" in stats):
		return

	if stats.sprite_resource == null or stats.sprite_resource == "":
		return

	var resource = load(stats.sprite_resource)

	if resource == null:
		push_warning("Could not load sprite resource: %s" % stats.sprite_resource)
		return

	var old_visual = unit.get_node_or_null("Visual")
	var animated_sprite = unit.get_node_or_null("AnimatedSprite2D")

	if animated_sprite == null:
		animated_sprite = unit.get_node_or_null("Sprite")

	if resource is SpriteFrames:
		if animated_sprite == null:
			animated_sprite = AnimatedSprite2D.new()
			animated_sprite.name = "AnimatedSprite2D"

			if old_visual:
				var parent = old_visual.get_parent()
				var idx = old_visual.get_index()
				old_visual.queue_free()
				parent.add_child(animated_sprite)
				parent.move_child(animated_sprite, idx)
			else:
				unit.add_child(animated_sprite)

		animated_sprite.sprite_frames = resource
		animated_sprite.centered = true

		play_default_animation(animated_sprite)
		return

	if resource is Texture2D:
		if old_visual:
			var parent = old_visual.get_parent()
			var idx = old_visual.get_index()
			old_visual.queue_free()

			var sprite = Sprite2D.new()
			sprite.name = "Visual"
			sprite.texture = resource
			sprite.centered = true

			parent.add_child(sprite)
			parent.move_child(sprite, idx)
		elif animated_sprite:
			var frames = SpriteFrames.new()
			frames.add_animation("Idle")
			frames.add_frame("Idle", resource)
			frames.set_animation_loop("Idle", true)

			animated_sprite.sprite_frames = frames
			animated_sprite.play("Idle")


func play_default_animation(animated_sprite: AnimatedSprite2D) -> void:
	if animated_sprite.sprite_frames == null:
		return

	var frames = animated_sprite.sprite_frames

	if frames.has_animation("Idle"):
		animated_sprite.play("Idle")
	elif frames.has_animation("idle"):
		animated_sprite.play("idle")
	elif frames.has_animation("Walk"):
		animated_sprite.play("Walk")
	elif frames.has_animation("walk"):
		animated_sprite.play("walk")
	else:
		var names = frames.get_animation_names()

		if names.size() > 0:
			animated_sprite.play(names[0])


## Spawn for player
func spawn_player_unit(unit_id: String) -> Node:
	var pos = _get_player_spawn_pos()
	return spawn_unit(unit_id, "player", pos)


## Spawn for enemy
func spawn_enemy_unit(unit_id: String) -> Node:
	var pos = _get_enemy_spawn_pos()
	return spawn_unit(unit_id, "enemy", pos)


## Get current player spawn position (fetched dynamically)
func _get_player_spawn_pos() -> Vector2:
	var main = get_tree().get_first_node_in_group("main")
	if main:
		var player_spawn = main.get_node_or_null("PlayerSpawn")
		if player_spawn:
			return player_spawn.global_position
	return Vector2.ZERO


## Get current enemy spawn position (fetched dynamically)
func _get_enemy_spawn_pos() -> Vector2:
	var main = get_tree().get_first_node_in_group("main")
	if main:
		var enemy_spawn = main.get_node_or_null("EnemySpawn")
		if enemy_spawn:
			return enemy_spawn.global_position
	return Vector2.ZERO
