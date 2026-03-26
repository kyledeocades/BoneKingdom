extends Node

class_name CameraController

@export var camera_path: NodePath
@export var left_anchor_path: NodePath
@export var right_anchor_path: NodePath

@export var move_speed: float = 500.0
@export var drag_sensitivity: float = 1.0
@export var min_margin: float = 80.0
@export var max_margin: float = 80.0

var is_dragging: bool = false

@onready var camera: Camera2D = get_node_or_null(camera_path)
@onready var left_anchor: Node2D = get_node_or_null(left_anchor_path)
@onready var right_anchor: Node2D = get_node_or_null(right_anchor_path)

func _process(delta: float):
	handle_keyboard(delta)

func _unhandled_input(event):
	if camera == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_dragging = event.pressed
	elif event is InputEventMouseMotion and is_dragging:
		move_camera_by(-event.relative.x * drag_sensitivity)
	elif event is InputEventScreenTouch:
		is_dragging = event.pressed
	elif event is InputEventScreenDrag:
		move_camera_by(-event.relative.x * drag_sensitivity)

func handle_keyboard(delta: float):
	if camera == null:
		return

	var direction := 0.0

	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction += 1.0

	if direction != 0.0:
		move_camera_by(direction * move_speed * delta)

func move_camera_by(amount: float):
	if camera == null or left_anchor == null or right_anchor == null:
		return

	var min_x = left_anchor.global_position.x - min_margin
	var max_x = right_anchor.global_position.x + max_margin

	if min_x > max_x:
		var center = (min_x + max_x) * 0.5
		min_x = center
		max_x = center

	camera.global_position.x = clamp(camera.global_position.x + amount, min_x, max_x)
