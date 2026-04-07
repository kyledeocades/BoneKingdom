extends Node2D
## Mine structure that passively generates bones into a stockpile
## Workers collect from the stockpile and ferry bones to their base
## Can be upgraded (tier 1-5) and damaged by enemy units
## Losing all HP drops a tier; losing HP at tier 1 causes depletion

class_name Mine

@export var team: String = "player"

## Bones generated per second for each tier (index 0 = tier 1 ... index 4 = tier 5)
## Defaults: 2/s, 4/s, 6/s, 8/s, 10/s = 20, 40, 60, 80, 100 bones per 10s
@export var generation_rates: Array[float] = [2.0, 4.0, 6.0, 8.0, 10.0]

@export var max_stockpile: int = 800
@export var max_health: int = 50
@export var max_tier: int = 5

var current_tier: int = 1
var current_health: int = 50
var stockpile: int = 0
var is_depleted: bool = false

var _generation_accumulator: float = 0.0

@onready var info_label = get_node_or_null("Label")

func _ready() -> void:
	current_health = max_health
	update_label()

func _process(delta: float) -> void:
	if is_depleted:
		return

	_generation_accumulator += get_current_rate() * delta
	if _generation_accumulator >= 1.0:
		var to_add: int = int(_generation_accumulator)
		stockpile = min(stockpile + to_add, max_stockpile)
		_generation_accumulator -= float(to_add)

	update_label()


## Called by workers: removes up to `amount` bones and returns how many were taken
func take_bones(amount: int) -> int:
	var taken: int = min(amount, stockpile)
	stockpile -= taken
	return taken

## Returns true if there are any bones ready to collect
func has_bones() -> bool:
	return stockpile > 0

## Returns the passive generation rate for the current tier (bones/second)
func get_current_rate() -> float:
	return generation_rates[current_tier - 1]

## Deal damage to the mine. Reduces tier on death; depletes at tier 1.
func take_damage(amount: int) -> void:
	if is_depleted:
		return

	current_health -= amount
	if current_health < 0:
		current_health = 0

	update_label()

	if current_health <= 0:
		_on_health_depleted()

## Upgrade the mine by one tier. Returns false if already at max tier.
func upgrade() -> bool:
	if current_tier >= max_tier:
		return false
	current_tier += 1
	update_label()
	return true

## Repair the mine back to full HP and clear depleted state.
func repair() -> void:
	current_health = max_health
	is_depleted = false
	update_label()


func _on_health_depleted() -> void:
	if current_tier > 1:
		current_tier -= 1
		current_health = max_health
		_generation_accumulator = 0.0
		print(team, " mine degraded to tier ", current_tier)
	else:
		# Tier 1 and out of HP — mine is depleted until repaired
		is_depleted = true
		print(team, " mine is depleted!")

	update_label()

func update_label() -> void:
	if info_label == null:
		return
	var state_str := " [DEPLETED]" if is_depleted else ""
	info_label.text = (
		team.capitalize() + " Mine" + state_str
		+ "\nTier: " + str(current_tier) + " / " + str(max_tier)
		+ "\nHP: " + str(current_health) + " / " + str(max_health)
		+ "\nStock: " + str(stockpile) + " / " + str(max_stockpile)
		+ "\nRate: " + str(get_current_rate()) + " /s"
	)
