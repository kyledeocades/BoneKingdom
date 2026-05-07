extends Node2D
## Main game controller
## Orchestrates all game systems and managers

class_name GameController

# ── Overlay scripts ─────────────────────────────────────────────────────────
# ⚠ Adjust these paths to match where you placed the UI scripts
const PauseMenuScript    = preload("res://scripts/ui/PauseMenu.gd")
const ResultOverlayScript = preload("res://scripts/ui/GameResultOverlay.gd")

# ── Stage selection (set by StageSelectScreen before changing scene) ──────────
static var selected_stage_id: String = "default"

var _game_state: Node
var _event_bus: Node
var _spawn_manager: Node
var _unit_manager: Node
var _ui_controller: Node
var _unit_catalog: Node
var _stage_manager: Node
var _enemy_spawn_timer: Timer

var _pause_menu: PauseMenu
var _result_overlay: GameResultOverlay

var _stage_config: StageConfig

# Track cooldowns for each unit type
var _unit_cooldowns: Dictionary = {}  # unit_id -> time remaining

func _ready():
	add_to_group("main")
	
	# Get all system references
	_game_state = $GameState
	_event_bus = $GameEventBus
	_spawn_manager = $SpawnManager
	_unit_manager = $UnitManager
	_ui_controller = $UIController
	_unit_catalog = $UnitCatalog
	_stage_manager = $StageManager
	
	# Validate systems
	assert(_game_state != null, "GameState not found")
	assert(_event_bus != null, "GameEventBus not found")
	assert(_spawn_manager != null, "SpawnManager not found")
	assert(_unit_manager != null, "UnitManager not found")
	assert(_ui_controller != null, "UIController not found")
	assert(_unit_catalog != null, "UnitCatalog not found")
	assert(_stage_manager != null, "StageManager not found")
	
	# Spawn UI overlays
	_setup_overlays()
	
	# Wait for all child systems to initialize
	await get_tree().process_frame
	
	# Load and apply selected stage (default or user-selected)
	if not _stage_manager.load_and_apply_stage(selected_stage_id):
		push_error("Failed to load stage: %s" % selected_stage_id)
	
	_stage_config = _stage_manager.get_current_stage()
	assert(_stage_config != null, "Stage config not loaded")
	
	# Initialize game state with stage-specific resources
	_game_state.starting_bones = _stage_config.starting_player_resources
	_game_state.starting_enemy_bones = _stage_config.starting_enemy_resources
	_game_state.bones = _stage_config.starting_player_resources
	_game_state.enemy_bones = _stage_config.starting_enemy_resources
	_game_state.bones_changed.emit(_game_state.bones)
	_game_state.enemy_bones_changed.emit(_game_state.enemy_bones)
	
	# Apply separate resource rates for player and enemy
	_spawn_manager.set_player_resource_rate(_stage_config.player_resource_rate)
	_spawn_manager.set_enemy_resource_rate(_stage_config.enemy_resource_rate)
	
	# Setup UI with allowed units from stage
	#print("DEBUG: Building spawn buttons...")
	#print("DEBUG: Starting bones: ", _game_state.bones)
	var units = _unit_catalog.get_player_spawn_units()
	#print("DEBUG: Available player units: ", units.size())
	for u in units:
		print("  - ", u.unit_id, " (cost: ", u.cost, ")")
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

func _process(delta):
	if _game_state.game_over:
		return
	
	# Update cooldowns
	for unit_id in _unit_cooldowns.keys():
		_unit_cooldowns[unit_id] -= delta
		if _unit_cooldowns[unit_id] <= 0:
			_unit_cooldowns.erase(unit_id)
	
	check_win_loss_condition()

## Spawn the pause and result overlay CanvasLayers as children
func _setup_overlays() -> void:
	_pause_menu = PauseMenuScript.new()
	add_child(_pause_menu)
	
	_result_overlay = ResultOverlayScript.new()
	add_child(_result_overlay)

