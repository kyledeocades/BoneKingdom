extends CharacterBody2D
## Base class for all units
## Handles health, damage, and common functionality

class_name BaseUnit

signal died(unit: Node)
signal health_changed(current: int, max: int)

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
	add_to_group("units")
	current_health = max_health
	configure_collision_behavior()
	update_label()

func configure_collision_behavior():
	# Unit-to-unit physics blocking causes lane deadlocks; combat is range-driven.
	collision_layer = 0
	collision_mask = 0

func _physics_process(delta):
	process_unit(delta)

## Override in subclasses
func process_unit(_delta: float) -> void:
	pass

func take_damage(amount: int) -> void:
	current_health -= amount
	
	if current_health < 0:
		current_health = 0
	
	health_changed.emit(current_health, max_health)
	update_label()
	
	if current_health <= 0:
		die()

func update_label() -> void:
	if info_label != null:
		info_label.text = unit_name + "\nHP: " + str(current_health)

func die() -> void:
	died.emit(self)
	queue_free()

