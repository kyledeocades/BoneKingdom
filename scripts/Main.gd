extends Node2D

var bones: int = 100
var enemy_bones: int = 100
var game_over: bool = false

@onready var bones_label = $UI/BonesLabel
@onready var result_label = $UI/ResultLabel
@onready var player_spawn = $PlayerSpawn
@onready var enemy_spawn = $EnemySpawn
@onready var unit_scene = preload("res://scenes/units/Unit.tscn")

func _ready():
	update_ui()
	start_enemy_spawn_loop()

func _process(delta):
	if game_over:
		return
	
	check_win_loss()
	update_ui()

func add_bones(amount: int):
	bones += amount
	update_ui()

func update_ui():
	bones_label.text = "Bones: " + str(bones)

func spawn_player_unit(unit_type: String):
	if game_over:
		return
	
	var cost = get_unit_cost(unit_type)
	if bones < cost:
		return
	
	bones -= cost
	
	var unit = unit_scene.instantiate()
	setup_unit(unit, unit_type, "player")
	unit.global_position = player_spawn.global_position
	add_child(unit)

func spawn_enemy_unit(unit_type: String):
	if game_over:
		return
	
	var cost = get_enemy_unit_cost(unit_type)
	if enemy_bones < cost:
		return
	
	enemy_bones -= cost
	
	var unit = unit_scene.instantiate()
	setup_unit(unit, unit_type, "enemy")
	unit.global_position = enemy_spawn.global_position
	add_child(unit)

func setup_unit(unit, unit_type: String, team: String):
	unit.team = team
	
	match unit_type:
		"collector":
			unit.unit_name = "Bone Collector" if team == "player" else "Peasant"
			unit.max_health = 50
			unit.current_health = 50
			unit.damage = 0
			unit.move_speed = 40
			unit.attack_range = 0
			unit.attack_cooldown = 1.0
			unit.is_worker = true
			unit.gather_rate = 10
			unit.gather_cooldown = 2.0
		
		"swordsman":
			unit.unit_name = "Skeleton Swordsman" if team == "player" else "Footman"
			unit.max_health = 80
			unit.current_health = 80
			unit.damage = 10
			unit.move_speed = 55
			unit.attack_range = 35
			unit.attack_cooldown = 1.0
			unit.is_worker = false
		
		"knight":
			unit.unit_name = "Skeleton Knight" if team == "player" else "Shield Guard"
			unit.max_health = 150
			unit.current_health = 150
			unit.damage = 15
			unit.move_speed = 35
			unit.attack_range = 35
			unit.attack_cooldown = 1.2
			unit.is_worker = false
		
		"catapult":
			unit.unit_name = "Skull Catapult" if team == "player" else "Archer"
			unit.max_health = 70
			unit.current_health = 70
			unit.damage = 20
			unit.move_speed = 30
			unit.attack_range = 120
			unit.attack_cooldown = 1.5
			unit.is_worker = false
	
	unit.update_label()

func get_unit_cost(unit_type: String) -> int:
	match unit_type:
		"collector":
			return 50
		"swordsman":
			return 75
		"knight":
			return 120
		"catapult":
			return 150
	return 999

func get_enemy_unit_cost(unit_type: String) -> int:
	return get_unit_cost(unit_type)

func start_enemy_spawn_loop():
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(_on_enemy_spawn_timer_timeout)
	add_child(timer)

func _on_enemy_spawn_timer_timeout():
	if game_over:
		return
	
	if enemy_bones >= 50 and count_enemy_workers() < 2:
		spawn_enemy_unit("collector")
		return
	
	var roll = randi() % 3
	
	if roll == 0 and enemy_bones >= 75:
		spawn_enemy_unit("swordsman")
	elif roll == 1 and enemy_bones >= 120:
		spawn_enemy_unit("knight")
	elif roll == 2 and enemy_bones >= 150:
		spawn_enemy_unit("catapult")

func count_enemy_workers() -> int:
	var count = 0
	
	for unit in get_tree().get_nodes_in_group("units"):
		if unit.team == "enemy" and unit.is_worker:
			count += 1
	
	return count

func check_win_loss():
	var player_base = get_node_or_null("PlayerBase")
	var enemy_base = get_node_or_null("EnemyBase")
	
	if enemy_base == null:
		game_over = true
		result_label.text = "YOU WIN"
	elif player_base == null:
		game_over = true
		result_label.text = "YOU LOSE"

func _on_spawn_collector_button_pressed():
	spawn_player_unit("collector")

func _on_spawn_swordsman_button_pressed():
	spawn_player_unit("swordsman")

func _on_spawn_knight_button_pressed():
	spawn_player_unit("knight")

func _on_spawn_catapult_button_pressed():
	spawn_player_unit("catapult")
