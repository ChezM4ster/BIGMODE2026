class_name PlayerCar

extends Node3D

enum {
	DRIVE,
	DRIFT,
	AIR
}

var sphere_offset : Vector3 = Vector3.DOWN

@export var acceleration : float = 35.0

@export var steering : float = 10.0

@export var turn_speed : float = 4.0

@export var turn_stop_limit : float = 0.75

@export var body_tilt : float = 35.0

@onready var car_mesh : Node3D = $CarModel

@onready var car_body: MeshInstance3D = $CarModel/Cube_001

@onready var ground_ray: RayCast3D = $GroundRay

@onready var ball: RigidBody3D = $Ball


var speed_input : float = 0.0
var rotate_input : float = 0.0 

var car_state : int = DRIVE

func _physics_process(delta: float) -> void:
	car_mesh.transform.origin = ball.transform.origin
	ball.apply_central_force(-car_mesh.global_transform.basis.z * speed_input)

func _process(delta):
	
	speed_input = Input.get_axis("accelerate", "brake") * acceleration
	rotate_input = Input.get_axis("steer_right", "steer_left") * deg_to_rad(steering)
	
	camera_fov(delta)
	camera_tilt(delta)
	
	if ball.linear_velocity.length() > 0.75:
		rotate_car(delta)
	
	
	#state_updater()
	#match car_state:
		#DRIVE:
			#drive_state(delta)
		#DRIFT:
			#pass
		#AIR:
			#pass
	

func rotate_car(delta : float) -> void:
	var new_basis : Basis = car_mesh.global_transform.basis.rotated(car_mesh.global_transform.basis.y, rotate_input)
	car_mesh.global_transform.basis = car_mesh.global_transform.basis.slerp(new_basis, turn_speed * delta)
	car_mesh.global_transform = car_mesh.global_transform.orthonormalized()
	var t : float = -rotate_input * ball.linear_velocity.length() / body_tilt
	car_body.rotation.z = lerp(car_body.rotation.z, t, 10 * delta)




#region Camera Tilting and FOV methods

@export_category("Camera Juice")
@export var max_camera_tilt : float = 15.0    
@export var camera_tilt_speed : float = 6.0 
var current_tilt : float = 0.0

@export var base_fov : float = 70.0
@export var max_fov : float = 95.0
@export var fov_speed : float = 6.0      
@export var fov_max_speed : float = 45.0 

@onready var camera_rig: Node3D = $CarModel/CameraRig
@onready var camera: Camera3D = $CarModel/CameraRig/Camera3D

func camera_tilt(delta : float) -> void:
	# Rotates da camera...
	var speed_factor = clamp(ball.linear_velocity.length() / 40.0, 0.0, 1.0)
	var target_tilt = rotate_input * max_camera_tilt * speed_factor
	current_tilt = lerp(current_tilt, target_tilt, camera_tilt_speed * delta)
	

	camera_rig.rotation.z = deg_to_rad(current_tilt)

func camera_fov(delta : float) -> void:
	var speed = ball.linear_velocity.length()
	var speed_ratio = clamp(speed / fov_max_speed, 0.0, 1.0)
	speed_ratio = ease(speed_ratio, -1.5)

	var target_fov = lerp(base_fov, max_fov, speed_ratio)
	camera.fov = lerp(camera.fov, target_fov, fov_speed * delta)
#endregion
