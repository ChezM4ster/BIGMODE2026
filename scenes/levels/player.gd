extends Node3D

var SPEED = 100

func _process(delta: float) -> void:
	var dir_x = Input.get_axis("left", "right")
	rotation.y += -dir_x * delta 
	var forward_direction = -basis.z 
	position += forward_direction * SPEED * delta
