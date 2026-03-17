extends Node

@export_dir var unit_stats_dir: String = "res://data/unit_types"

var _stats_by_id: Dictionary = {}
var _all_stats: Array[UnitTypeStats] = []

func _ready():
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
			if stats is UnitTypeStats and not stats.unit_id.is_empty():
				if _stats_by_id.has(stats.unit_id):
					push_warning("Duplicate unit id in catalog: %s" % stats.unit_id)
				else:
					_stats_by_id[stats.unit_id] = stats
					_all_stats.append(stats)
		file_name = dir.get_next()
	dir.list_dir_end()

	_all_stats.sort_custom(func(a: UnitTypeStats, b: UnitTypeStats):
		return a.sort_order < b.sort_order
	)

func get_stats(unit_id: String) -> UnitTypeStats:
	return _stats_by_id.get(unit_id)

func get_player_spawn_units() -> Array[UnitTypeStats]:
	var units: Array[UnitTypeStats] = []
	for stats in _all_stats:
		if stats.player_spawn_enabled:
			units.append(stats)
	return units

func get_enemy_ai_units() -> Array[UnitTypeStats]:
	var units: Array[UnitTypeStats] = []
	for stats in _all_stats:
		if stats.enemy_ai_enabled:
			units.append(stats)
	return units
