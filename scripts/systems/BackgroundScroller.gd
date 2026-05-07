extends Sprite2D
## Background Scroller - Anchors background to camera position
## Attaches to the Background sprite node

class_name BackgroundScroller

@onready var camera: Camera2D = get_tree().get_first_node_in_group("main").find_child("Camera2D")

func _process(_delta: float) -> void:
	if camera:
		# Follow camera position to keep background anchored to view
		global_position = camera.global_position
