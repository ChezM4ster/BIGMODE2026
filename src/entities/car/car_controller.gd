class_name PlayerCar
extends Node
signal Explode

enum {
	DRIVE,
	DRIFT,
	AIR,
	LOCK
}

@onready var car_mesh : Node3D = $CarModel
@onready var car_body: MeshInstance3D = $CarModel/Cube_001
@onready var ground_ray: RayCast3D = $Ball/GroundRay
@onready var ball: RigidBody3D = $Ball

var sphere_offset : Vector3 = Vector3.DOWN

@export var acceleration : float = 80.0
@export var steering : float = 20.0
@export var turn_speed : float = 6.0
@export var turn_stop_limit : float = 0.75
@export var body_tilt : float = 35.0


@export_category("Gravity")
@export var normal_gravity : float = 5.0 
@export var air_gravity : float = 10.0
var drift : bool = false
var drift_direction : float = 0
var minimum_drift : bool = false
var boost : float = 1.0
var drift_boost : float = 1.75
var speed_input : float = 0.0
var rotate_input : float = 0.0 

var locked = false

func kill_player():
	car_mesh.visible = false
	locked = true


func revive_player():
	car_mesh.visible = true
	locked = false
	ball.position = Vector3.ZERO
	
func _physics_process(delta: float) -> void:
	car_mesh.transform.origin = ball.transform.origin
	if get_player_state() != AIR:
		ball.apply_central_force(-car_mesh.global_transform.basis.z * speed_input * boost)
	apply_gravity_logic()

func apply_gravity_logic() -> void:
	if get_player_state() == AIR:
		ball.gravity_scale = air_gravity
	else:
		ball.gravity_scale = normal_gravity

func _process(delta):
	player_input()
	state_updater(delta)
	align_mesh(delta)
	if ball.linear_velocity.length() > 0.75:
		handle_car_orientation(delta)

func get_player_state() -> int :
	if locked:
		return LOCK
	
	if ground_ray.is_colliding():
		if Input.is_action_just_pressed("drift") and !drift and rotate_input != 0 and speed_input < 0 and speed_input < 1:
			return DRIFT
		else:
			return DRIVE
	else:
		return AIR

func handle_car_orientation(delta: float) -> void:
	car_mesh.rotate_object_local(Vector3.UP, rotate_input * turn_speed * delta)
	var lean_target : float = -rotate_input * ball.linear_velocity.length() / body_tilt
	car_body.rotation.z = lerp(car_body.rotation.z, lean_target, 10 * delta)

func align_mesh(delta: float) -> void:
	if ground_ray.is_colliding():
		var normal = ground_ray.get_collision_normal()
		var mesh_tran = car_mesh.global_transform.basis
		var new_x = normal.cross(mesh_tran.z).normalized()
		var new_z = new_x.cross(normal).normalized()
		var target_basis = Basis(new_x, normal, new_z)
		car_mesh.global_basis = car_mesh.global_basis.slerp(target_basis, delta * 10.0).orthonormalized()

func rotate_car(delta : float) -> void:
	var mesh_tran = car_mesh.global_transform
	var new_basis : Basis = mesh_tran.basis.rotated(mesh_tran.basis.y, rotate_input)
	mesh_tran.basis = mesh_tran.basis.slerp(new_basis, turn_speed * delta)
	mesh_tran = mesh_tran.orthonormalized()

func player_input() -> void:
	speed_input = Input.get_axis("accelerate", "brake") * acceleration
	rotate_input = Input.get_axis("steer_right", "steer_left") * deg_to_rad(steering)

#region Player state methods
func state_updater(delta : float) -> void:
	match get_player_state():
		DRIVE:
			drive_state(delta)
		DRIFT:
			drift_state(delta)
		AIR:
			pass

func drive_state(delta : float) -> void:
	if Input.is_action_just_pressed("drift") and !drift and rotate_input != 0 and speed_input < 0:
		start_drift()
	
func drift_state(delta : float) -> void:
	var steer = Input.get_axis("steer_right", "steer_left")
	var drift_bias : float = drift_direction * 2
	rotate_input = (steer * deg_to_rad(steering)) * 0.4 + drift_bias
	if Input.is_action_just_released("drift") or speed_input > 1:
		stop_drift()

#endregion

#region Drift methods
func start_drift() -> void:
	print("Starting drift")
	minimum_drift = false
	drift_direction = rotate_input
	drift_timer.start()
	
func stop_drift() -> void:
	if minimum_drift:
		boost = drift_boost
		boost_timer.start()
		#camera_rig.camera_shake()
		print("Boost timer started")
	minimum_drift = false
	print("Stopping drift")
	
#endregion

#region Timer related methods
@onready var drift_timer: Timer = $Timers/DriftTimer
@onready var boost_timer: Timer = $Timers/BoostTimer

func _on_drift_timer_timeout() -> void:
	if get_player_state() == DRIFT:
		minimum_drift = true

func _on_boost_timer_timeout() -> void:
	boost = 1.0
	print("Double boost...")
	
#endregion

func explode_car():
	Explode.emit()

func _on_collison_detetor_body_entered(body: Node3D) -> void:
	var crash_threshold = 15
	if ball.linear_velocity.length() > crash_threshold:
		explode_car()
	