## ESC key toggles pause menu (but not once game is over)
## Ctrl+Shift+B adds 500 bones (debug cheat)
func _unhandled_input(event: InputEvent) -> void:
	# Debug: Ctrl+Shift+B adds 500 bones
	if event is InputEventKey and event.pressed and event.ctrl_pressed and event.shift_pressed and event.keycode == KEY_B:
		_game_state.add_bones(500)
		print("Debug: Added 500 bones! Total: ", _game_state.bones)
		get_tree().root.set_input_as_handled()
		return
	
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
	
	# Check if unit is on cooldown
	if _unit_cooldowns.has(unit_id):
		return
	
	var stats = _unit_catalog.get_stats(unit_id)
	if stats == null:
		return
	
	if not _game_state.try_spend_bones(stats.cost):
		return
	
	_spawn_manager.spawn_player_unit(unit_id)
	
	# Start cooldown
	_unit_cooldowns[unit_id] = stats.spawn_cooldown

## Handle bone earning for enemies and players
func _on_bones_earned(amount: int, team: String) -> void:
	if team == "player":
		_game_state.add_bones(amount)
	else:
		_game_state.add_enemy_bones(amount)

## Handle unit death for tracking
func _on_unit_died(_unit: Node, _team: String) -> void:
	pass

## Mine interactions
## Upgrade the player mine by one tier. Cost scales with current tier.
func upgrade_player_mine() -> void:
	var mine = get_node_or_null("PlayerMine")
	if mine == null:
		return
	if mine.current_tier >= mine.max_tier:
		print("Mine already at max tier!")
		return
	var upgrade_cost: int = 100 * mine.current_tier
	if _game_state.try_spend_bones(upgrade_cost):
		mine.upgrade()
		print("Mine upgraded to tier ", mine.current_tier, " (cost ", upgrade_cost, " bones)")
	else:
		print("Not enough bones to upgrade mine! Need ", upgrade_cost)
 
## Repair the player mine back to full HP and clear depleted state.
func repair_player_mine() -> void:
	var mine = get_node_or_null("PlayerMine")
	if mine == null:
		return
	var repair_cost: int = 50
	if _game_state.try_spend_bones(repair_cost):
		mine.repair()
		print("Mine repaired!")
	else:
		print("Not enough bones to repair mine! Need ", repair_cost)
 
## Button callbacks for mine UI buttons
func _on_upgrade_mine_button_pressed() -> void:
	upgrade_player_mine()
 
func _on_repair_mine_button_pressed() -> void:
	repair_player_mine()

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
	
	match _stage_config.enemy_ai_mode:
		"aggressive":
			_on_enemy_spawn_timer_tick_aggressive()
		"economical":
			_on_enemy_spawn_timer_tick_economical()
		"smart":
			_on_enemy_spawn_timer_tick_smart()
		_:  # default to "random"
			_on_enemy_spawn_timer_tick_random()

## Random AI: Cheapest worker if count < 2, otherwise random combat unit
func _on_enemy_spawn_timer_tick_random() -> void:
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

