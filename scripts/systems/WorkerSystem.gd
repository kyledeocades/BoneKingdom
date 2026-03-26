extends Node
## Handles worker/gathering logic
## Coordinates bone collection and delivery

class_name WorkerSystem

var _bone_pile: Node
var _player_base: Node
var _enemy_base: Node
var _event_bus: GameEventBus

func _ready():
	add_to_group("worker_system")
	_event_bus = get_tree().get_first_node_in_group("game_event_bus")
	
	var main = get_tree().get_first_node_in_group("main")
	if main:
		_bone_pile = main.get_node_or_null("BonePile")
		_player_base = main.get_node_or_null("PlayerBase")
		_enemy_base = main.get_node_or_null("EnemyBase")

## Process worker gathering logic
func process_worker(worker: Node, delta: float) -> void:
	if not worker.is_worker:
		return
	
	worker.gather_timer -= delta
	
	var target = _bone_pile
	var base = _player_base if worker.team == "player" else _enemy_base
	
	if base == null or target == null:
		return
	
	# Move to bone pile if not carrying
	if not worker.carrying_bones:
		move_worker_toward(worker, target.global_position)
		if worker.global_position.distance_to(target.global_position) < 20:
			if worker.gather_timer <= 0:
				worker.carrying_bones = true
				worker.gather_timer = worker.gather_cooldown
	# Move to base if carrying
	else:
		move_worker_toward(worker, base.global_position)
		if worker.global_position.distance_to(base.global_position) < 40:
			deliver_bones(worker)
			worker.carrying_bones = false

## Move a unit toward target position
func move_worker_toward(unit: Node, target_pos: Vector2) -> void:
	var direction = (target_pos - unit.global_position).normalized()
	unit.velocity = direction * unit.move_speed
	unit.move_and_slide()

## Process bone delivery and emit event
func deliver_bones(worker: Node) -> void:
	var amount = worker.gather_rate
	if worker.team == "player":
		_event_bus.bones_earned.emit(amount, "player")
	else:
		_event_bus.bones_earned.emit(amount, "enemy")
	_event_bus.bones_gathered.emit(amount, worker.team)
