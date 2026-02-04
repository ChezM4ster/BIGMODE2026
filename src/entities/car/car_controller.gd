class_name PlayerCar
extends Node
signal Explode

enum {
	DRIVE,
	DRIFT,
	AIR,
	LOCK
}
@export var ground_ray: RayCast3D 

@onready var car_mesh : Node3D = $CarModel
@onready var car_body: MeshInstance3D = $CarModel/Cube_001

@onready var ball: RigidBody3D = $Ball
@onready var efectsys : EfectSystem = $effectsSys
@onready var upgradesys : UpgradeSys = $UpgradeSys

@export var acceleration : float = 80.0
func get_acceleration() -> float : return acceleration * efectsys.get_speed_mult() * upgradesys.get_speed_mult()

@export var steering : float = 20.0
func get_steering() -> float : return steering * efectsys.get_stearing_mult() * upgradesys.get_stearing_mult()

@export var turn_speed : float = 6.0
@export var turn_stop_limit : float = 0.75
@export var body_tilt : float = 35.0
@export_category("Gravity")
@export var normal_gravity : float = 5.0 
@export var air_gravity : float = 10.0

var drift_direction : float = 0
var minimum_drift : bool = false
var boost : float = 1.0
var drift_boost : float = 1.75

var locked = false
var oily_rotate : float = 0.0

func kill_player():
	car_mesh.visible = false
	locked = true
	ball.freeze = true
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO

func revive_player():
	car_mesh.visible = true
	locked = false
	ball.position = Vector3.ZERO
	ball.freeze = false

func get_speed_input():
	return Input.get_axis("accelerate", "brake") * get_acceleration()

func get_rotation_input():
	var drift_bias : float = drift_direction * 2
	if get_player_state() == DRIFT:
		return (Input.get_axis("steer_right", "steer_left") * deg_to_rad(get_steering())) * 0.4 + drift_bias
	return Input.get_axis("steer_right", "steer_left") * deg_to_rad(get_steering())

func get_speed() -> Vector3:
	return car_mesh.global_transform.basis.z * get_speed_input() * boost

func _physics_process(_delta: float) -> void:
	car_mesh.transform.origin = ball.transform.origin
	if get_player_state() != AIR:
		ball.apply_central_force(get_speed())
	apply_gravity_logic()

func apply_gravity_logic() -> void:
	if get_player_state() == AIR:
		ball.gravity_scale = air_gravity
	else:
		ball.gravity_scale = normal_gravity

func _process(delta):
	$GroundRay.position = $CarModel.position
	state_updater(delta)
	align_mesh(delta)
	if ball.linear_velocity.length() > 0.75:
		handle_car_orientation(delta)

func get_player_state() -> int :
	if locked:
		return LOCK
	if ground_ray.is_colliding():
		if Input.is_action_just_pressed("drift") and Input.get_axis("steer_right", "steer_left") != 0 and get_speed_input() < 1:
			return DRIFT
		else:
			return DRIVE
	else:
		return AIR

func handle_car_orientation(delta: float) -> void:
	car_mesh.rotate_object_local(Vector3.UP, get_rotation_input() * turn_speed * delta)
	var lean_target : float = -get_rotation_input() * ball.linear_velocity.length() / body_tilt
	car_body.rotation.z = lerp(car_body.rotation.z, lean_target, 10 * delta)


func align_mesh(delta: float) -> void:
	if ground_ray.is_colliding():
		var normal = ground_ray.get_collision_normal()
		var mesh_tran = car_mesh.global_transform.basis
		var new_x = normal.cross(mesh_tran.z).normalized()
		var new_z = new_x.cross(normal).normalized()
		var target_basis = Basis(new_x, normal, new_z)
		car_mesh.global_basis = car_mesh.global_basis.slerp(target_basis, delta * 10.0).orthonormalized()
		var target_basis_ball = Basis(new_x, normal, new_z)
		ball.global_basis = ball.global_basis.slerp(target_basis_ball, delta * 10.0).orthonormalized()

func rotate_car(delta : float) -> void:
	var mesh_tran = car_mesh.global_transform
	var new_basis : Basis = mesh_tran.basis.rotated(mesh_tran.basis.y, get_rotation_input())
	mesh_tran.basis = mesh_tran.basis.slerp(new_basis, turn_speed * delta)
	mesh_tran = mesh_tran.orthonormalized()

#region Player state methods
func state_updater(delta : float) -> void:
	match get_player_state():
		DRIVE:
			drive_state(delta)
		DRIFT:
			drift_state(delta)
		AIR:
			air_state(delta)

func drive_state(_delta : float) -> void:
	if Input.is_action_just_pressed("drift") and get_rotation_input() != 0 and get_speed_input() < 0:
		start_drift()
	if Input.is_action_just_pressed("jump") and oily:
		jump()

func drift_state(_delta : float) -> void:
	if Input.is_action_just_released("drift") or get_speed_input() > 1:
		stop_drift()
	if Input.is_action_just_pressed("jump") and oily and ground_ray.is_colliding():
		jump()

func air_state(_delta : float) -> void:
	if can_air_dash and Input.is_action_just_pressed("drift"):
		air_dash()
#endregion


#region Oil related methods
var oily : bool = false

func enter_oil() -> void:
	oily = true
	efectsys.add("oily")
	print("Entered oil")

func exit_oil() -> void:
	oil_timer.start()

@export var jump_force : float = 800.0

func jump() -> void:
	ball.apply_central_force(Vector3.UP * jump_force)
	can_air_dash = true
	print("Jumping")

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
	print("Starting drift")
	minimum_drift = false
	drift_direction = get_rotation_input()
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
@onready var oil_timer: Timer = $Timers/OilTimer

func _on_drift_timer_timeout() -> void:
	if get_player_state() == DRIFT:
		minimum_drift = true

func _on_boost_timer_timeout() -> void:
	boost = 1.0
	print("Double boost...")

func _on_oil_timer_timeout() -> void:
	oily = false
	print("Oil over")

#endregion

func explode_car():
	Explode.emit()

func _on_collison_detetor_body_entered(body) -> void:
	if !body.is_in_group("car"):
		var crash_threshold = 15
		if ball.linear_velocity.length() > crash_threshold:
			explode_car()
