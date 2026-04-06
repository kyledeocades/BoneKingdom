extends Node2D
## Main game controller
## Orchestrates all game systems and managers

class_name GameController

# ── Overlay scripts ─────────────────────────────────────────────────────────
# ⚠ Adjust these paths to match where you placed the UI scripts
const PauseMenuScript    = preload("res://scripts/ui/PauseMenu.gd")
const ResultOverlayScript = preload("res://scripts/ui/GameResultOverlay.gd")

var _game_state: Node
var _event_bus: Node
var _spawn_manager: Node
var _unit_manager: Node
var _ui_controller: Node
var _unit_catalog: Node
var _enemy_spawn_timer: Timer

var _pause_menu: PauseMenu
var _result_overlay: GameResultOverlay

func _ready():
	add_to_group("main")
	
	# Get all system references
	_game_state = $GameState
	_event_bus = $GameEventBus
	_spawn_manager = $SpawnManager
	_unit_manager = $UnitManager
	_ui_controller = $UIController
	_unit_catalog = $UnitCatalog
	
	# Validate systems
	assert(_game_state != null, "GameState not found")
	assert(_event_bus != null, "GameEventBus not found")
	assert(_spawn_manager != null, "SpawnManager not found")
	assert(_unit_manager != null, "UnitManager not found")
	assert(_ui_controller != null, "UIController not found")
	assert(_unit_catalog != null, "UnitCatalog not found")
	
	# Spawn UI overlays
	_setup_overlays()
	
	# Wait for all child systems to initialize
	await get_tree().process_frame
	
	# Setup UI
	_ui_controller.build_spawn_buttons(_on_player_spawn_button_pressed)
	
	# Subscribe to events
	_event_bus.bones_earned.connect(_on_bones_earned)
	_event_bus.unit_died.connect(_on_unit_died)
	_event_bus.win_condition_met.connect(_on_win_condition_met)
	_event_bus.lose_condition_met.connect(_on_lose_condition_met)
	
	# Start enemy AI
	start_enemy_spawn_loop()
	
	# Emit game started
	_event_bus.game_started.emit()

func _process(_delta):
	if _game_state.game_over:
		return
	
	check_win_loss_condition()

## Spawn the pause and result overlay CanvasLayers as children
func _setup_overlays() -> void:
	_pause_menu = PauseMenuScript.new()
	add_child(_pause_menu)
	
	_result_overlay = ResultOverlayScript.new()
	add_child(_result_overlay)

## ESC key toggles pause menu (but not once game is over)
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _game_state.game_over:
		return
	if _pause_menu.visible:
		_pause_menu.close()
	else:
		_pause_menu.open()

## Win condition: show victory overlay
func _on_win_condition_met(_reason: String) -> void:
	_result_overlay.show_result("YOU WIN")

## Lose condition: show defeat overlay
func _on_lose_condition_met(_reason: String) -> void:
	_result_overlay.show_result("YOU LOSE")

## Play spawns a unit when button pressed
func _on_player_spawn_button_pressed(unit_id: String) -> void:
	if _game_state.game_over:
		return
	
	var stats = _unit_catalog.get_stats(unit_id)
	if stats == null:
		return
	
	if not _game_state.try_spend_bones(stats.cost):
		return
	
	_spawn_manager.spawn_player_unit(unit_id)

## Handle bone earning for enemies and players
func _on_bones_earned(amount: int, team: String) -> void:
	if team == "player":
		_game_state.add_bones(amount)
	else:
		_game_state.add_enemy_bones(amount)

## Handle unit death for tracking
func _on_unit_died(_unit: Node, _team: String) -> void:
	pass

## Enemy AI spawn logic
func start_enemy_spawn_loop() -> void:
	_enemy_spawn_timer = Timer.new()
	_enemy_spawn_timer.wait_time = 3.0
	_enemy_spawn_timer.timeout.connect(_on_enemy_spawn_timer_tick)
	add_child(_enemy_spawn_timer)
	_enemy_spawn_timer.start()

func _on_enemy_spawn_timer_tick() -> void:
	if _game_state.game_over:
		return
	
	var worker_id = get_affordable_enemy_worker_unit_id()
	if _unit_manager.count_workers("enemy") < 2 and not worker_id.is_empty():
		if _game_state.try_spend_enemy_bones(_unit_catalog.get_stats(worker_id).cost):
			_spawn_manager.spawn_enemy_unit(worker_id)
		return
	
	var combat_id = get_random_affordable_enemy_combat_unit_id()
	if not combat_id.is_empty():
		var stats = _unit_catalog.get_stats(combat_id)
		if _game_state.try_spend_enemy_bones(stats.cost):
			_spawn_manager.spawn_enemy_unit(combat_id)

func get_affordable_enemy_worker_unit_id() -> String:
	var selected = null
	for stats in _unit_catalog.get_enemy_ai_units():
		if not stats.is_worker:
			continue
		if stats.cost > _game_state.enemy_bones:
			continue
		if selected == null or stats.cost < selected.cost:
			selected = stats
	return "" if selected == null else selected.unit_id

func get_random_affordable_enemy_combat_unit_id() -> String:
	var affordable: Array[String] = []
	for stats in _unit_catalog.get_enemy_ai_units():
		if stats.is_worker:
			continue
		if stats.cost <= _game_state.enemy_bones:
			affordable.append(stats.unit_id)
	if affordable.is_empty():
		return ""
	return affordable[randi() % affordable.size()]

func check_win_loss_condition() -> void:
	var player_base = get_node_or_null("PlayerBase")
	var enemy_base = get_node_or_null("EnemyBase")
	
	if enemy_base == null:
		_game_state.set_game_result("YOU WIN")
		_event_bus.win_condition_met.emit("Enemy base destroyed")
	elif player_base == null:
		_game_state.set_game_result("YOU LOSE")
		_event_bus.lose_condition_met.emit("Your base destroyed")

## Forwarding methods for backward compatibility
func add_bones(amount: int) -> void:
	_game_state.add_bones(amount)

func add_enemy_bones(amount: int) -> void:
	_game_state.add_enemy_bones(amount)
