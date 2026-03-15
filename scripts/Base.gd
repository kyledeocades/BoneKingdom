extends CharacterBody2D

@export var max_health: int = 500
@export var team: String = "player"

var current_health: int

@onready var hp_label = $Label

func _ready():
	current_health = max_health
	update_label()

func take_damage(amount: int):
	current_health -= amount
	
	if current_health < 0:
		current_health = 0
	
	update_label()
	
	if current_health <= 0:
		die()

func update_label():
	hp_label.text = team + " Base HP: " + str(current_health)

func die():
	queue_free()
