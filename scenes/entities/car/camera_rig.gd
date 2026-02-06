extends Node3D

@onready var camera_3d: Camera3D = $Camera3D

func camera_shake(period : float = 0.1, magnitude : float = 0.05):
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

func freeze_frame(time_scale : float, duration : float) -> void:
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
