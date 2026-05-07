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
var unit_stats: Resource = null  # Reference to UnitStats for this unit

@onready var info_label = get_node_or_null("Label")
@onready var health_bar: ProgressBar = get_node_or_null("HealthBar")
		
func _ready():
	add_to_group("units")
	current_health = max_health
	configure_collision_behavior()
	update_label()
	apply_healthbar_color()
	
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
	
	# Play damage sound
	_play_damage_sound()
	
	health_changed.emit(current_health, max_health)
	update_label()
	
	if current_health <= 0:
		die()

func _play_damage_sound() -> void:
	var damage_sfx = AudioStreamPlayer2D.new()
	damage_sfx.stream = load("res://data/audio/sfx/458867__raclure__damage-sound-effect.mp3")
	if damage_sfx.stream == null:
		return
	damage_sfx.bus = "SFX"
	damage_sfx.volume_db = -33.0
	damage_sfx.max_distance = 800.0  # Sound inaudible beyond 800 pixels
	damage_sfx.attenuation = 2  # Logarithmic attenuation
	damage_sfx.global_position = global_position
	add_child(damage_sfx)
	damage_sfx.play()
	await damage_sfx.finished
	damage_sfx.queue_free()

func update_label() -> void:
	if info_label != null:
		info_label.text = unit_name

	if health_bar != null:
		health_bar.max_value = max_health
		health_bar.value = current_health

func apply_healthbar_color() -> void:
	if health_bar == null:
		return

	var fill_style := StyleBoxFlat.new()
	var background_style := StyleBoxFlat.new()

	# Player/enemy colors
	if team == "player":
		fill_style.bg_color = Color(0.1, 0.9, 0.2, 0.75)
	else:
		fill_style.bg_color = Color(0.9, 0.1, 0.1, 0.75)

	# Transparent dark background
	background_style.bg_color = Color(0.0, 0.0, 0.0, 0.25)

	health_bar.add_theme_stylebox_override("fill", fill_style)
	health_bar.add_theme_stylebox_override("background", background_style)
	fill_style.border_width_left = 1
	fill_style.border_width_right = 1
	fill_style.border_width_top = 1
	fill_style.border_width_bottom = 1

	fill_style.border_color = Color.BLACK

func die() -> void:
	died.emit(self)
	queue_free()
