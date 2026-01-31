extends Node3D

@onready var camera_3d: Camera3D = $Camera3D


@export var period = 0.1
@export var magnitude = 0.05

func camera_shake():
	var initial_transform = camera_3d.transform 
	var elapsed_time = 0.0

	while elapsed_time < period:
		var offset = Vector3(
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude),
			0.0
		)

		camera_3d.transform.origin = initial_transform.origin + offset
		elapsed_time += get_process_delta_time()
		await get_tree().process_frame

	camera_3d.transform = initial_transform
