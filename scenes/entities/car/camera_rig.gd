extends SpringArm3D


@export var car: PlayerCar
@onready var camera: Camera3D = $Camera3D
@export var ball: Node3D
@export var pivot : Node3D

@export var period = 0.1
@export var magnitude = 0.05

@export_category("Camera Juice")
@export var max_camera_tilt: float = 15.0
@export var camera_tilt_speed: float = 6.0
var current_tilt: float = 0.0
var current_offset: float = 0.0

@export var base_fov: float = 70.0
@export var max_fov: float = 95.0
@export var fov_speed: float = 6.0
@export var fov_max_speed: float = 45.0

@export_category("Drift Camera Juice")
@export var drift_camera_tilt: float = 80.0
@export var drift_tilt_speed: float = 12.0
@export var drift_camera_offset: float = 3.0
@export var drift_offset_speed: float = 10.0

func get_camera_fov(delta: float) -> float:
	var speed = car.get_speed().length()
	var speed_ratio = clamp(speed / fov_max_speed, 0.0, 1.0)
	speed_ratio = ease(speed_ratio, -1.5)
	var target_fov = lerp(base_fov, max_fov, speed_ratio)
	return lerp(camera.fov, target_fov, fov_speed * delta)

func get_camera_tilt(delta: float) -> float:
	var target_tilt: float = 0.0
	var target_offset: float = 0.0
	var tilt_speed: float = camera_tilt_speed
	if car.get_player_state() == car.DRIFT:
		target_tilt = car.drift_direction * drift_camera_tilt
		target_offset = car.drift_direction * drift_camera_offset
		tilt_speed = drift_tilt_speed
	else:
		target_tilt = car.get_rotation_input() * max_camera_tilt
	current_tilt = lerp(current_tilt, target_tilt, tilt_speed * delta)
	current_offset = lerp(current_offset, target_offset, drift_offset_speed * delta)
	return deg_to_rad(current_tilt)

func _process(delta: float) -> void:
	pivot.global_position = ball.global_position
	pivot.rotation.y = lerp_angle(pivot.rotation.y, ball.rotation.y, delta * 1.5)
	camera.fov = get_camera_fov(delta)
	rotation.z = get_camera_tilt(delta)

func camera_shake():
	var initial_transform = camera.transform
	var elapsed_time = 0.0
	while elapsed_time < period:
		var offset = Vector3(
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude),
			0.0
		)
		camera.transform.origin = initial_transform.origin + offset
		elapsed_time += get_process_delta_time()
		await get_tree().process_frame

	camera.transform = initial_transform
