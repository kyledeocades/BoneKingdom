extends Node
## Manages stage loading, initialization, and configuration
## Applies StageConfig settings to the game scene

class_name StageManager

const STAGE_DIR: String = "res://data/stages"

var _current_stage: StageConfig
var _main_controller: Node2D


func _ready():
	add_to_group("stage_manager")
	
	_main_controller = get_tree().get_first_node_in_group("main")
	
	if _main_controller == null:
		push_error("StageManager: Main controller not found in 'main' group")


## Load a stage by ID and apply it to the game
func load_and_apply_stage(stage_id: String) -> bool:
	var stage = load_stage(stage_id)
	if stage == null:
		push_error("Failed to load stage: %s" % stage_id)
		return false
	
	_current_stage = stage
	apply_stage_config(stage)
	return true


## Load a stage resource by ID (looks for stage_{id}.tres)
func load_stage(stage_id: String) -> StageConfig:
	var path = "%s/stage_%s.tres" % [STAGE_DIR, stage_id]
	var stage = load(path)
	
	if stage == null or not stage is StageConfig:
		push_error("Stage not found or invalid: %s" % path)
		return null
	
	return stage


## Apply all stage config settings to the scene
func apply_stage_config(config: StageConfig) -> void:
	if _main_controller == null:
		push_error("Cannot apply stage config: Main controller not found")
		return
	
	_apply_background(config)
	_apply_spawn_positions(config)
	_apply_mine_positions(config)
	_apply_base_positions(config)
	_apply_camera_bounds(config)
	_apply_scrollbar_bounds(config)
	_apply_economy_settings(config)
	_apply_unit_restrictions(config)
	
	print("Stage loaded: %s (%s)" % [config.stage_name, config.stage_id])


## Update background texture
func _apply_background(config: StageConfig) -> void:
	var background = _main_controller.get_node_or_null("Background")
	if background == null:
		push_warning("Background node not found")
		return
	
	var texture = load(config.background_path)
	if texture == null:
		push_warning("Background texture not found: %s" % config.background_path)
		return
	
	background.texture = texture


## Update spawn positions based on base_distance
func _apply_spawn_positions(config: StageConfig) -> void:
	var positions = config.calculate_positions(500.0)  # Y position from current Main.tscn
	
	var player_spawn = _main_controller.get_node_or_null("PlayerSpawn")
	var enemy_spawn = _main_controller.get_node_or_null("EnemySpawn")
	
	if player_spawn:
		player_spawn.global_position = positions["player_base"]
	else:
		push_warning("PlayerSpawn marker not found")
	
	if enemy_spawn:
		enemy_spawn.global_position = positions["enemy_base"]
	else:
		push_warning("EnemySpawn marker not found")


## Update mine positions based on mine_distance
func _apply_mine_positions(config: StageConfig) -> void:
	var positions = config.calculate_positions(500.0)
	
	var player_mine = _main_controller.get_node_or_null("PlayerMine")
	var enemy_mine = _main_controller.get_node_or_null("EnemyMine")
	
	if player_mine:
		player_mine.global_position = positions["player_mine"]
	else:
		push_warning("PlayerMine marker not found")
	
	if enemy_mine:
		enemy_mine.global_position = positions["enemy_mine"]
	else:
		push_warning("EnemyMine marker not found")


## Update base positions based on base_distance
func _apply_base_positions(config: StageConfig) -> void:
	var positions = config.calculate_positions(500.0)
	
	var player_base = _main_controller.get_node_or_null("PlayerBase")
	var enemy_base = _main_controller.get_node_or_null("EnemyBase")
	
	if player_base:
		player_base.global_position = positions["player_base"]
	else:
		push_warning("PlayerBase node not found")
	
	if enemy_base:
		enemy_base.global_position = positions["enemy_base"]
	else:
		push_warning("EnemyBase node not found")


## Update camera bounds based on base distance
func _apply_camera_bounds(config: StageConfig) -> void:
	var camera_controller = _main_controller.get_node_or_null("CameraController")
	if camera_controller == null or not camera_controller.has_method("set_bounds_from_base_distance"):
		push_warning("CameraController not found or missing set_bounds_from_base_distance method")
		return
	
	camera_controller.set_bounds_from_base_distance(config.base_distance)


## Update scrollbar bounds based on stage size
func _apply_scrollbar_bounds(config: StageConfig) -> void:
	var battle_scrollbar = _main_controller.find_child("BattleScrollbar")
	if battle_scrollbar == null or not battle_scrollbar.has_method("set_stage_bounds"):
		push_warning("BattleScrollbar not found or missing set_stage_bounds method")
		return
	
	battle_scrollbar.set_stage_bounds(config)


## Apply economy settings (starting resources, spawn cooldown, resource rate)
func _apply_economy_settings(config: StageConfig) -> void:
	var game_state = _main_controller.get_node_or_null("GameState")
	if game_state == null:
		push_warning("GameState not found")
		return
	
	# Set starting resources
	game_state.bones = config.starting_resources
	game_state.enemy_bones = config.starting_resources
	
	# Store stage config reference in GameController for other systems to access
	if _main_controller.has_meta("stage_config"):
		_main_controller.set_meta("stage_config", config)
	else:
		_main_controller.set_meta("stage_config", config)


## Apply unit restrictions to UnitCatalog
func _apply_unit_restrictions(config: StageConfig) -> void:
	var unit_catalog = _main_controller.get_node_or_null("UnitCatalog")
	if unit_catalog == null:
		push_warning("UnitCatalog not found")
		return
	
	# Set allowed units (UnitCatalog will handle filtering)
	if unit_catalog.has_method("set_stage_restrictions"):
		unit_catalog.set_stage_restrictions(
			config.get_allowed_player_units_resolved(),
			config.get_allowed_enemy_units_resolved()
		)


## Get current stage config
func get_current_stage() -> StageConfig:
	return _current_stage


## List all available stages
func list_available_stages() -> Array[String]:
	var stages: Array[String] = []
	var dir = DirAccess.open(STAGE_DIR)
	
	if dir == null:
		push_warning("Stages directory not found: %s" % STAGE_DIR)
		return stages
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.starts_with("stage_") and file_name.ends_with(".tres"):
			var stage_id = file_name.trim_suffix(".tres").trim_prefix("stage_")
			stages.append(stage_id)
		file_name = dir.get_next()
	
	return stages
