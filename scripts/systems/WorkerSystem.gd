extends Node

class_name WorkerSystem

var _main: Node
var _player_mine: Node
var _enemy_mine: Node
var _player_base: Node
var _enemy_base: Node
var _event_bus: GameEventBus

func _ready():
	add_to_group("worker_system")

	_main = get_tree().get_first_node_in_group("main")
	_event_bus = get_tree().get_first_node_in_group("game_event_bus")

	if _main:
		# Preferred mine names
		_player_mine = _main.get_node_or_null("PlayerMine")
		_enemy_mine = _main.get_node_or_null("EnemyMine")

		# Fallback if your scene still uses one shared BonePile
		if _player_mine == null:
			_player_mine = _main.get_node_or_null("BonePile")

		if _enemy_mine == null:
			_enemy_mine = _main.get_node_or_null("BonePile")

		_player_base = _main.get_node_or_null("PlayerBase")
		_enemy_base = _main.get_node_or_null("EnemyBase")

func _physics_process(delta):
	for unit in get_tree().get_nodes_in_group("units"):
		if unit.is_worker:
			process_worker(unit, delta)

func process_worker(worker: Node, delta: float) -> void:
	if not worker.is_worker:
		return

	worker.gather_timer -= delta

	var mine = _player_mine if worker.team == "player" else _enemy_mine
	var base = _player_base if worker.team == "player" else _enemy_base

	if mine == null or base == null:
		return

	if not worker.carrying_bones:
		var dist_to_mine = worker.global_position.distance_to(mine.global_position)

		if dist_to_mine > 20:
			move_worker_toward(worker, mine.global_position)
		else:
			worker.velocity = Vector2.ZERO

			if worker.gather_timer <= 0:
				var taken: int = worker.gather_rate

				if mine.has_method("has_bones") and mine.has_method("take_bones"):
					if mine.has_bones():
						taken = mine.take_bones(worker.gather_rate)
					else:
						taken = 0

				if taken > 0:
					worker.carrying_bones = true
					worker.gather_timer = worker.gather_cooldown

	else:
		var dist_to_base = worker.global_position.distance_to(base.global_position)

		if dist_to_base > 40:
			move_worker_toward(worker, base.global_position)
		else:
			worker.velocity = Vector2.ZERO
			deliver_bones(worker)
			worker.carrying_bones = false
			worker.gather_timer = worker.gather_cooldown

func move_worker_toward(unit: Node, target_pos: Vector2) -> void:
	var direction = (target_pos - unit.global_position).normalized()
	unit.velocity = direction * unit.move_speed
	unit.move_and_slide()

func deliver_bones(worker: Node) -> void:
	var amount = worker.gather_rate

	if _event_bus != null:
		_event_bus.bones_earned.emit(amount, worker.team)
		_event_bus.bones_gathered.emit(amount, worker.team)
		return

	# Fallback if EventBus is not working yet
	if _main != null:
		if worker.team == "player" and _main.has_method("add_bones"):
			_main.add_bones(amount)
		elif worker.team == "enemy":
			_main.enemy_bones += amount
