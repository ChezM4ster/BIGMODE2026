class_name PlayerCar

extends Node3D

enum {
	DRIVE,
	DRIFT,
	AIR
}

var sphere_offset : Vector3 = Vector3.DOWN

@export var acceleration : float = 70.0

@export var steering : float = 10.0

@export var turn_speed : float = 4.0

@export var turn_stop_limit : float = 0.75

@export var body_tilt : float = 35.0

@onready var car_mesh : Node3D = $CarModel

@onready var car_body: MeshInstance3D = $CarModel/Cube_001

@onready var ground_ray: RayCast3D = $GroundRay

@onready var ball: RigidBody3D = $Ball

var drift : bool = false
var drift_direction : float = 0
var minimum_drift : bool = false
var boost : float = 1.0
var drift_boost : float = 1.75


var speed_input : float = 0.0
var rotate_input : float = 0.0 

var car_state : int = DRIVE

func _physics_process(delta: float) -> void:
	car_mesh.transform.origin = ball.transform.origin
	ground_ray.transform.origin = ball.transform.origin
	ball.apply_central_force(-car_mesh.global_transform.basis.z * speed_input * boost)

func _process(delta : float):
	
	player_input(delta)
	state_updater(delta)
	camera_fov(delta)
	camera_tilt(delta)
	
	if ball.linear_velocity.length() > 0.75:
		rotate_car(delta)

func rotate_car(delta : float) -> void:
	var new_basis : Basis = car_mesh.global_transform.basis.rotated(car_mesh.global_transform.basis.y, rotate_input)
	car_mesh.global_transform.basis = car_mesh.global_transform.basis.slerp(new_basis, turn_speed * delta)
	car_mesh.global_transform = car_mesh.global_transform.orthonormalized()
	var t : float = -rotate_input * ball.linear_velocity.length() / body_tilt
	car_body.rotation.z = lerp(car_body.rotation.z, t, 10 * delta)

var oily_rotate : float = 0.0

func player_input(delta : float) -> void:
	speed_input = Input.get_axis("accelerate", "brake") * acceleration
	rotate_input = Input.get_axis("steer_right", "steer_left") * deg_to_rad(steering)
	

#region Player state methods
func state_updater(delta : float) -> void:
	
	match car_state:
		DRIVE:
			drive_state(delta)
		DRIFT:
			drift_state(delta)
		AIR:
			air_state(delta)

func drive_state(delta : float) -> void:
	
	## Will be used to check for air state
	if !ground_ray.is_colliding():
		car_state = AIR
	
	if Input.is_action_just_pressed("jump") and oily:
		jump()
	
	if Input.is_action_just_pressed("drift") and !drift and rotate_input != 0 and speed_input < 0:
		start_drift()
	
func drift_state(delta : float) -> void:
	
	var steer = Input.get_axis("steer_right", "steer_left")
	var drift_bias : float = drift_direction * 2
	rotate_input = (steer * deg_to_rad(steering)) * 0.4 + drift_bias
		
	if Input.is_action_just_released("drift") or speed_input > 1:
		stop_drift()
	
	if Input.is_action_just_pressed("jump") and oily and ground_ray.is_colliding():
		jump()

func air_state(delta : float) -> void:
	
	if ground_ray.is_colliding():
		car_state = DRIVE
		
	if can_air_dash and Input.is_action_just_pressed("drift"):
		air_dash()
#endregion

#region Camera Tilting and FOV methods

@export_category("Camera Juice")
@export var max_camera_tilt : float = 15.0    
@export var camera_tilt_speed : float = 6.0 
var current_tilt : float = 0.0
var current_offset : float = 0.0

@export var base_fov : float = 70.0
@export var max_fov : float = 95.0
@export var fov_speed : float = 6.0      
@export var fov_max_speed : float = 45.0 

@export_category("Drift Camera Juice")
@export var drift_camera_tilt : float = 80.0       
@export var drift_tilt_speed : float = 12.0         
@export var drift_camera_offset : float = 3.0      
@export var drift_offset_speed : float = 10.0

@onready var camera_rig: Node3D = $CarModel/CameraRig
@onready var camera: Camera3D = $CarModel/CameraRig/Camera3D

func camera_tilt(delta : float) -> void:
	# Rotates da camera...
	var target_tilt : float = 0.0
	var target_offset : float = 0.0
	var tilt_speed : float = camera_tilt_speed

	if car_state == DRIFT:
		target_tilt = drift_direction * drift_camera_tilt
		target_offset = drift_direction * drift_camera_offset
		tilt_speed = drift_tilt_speed
	else:
		target_tilt = rotate_input * max_camera_tilt

	current_tilt = lerp(current_tilt, target_tilt, tilt_speed * delta)
	current_offset = lerp(current_offset, target_offset, drift_offset_speed * delta)

	camera_rig.rotation.z = deg_to_rad(current_tilt)
	camera_rig.position.x = current_offset

func camera_fov(delta : float) -> void:
	var speed = ball.linear_velocity.length()
	var speed_ratio = clamp(speed / fov_max_speed, 0.0, 1.0)
	speed_ratio = ease(speed_ratio, -1.5)

	var target_fov = lerp(base_fov, max_fov, speed_ratio)
	camera.fov = lerp(camera.fov, target_fov, fov_speed * delta)
#endregion


#region Air dash variable

@export var air_dash_force : float = 30.0
@export var air_dash_cooldown : float = 0.0 

var can_air_dash : bool = true

func air_dash() -> void:
	var dir :float = Input.get_axis("steer_left", "steer_right")

	if dir == 0:
		return  

	var right : Vector3 = car_mesh.global_transform.basis.x
	ball.apply_central_impulse((-right * dir + Vector3.UP * 0.2).normalized() * air_dash_force)

	can_air_dash = false

#endregion


#region Drift methods
func start_drift() -> void:
	car_state = DRIFT
	print("Starting drift")
	minimum_drift = false
	drift_direction = rotate_input
	drift_timer.start()
	
func stop_drift() -> void:
	if minimum_drift:
		boost = drift_boost
		boost_timer.start()
		camera_rig.camera_shake()
		print("Boost timer started")
	car_state = DRIVE
	minimum_drift = false
	print("Stopping drift")
	
#endregion

#region Oil related methods
var oily : bool = false

func enter_oil() -> void:
	oily = true
	print("Entered oil")

func exit_oil() -> void:
	oil_timer.start()

@export var jump_force : float = 800.0

func jump() -> void:
	ball.apply_central_force(Vector3.UP * jump_force)
	can_air_dash = true
	print("Jumping")

#endregion

#region Timer related methods
@onready var drift_timer: Timer = $Timers/DriftTimer
@onready var boost_timer: Timer = $Timers/BoostTimer
@onready var oil_timer: Timer = $Timers/OilTimer

func _on_drift_timer_timeout() -> void:
	if car_state == DRIFT:
		minimum_drift = true

func _on_boost_timer_timeout() -> void:
	boost = 1.0
	print("Double boost...")
	
func _on_oil_timer_timeout() -> void:
	oily = false
	print("Oil over")

#endregion
