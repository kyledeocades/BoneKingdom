extends Node
class_name UnitCatalog

@export_dir var unit_stats_dir: String = "res://data/unit_types"
@export var fallback_unit_stat_paths: Array[String] = [
	"res://data/unit_types/collector.tres",
	"res://data/unit_types/swordsman.tres",
	"res://data/unit_types/knight.tres",
	"res://data/unit_types/catapult.tres",
]

var _stats_by_id: Dictionary = {}
var _all_stats: Array = []

# Stage restrictions (empty = no restrictions)
var _allowed_player_units: Array[String] = []
var _allowed_enemy_units: Array[String] = []

func _ready():
	add_to_group("unit_catalog")
	reload_catalog()

func reload_catalog():
	_stats_by_id.clear()
	_all_stats.clear()

	var dir := DirAccess.open(unit_stats_dir)
	if dir != null:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var path = "%s/%s" % [unit_stats_dir, file_name]
				try_add_stats(path)
			file_name = dir.get_next()
		dir.list_dir_end()

	# In exported builds, res:// directory listing can return no files.
	if _all_stats.is_empty():
		for path in fallback_unit_stat_paths:
			if path.ends_with(".tres"):
				try_add_stats(path)

	if _all_stats.is_empty():
		push_warning("No unit stats could be loaded. Check UnitCatalog paths.")

	_all_stats.sort_custom(func(a, b):
		return a.sort_order < b.sort_order
	)

func try_add_stats(path: String):
	var stats = load(path)
	if stats is UnitStats and not stats.unit_id.is_empty():
		if _stats_by_id.has(stats.unit_id):
			push_warning("Duplicate unit id in catalog: %s" % stats.unit_id)
		else:
			_stats_by_id[stats.unit_id] = stats
			_all_stats.append(stats)

func get_stats(unit_id: String):
	return _stats_by_id.get(unit_id)

## Set stage unit restrictions
## Pass empty arrays to allow all units
func set_stage_restrictions(allowed_player: Array[String], allowed_enemy: Array[String]) -> void:
	_allowed_player_units = allowed_player
	_allowed_enemy_units = allowed_enemy

## Check if a unit is allowed for player
func _is_player_unit_allowed(unit_id: String) -> bool:
	if _allowed_player_units.is_empty():
		return true
	return unit_id in _allowed_player_units

## Check if a unit is allowed for enemy
func _is_enemy_unit_allowed(unit_id: String) -> bool:
	if _allowed_enemy_units.is_empty():
		return true
	return unit_id in _allowed_enemy_units

func get_player_spawn_units() -> Array:
	var units: Array = []
	for stats in _all_stats:
		if stats.player_spawn_enabled and _is_player_unit_allowed(stats.unit_id):
			units.append(stats)
	return units

func get_enemy_ai_units() -> Array:
	var units: Array = []
	for stats in _all_stats:
		if stats.enemy_ai_enabled and _is_enemy_unit_allowed(stats.unit_id):
			units.append(stats)
	return units
