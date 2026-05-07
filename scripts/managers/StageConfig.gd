extends Resource
## Stage configuration resource
## Defines all parameters for a playable stage

class_name StageConfig

# ── Stage Identity ──────────────────────────────────────────────────────────
@export var stage_id: String = "stage_default"
@export var stage_name: String = "Default Stage"
@export var is_available: bool = true  # Whether this stage appears in the stage select menu

# ── Spatial Layout ──────────────────────────────────────────────────────────
## Distance from center (0,0) to each base (player at -X, enemy at +X)
@export var base_distance: float = 1600.0

## Distance from base to its respective mine (closer to center, subtracted from base_distance)
@export var mine_distance: float = 400.0

# ── Unit Allowlists ────────────────────────────────────────────────────────
## Empty array = allow all units
## "default" = allow collector, swordsman, knight, catapult
## Otherwise list specific unit IDs: ["collector", "knight"]
@export var allowed_player_units: Array[String] = []
@export var allowed_enemy_units: Array[String] = []

# ── Economy & Pacing ────────────────────────────────────────────────────────
## Initial bones both player and enemy start with
@export var starting_resources: int = 500

## Multiplier on resource gathering rate (gather_rate of workers)
@export var resource_rate: float = 1.0

# ── Visual Theme ────────────────────────────────────────────────────────────
## Path to background texture for this stage
@export var background_path: String = "res://data/backgrounds/bg_underworld.png"


# ── Helper: Get resolved unit lists ─────────────────────────────────────────
func get_allowed_player_units_resolved() -> Array[String]:
	return _resolve_unit_list(allowed_player_units)

func get_allowed_enemy_units_resolved() -> Array[String]:
	return _resolve_unit_list(allowed_enemy_units)


func _resolve_unit_list(unit_list: Array[String]) -> Array[String]:
	## Empty array means all units allowed
	if unit_list.is_empty():
		return []
	
	## Replace "default" keyword with standard set
	var result: Array[String] = []
	for unit_id in unit_list:
		if unit_id == "default":
			result.append_array(["collector", "swordsman", "knight", "catapult"])
		else:
			result.append(unit_id)
	
	return result


# ── Helper: Calculate spawn positions ───────────────────────────────────────
## Returns dictionary with symmetric base and mine positions
## Layout: [mine] [base] ... (center) ... [base] [mine]
func calculate_positions(center_y: float = 500.0) -> Dictionary:
	return {
		"player_base": Vector2(-base_distance, center_y),
		"player_mine": Vector2(-(base_distance - mine_distance), center_y),
		"enemy_base": Vector2(base_distance, center_y),
		"enemy_mine": Vector2(base_distance - mine_distance, center_y),
	}
