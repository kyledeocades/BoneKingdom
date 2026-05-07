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
@onready var health_bar: ProgressBar = get_node_or_null("HealthBar")

func _ready():
	current_health = max_health
	_event_bus = get_tree().get_first_node_in_group("game_event_bus")
	apply_healthbar_color()
	update_label()

func take_damage(amount: int):
	current_health -= amount
	
	if current_health < 0:
		current_health = 0
	
	health_changed.emit(current_health, max_health)
	update_label()
	
	if current_health <= 0:
		die()

func update_label() -> void:
	if hp_label != null:
		hp_label.text = team + " Base"

	if health_bar != null:
		health_bar.max_value = max_health
		health_bar.value = current_health
		
func apply_healthbar_color() -> void:
	if health_bar == null:
		return

	var fill_style := StyleBoxFlat.new()
	var background_style := StyleBoxFlat.new()

	if team == "player":
		fill_style.bg_color = Color(0.1, 0.9, 0.2, 0.75)
	else:
		fill_style.bg_color = Color(0.9, 0.1, 0.1, 0.75)

	background_style.bg_color = Color(0.0, 0.0, 0.0, 0.25)

	fill_style.border_width_left = 1
	fill_style.border_width_right = 1
	fill_style.border_width_top = 1
	fill_style.border_width_bottom = 1
	fill_style.border_color = Color.BLACK

	health_bar.add_theme_stylebox_override("fill", fill_style)
	health_bar.add_theme_stylebox_override("background", background_style)

func die():
	base_died.emit(team)
	if _event_bus:
		_event_bus.base_damaged.emit(self, current_health)
	queue_free()