## Smart AI: Dynamic timing, threat assessment, resource thresholds, composition strategy
func _on_enemy_spawn_timer_tick_smart() -> void:
	# Evaluate threat level (are player units near enemy base/mine?)
	var threat_level = _evaluate_player_threat()
	
	# Adjust spawn timer based on threat and resources
	var base_spawn_interval = 3.0
	if threat_level > 0.7:
		base_spawn_interval = 2.0  # Spawn faster under high threat
	elif _game_state.enemy_bones > 1000:
		base_spawn_interval = 2.5  # Spawn faster when rich
	elif _game_state.enemy_bones < 200:
		base_spawn_interval = 4.0  # Spawn slower when poor
	
	_enemy_spawn_timer.wait_time = base_spawn_interval
	
	# Under threat: prioritize combat units
	if threat_level > 0.7:
		var defensive_combat_id = get_best_defensive_combat_unit_id()
		if not defensive_combat_id.is_empty():
			var stats = _unit_catalog.get_stats(defensive_combat_id)
			if _game_state.try_spend_enemy_bones(stats.cost):
				_spawn_manager.spawn_enemy_unit(defensive_combat_id)
		return
	
	# Normal operation: balance workers and combat units
	var worker_count = _unit_manager.count_workers("enemy")
	
	# Maintain worker count (2-3 workers for good economy)
	if worker_count < 5:
		var worker_id = get_affordable_enemy_worker_unit_id()
		if not worker_id.is_empty():
			var worker_stats = _unit_catalog.get_stats(worker_id)
			# Only spawn worker if we have resource buffer for combat
			if _game_state.enemy_bones >= worker_stats.cost + 200:
				if _game_state.try_spend_enemy_bones(worker_stats.cost):
					_spawn_manager.spawn_enemy_unit(worker_id)
				return
	
	# Resource threshold: only spawn combat when we can afford it with buffer
	var combat_id = get_best_affordable_combat_unit_id()
	if not combat_id.is_empty():
		var stats = _unit_catalog.get_stats(combat_id)
		var min_threshold = maxi(300, stats.cost + 100)
		if _game_state.enemy_bones >= min_threshold:
			if _game_state.try_spend_enemy_bones(stats.cost):
				_spawn_manager.spawn_enemy_unit(combat_id)

## Evaluate threat: how close are player units to enemy base/mine?
func _evaluate_player_threat() -> float:
	var enemy_base = get_node_or_null("EnemyBase")
	var enemy_mine = get_node_or_null("EnemyMine")
	
	if enemy_base == null:
		return 0.0
	
	var threat = 0.0
	var player_combat = _unit_manager.get_combat_units("player")
	
	for unit in player_combat:
		var dist_to_base = unit.global_position.distance_to(enemy_base.global_position)
		var dist_to_mine = 99999.0
		if enemy_mine != null:
			dist_to_mine = unit.global_position.distance_to(enemy_mine.global_position)
		
		# Units within 500 pixels of base/mine are a threat
		var threat_range = 500.0
		if dist_to_base < threat_range:
			threat += 1.0 - (dist_to_base / threat_range)
		if enemy_mine != null and dist_to_mine < threat_range:
			threat += 0.5 * (1.0 - (dist_to_mine / threat_range))
	
	# Normalize threat level (0.0 to 1.0)
	return minf(threat / maxf(_unit_manager.count_combat_units("player"), 1), 1.0)

## Aggressive AI: Spawns frequently to secure map control and pressure player
func _on_enemy_spawn_timer_tick_aggressive() -> void:
	# Fast spawn rate (2.0-2.5s) to maintain pressure
	_enemy_spawn_timer.wait_time = 2.0 if _game_state.enemy_bones > 600 else 2.5
	
	# Get enemy map control ratio
	var control_ratio = _calculate_enemy_map_control()
	
	# If controlling less than 50% of map, spawn combat aggressively
	if control_ratio < 0.5:
		# Prioritize spawning combat units
		var combat_id = get_random_affordable_enemy_combat_unit_id()
		if not combat_id.is_empty():
			var stats = _unit_catalog.get_stats(combat_id)
			if _game_state.try_spend_enemy_bones(stats.cost):
				_spawn_manager.spawn_enemy_unit(combat_id)
			return
	
	# If economy is stable, maintain minimum workers
	var worker_count = _unit_manager.count_workers("enemy")
	if worker_count < 2 and _game_state.enemy_bones > 300:
		var worker_id = get_affordable_enemy_worker_unit_id()
		if not worker_id.is_empty():
			if _game_state.try_spend_enemy_bones(_unit_catalog.get_stats(worker_id).cost):
				_spawn_manager.spawn_enemy_unit(worker_id)
			return
	
	# Otherwise spawn any affordable combat unit
	var combat_id = get_random_affordable_enemy_combat_unit_id()
	if not combat_id.is_empty():
		var stats = _unit_catalog.get_stats(combat_id)
		if _game_state.try_spend_enemy_bones(stats.cost):
			_spawn_manager.spawn_enemy_unit(combat_id)

