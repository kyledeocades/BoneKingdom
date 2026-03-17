extends Node2D

@onready var game_state = $GameState
@onready var unit_catalog = $UnitCatalog
@onready var bones_label = $UI/BonesLabel
@onready var result_label = $UI/ResultLabel
@onready var spawn_buttons = $UI/SpawnButtons
@onready var player_spawn = $PlayerSpawn
@onready var enemy_spawn = $EnemySpawn
@onready var unit_scene = preload("res://scenes/units/Unit.tscn")

func _ready():
	game_state.bones_changed.connect(_on_bones_changed)
	game_state.result_changed.connect(_on_result_changed)
	_on_bones_changed(game_state.bones)
	_on_result_changed(game_state.result_text, game_state.game_over)
	build_spawn_buttons()
	start_enemy_spawn_loop()

func _process(_delta):
	if game_state.game_over:
		return
	
	check_win_loss()

func add_bones(amount: int):
	game_state.add_bones(amount)

func add_enemy_bones(amount: int):
	game_state.add_enemy_bones(amount)

func _on_bones_changed(new_bones: int):
	bones_label.text = "Bones: " + str(new_bones)

func _on_result_changed(new_text: String, is_visible: bool):
	result_label.text = new_text
	result_label.visible = is_visible

func build_spawn_buttons():
	for child in spawn_buttons.get_children():
		child.queue_free()

	for stats in unit_catalog.get_player_spawn_units():
		var button = Button.new()
		button.text = "%s (%d)" % [stats.player_name, stats.cost]
		button.pressed.connect(_on_spawn_unit_button_pressed.bind(stats.unit_id))
		spawn_buttons.add_child(button)

func _on_spawn_unit_button_pressed(unit_id: String):
	spawn_player_unit(unit_id)

func spawn_player_unit(unit_type: String):
	if game_state.game_over:
		return

	var stats = unit_catalog.get_stats(unit_type)
	if stats == null:
		return
	
	if not game_state.try_spend_bones(stats.cost):
		return
	
	var unit = unit_scene.instantiate()
	setup_unit(unit, stats, "player")
	unit.global_position = player_spawn.global_position
	add_child(unit)

func spawn_enemy_unit(unit_type: String):
	if game_state.game_over:
		return

	var stats = unit_catalog.get_stats(unit_type)
	if stats == null:
		return
	
	if not game_state.try_spend_enemy_bones(stats.cost):
		return
	
	var unit = unit_scene.instantiate()
	setup_unit(unit, stats, "enemy")
	unit.global_position = enemy_spawn.global_position
	add_child(unit)

func setup_unit(unit, stats: UnitTypeStats, team: String):
	unit.team = team
	unit.unit_name = stats.player_name if team == "player" else stats.enemy_name
	unit.max_health = stats.max_health
	unit.current_health = stats.max_health
	unit.damage = stats.damage
	unit.move_speed = stats.move_speed
	unit.attack_range = stats.attack_range
	unit.attack_cooldown = stats.attack_cooldown
	unit.is_worker = stats.is_worker
	unit.gather_rate = stats.gather_rate
	unit.gather_cooldown = stats.gather_cooldown
	
	unit.update_label()

func start_enemy_spawn_loop():
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(_on_enemy_spawn_timer_timeout)
	add_child(timer)

func _on_enemy_spawn_timer_timeout():
	if game_state.game_over:
		return

	var worker_id = get_affordable_enemy_worker_unit_id()
	if count_enemy_workers() < 2 and not worker_id.is_empty():
		spawn_enemy_unit(worker_id)
		return

	var combat_id = get_random_affordable_enemy_combat_unit_id()
	if not combat_id.is_empty():
		spawn_enemy_unit(combat_id)

func get_affordable_enemy_worker_unit_id() -> String:
	var selected: UnitTypeStats = null
	for stats in unit_catalog.get_enemy_ai_units():
		if not stats.is_worker:
			continue
		if stats.cost > game_state.enemy_bones:
			continue
		if selected == null or stats.cost < selected.cost:
			selected = stats

	return "" if selected == null else selected.unit_id

func get_random_affordable_enemy_combat_unit_id() -> String:
	var affordable: Array[String] = []
	for stats in unit_catalog.get_enemy_ai_units():
		if stats.is_worker:
			continue
		if stats.cost <= game_state.enemy_bones:
			affordable.append(stats.unit_id)

	if affordable.is_empty():
		return ""

	return affordable[randi() % affordable.size()]

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
		game_state.set_game_result("YOU WIN")
	elif player_base == null:
		game_state.set_game_result("YOU LOSE")
