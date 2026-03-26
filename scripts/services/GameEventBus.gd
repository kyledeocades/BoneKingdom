extends Node
## Centralized event bus for decoupled system communication
## Emits signals that systems subscribe to instead of direct calls

class_name GameEventBus

@warning_ignore_start("unused_signal")
# Spawning events
signal unit_spawned(unit: Node, team: String, unit_type: String)
signal unit_died(unit: Node, team: String)

# Resource events
signal bones_earned(amount: int, team: String)
signal bones_spent(amount: int, team: String)

# Combat events
signal unit_attacked(attacker: Node, target: Node, damage: int)
signal base_damaged(base: Node, damage: int)

# Game state events
signal game_started
signal game_ended(result: String)
signal win_condition_met(reason: String)
signal lose_condition_met(reason: String)

# Worker events
signal bones_gathered(amount: int, team: String)

# Enemy AI events
signal enemy_spawn_timer_tick
@warning_ignore_restore("unused_signal")

func _ready():
	add_to_group("game_event_bus")
