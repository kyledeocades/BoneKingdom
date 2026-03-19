extends CharacterBody2D

# The base/HQ (where units are spawned by either team)

class_name Base

signal health_changed(current: int, max: int)
signal base_died(team: String)

@export var max_health: int = 500
@export var team: String = "player"

var current_health: int
var _event_bus: Node

@onready var hp_label = $Label

func _ready():
	current_health = max_health
	_event_bus = get_tree().get_first_node_in_group("game_event_bus")
	update_label()

func take_damage(amount: int):
	current_health -= amount
	
	if current_health < 0:
		current_health = 0
	
	health_changed.emit(current_health, max_health)
	update_label()
	
	if current_health <= 0:
		die()

func update_label():
	hp_label.text = team + " Base HP: " + str(current_health)

func die():
	base_died.emit(team)
	if _event_bus:
		_event_bus.base_damaged.emit(self, current_health)
	queue_free()
