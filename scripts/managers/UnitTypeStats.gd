extends Resource

@export var unit_id: String = ""
@export var player_name: String = ""
@export var enemy_name: String = ""
@export var cost: int = 50
@export var max_health: int = 100
@export var damage: int = 10
@export var move_speed: float = 50.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.0
@export var is_worker: bool = false
@export var gather_rate: int = 10
@export var gather_cooldown: float = 2.0

@export var sort_order: int = 0
@export var player_spawn_enabled: bool = true
@export var enemy_ai_enabled: bool = true