## Economical AI: Focuses on economy, saves for waves when player pushes
func _on_enemy_spawn_timer_tick_economical() -> void:
	# Detect if player is sending a wave (multiple units moving toward enemy)
	var player_wave_incoming = _detect_player_wave()
	
	# Adjust spawn rate
	var base_spawn_interval = 4.0  # Default: slow spawn rate
	if player_wave_incoming:
		base_spawn_interval = 2.0  # Fast response to player wave
	elif _game_state.enemy_bones > 1200:
		base_spawn_interval = 2.5  # Spawn faster when very rich
	
	_enemy_spawn_timer.wait_time = base_spawn_interval
	
	# If wave incoming: spawn combat units to defend
	if player_wave_incoming:
		var combat_id = get_best_defensive_combat_unit_id()
		if not combat_id.is_empty():
			var stats = _unit_catalog.get_stats(combat_id)
			if _game_state.try_spend_enemy_bones(stats.cost):
				_spawn_manager.spawn_enemy_unit(combat_id)
		return
	
	# Normal economy mode: prioritize workers
	var worker_count = _unit_manager.count_workers("enemy")
	if worker_count < 4 and _game_state.enemy_bones < 1000:
		var worker_id = get_affordable_enemy_worker_unit_id()
		if not worker_id.is_empty():
			var worker_stats = _unit_catalog.get_stats(worker_id)
			# Spawn worker if not saving for a combat push
			if _game_state.enemy_bones >= worker_stats.cost + 150:
				if _game_state.try_spend_enemy_bones(worker_stats.cost):
					_spawn_manager.spawn_enemy_unit(worker_id)
				return
	
	# When bones accumulate past threshold, release a wave
	if _game_state.enemy_bones > 1200:
		var combat_id = get_best_affordable_combat_unit_id()
		if not combat_id.is_empty():
			if _game_state.try_spend_enemy_bones(_unit_catalog.get_stats(combat_id).cost):
				_spawn_manager.spawn_enemy_unit(combat_id)

## Calculate what % of the map is controlled by enemy (units past center)
func _calculate_enemy_map_control() -> float:
	var enemy_units = _unit_manager.get_combat_units("enemy")
	if enemy_units.is_empty():
		return 0.0
	
	var center_x = 0.0  # Map center X (considering bases are symmetric)
	var units_past_center = 0
	
	for unit in enemy_units:
		if unit.global_position.x > center_x:
			units_past_center += 1
	
	return float(units_past_center) / enemy_units.size()

## Detect if player is sending a wave (4+ combat units moving toward enemy, past center)
func _detect_player_wave() -> bool:
	var player_combat = _unit_manager.get_combat_units("player")
	if player_combat.size() < 4:
		return false
	
	var center_x = 0.0
	var units_past_center = 0
	
	for unit in player_combat:
		# Only count units moving toward enemy (positive X direction)
		if unit.global_position.x > center_x:
			units_past_center += 1
	
	# Wave detected if at least 50% of combat units are past center moving toward enemy
	return units_past_center >= int(ceil(player_combat.size() * 0.5))


## Get cheapest affordable combat unit (for smart mode)
func get_best_affordable_combat_unit_id() -> String:
	var best = null
	for stats in _unit_catalog.get_enemy_ai_units():
		if stats.is_worker:
			continue
		if stats.cost > _game_state.enemy_bones:
			continue
		if best == null or stats.cost < best.cost:
			best = stats
	return "" if best == null else best.unit_id

## Get best defensive unit (highest damage for the cost)
func get_best_defensive_combat_unit_id() -> String:
	var best = null
	var best_dps = 0.0
	for stats in _unit_catalog.get_enemy_ai_units():
		if stats.is_worker:
			continue
		if stats.cost > _game_state.enemy_bones:
			continue
		# Prioritize by damage-per-cost ratio
		var dps = float(stats.damage) / stats.cost
		if best == null or dps > best_dps:
			best = stats
			best_dps = dps
	return "" if best == null else best.unit_id

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

## Get remaining cooldown for a unit type
func get_unit_cooldown(unit_id: String) -> float:
	return _unit_cooldowns.get(unit_id, 0.0)
