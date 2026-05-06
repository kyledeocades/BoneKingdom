extends BaseUnit
## Worker unit that gathers bones from the bone pile

class_name WorkerUnit

var _worker_system: Node

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	super._ready()

	await get_tree().process_frame

	_worker_system = get_tree().get_first_node_in_group("worker_system")

	if animated_sprite:
		animated_sprite.play("Idle")

func process_unit(delta: float) -> void:
	if _worker_system:
		_worker_system.process_worker(self, delta)

	update_animation()

func update_animation() -> void:
	if animated_sprite == null:
		return

	if velocity.length() > 1:
		if velocity.x != 0:
			animated_sprite.flip_h = velocity.x < 0
		animated_sprite.play("Walk")
	else:
		animated_sprite.play("Idle")
