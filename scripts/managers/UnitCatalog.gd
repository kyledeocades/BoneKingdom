extends Node

@export_dir var unit_stats_dir: String = "res://data/unit_types"

var _stats_by_id: Dictionary = {}
var _all_stats: Array = []

func _ready():
	add_to_group("unit_catalog")
	reload_catalog()

func reload_catalog():
	_stats_by_id.clear()
	_all_stats.clear()

	var dir := DirAccess.open(unit_stats_dir)
	if dir == null:
		push_warning("Unit stats directory not found: %s" % unit_stats_dir)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path = "%s/%s" % [unit_stats_dir, file_name]
			var stats = load(path)
			var unit_id = stats.get("unit_id") if stats != null else null
			if unit_id != null and str(unit_id) != "":
				if _stats_by_id.has(stats.unit_id):
					push_warning("Duplicate unit id in catalog: %s" % stats.unit_id)
				else:
					_stats_by_id[stats.unit_id] = stats
					_all_stats.append(stats)
		file_name = dir.get_next()
	dir.list_dir_end()

	_all_stats.sort_custom(func(a, b):
		return a.sort_order < b.sort_order
	)

func get_stats(unit_id: String):
	return _stats_by_id.get(unit_id)

func get_player_spawn_units() -> Array:
	var units: Array = []
	for stats in _all_stats:
		if stats.player_spawn_enabled:
			units.append(stats)
	return units

func get_enemy_ai_units() -> Array:
	var units: Array = []
	for stats in _all_stats:
		if stats.enemy_ai_enabled:
			units.append(stats)
	return units
