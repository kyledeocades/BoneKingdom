extends BaseUnit
## Worker unit that gathers bones from the bone pile

class_name WorkerUnit

var _worker_system: Node

func _ready():
	super._ready()
	# Wait one frame for systems to initialize
	await get_tree().process_frame
	_worker_system = get_tree().get_first_node_in_group("worker_system")

func process_unit(delta: float) -> void:
	if _worker_system:
		_worker_system.process_worker(self, delta)
