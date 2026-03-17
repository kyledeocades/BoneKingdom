extends Node

signal bones_changed(new_bones: int)
signal enemy_bones_changed(new_bones: int)
signal result_changed(new_text: String, is_visible: bool)

@export var starting_bones: int = 500
@export var starting_enemy_bones: int = 500

var bones: int
var enemy_bones: int
var game_over: bool = false
var result_text: String = ""

func _ready():
	bones = starting_bones
	enemy_bones = starting_enemy_bones
	bones_changed.emit(bones)
	enemy_bones_changed.emit(enemy_bones)
	result_changed.emit("", false)

func add_bones(amount: int):
	bones += amount
	bones_changed.emit(bones)

func add_enemy_bones(amount: int):
	enemy_bones += amount
	enemy_bones_changed.emit(enemy_bones)

func try_spend_bones(cost: int) -> bool:
	if bones < cost:
		return false
	bones -= cost
	bones_changed.emit(bones)
	return true

func try_spend_enemy_bones(cost: int) -> bool:
	if enemy_bones < cost:
		return false
	enemy_bones -= cost
	enemy_bones_changed.emit(enemy_bones)
	return true

func set_game_result(text: String):
	game_over = true
	result_text = text
	result_changed.emit(result_text, true)
