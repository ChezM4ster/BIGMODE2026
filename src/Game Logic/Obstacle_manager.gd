extends Node3D
class_name ObstacleManager

#enum ObstacleType { SLOWDOWN, OIL, EXPLOSIVES, POINTS_ONLY }

@export_category("References")
@export var player: Node3D
## These areas are cylinders because they're circles basically
@export var spawn_area: Area3D
@export var despawn_area: Area3D
@export var road_collision_mask: int = 1 # set to the mask your road uses

@export_category("Spawning")
##how many obstacles allowed at once
@export var target_active_count: int = 40
## The radius around the player obstacles are allowed to spawn
@export var spawn_radius: float = 40.0
## The radius obstacles are allowed to exist in
@export var despawn_radius: float = 60.0
## Radius obstacles are NOT allowed to spawn (in near the player)
@export var safe_radius: float = 10.0
## Min distance between obstacles
@export var min_spacing: float = 6.0
## How many time an obstacle is allowed to try and spawn
@export var max_spawn_attempts_per_obstacle: int = 25
## Distance above the player so that obstacles can check down to the gorund to see if they can spawn there
@export var spawn_height_above_player: float = 25.0
## pulls obstacle off the ground
@export var surface_offset: float = 0.1

@export_category("Timing")
## How often spawns can occur for CPU's sake
@export var tick_rate_hz: float = 6.0 # despawn and refill frequency

@export_category("Obstacle Scenes")
## all the obstacles TODO either replace with arrays or have each obstacle choose what it looks like and its stats on spawn
@export var slowdown_scene: PackedScene
@export var oil_scene: PackedScene
@export var explosives_scene: PackedScene
@export var points_only_scene: PackedScene

@export_category("Pools")
## number of obstacles in pool
@export var pool_slowdown: int = 25
@export var pool_oil: int = 25
@export var pool_explosives: int = 25
@export var pool_points_only: int = 25

@export_category("Spawn Weights")
## weights for obstacle spawn chances
@export var w_slowdown: float = 1.0
@export var w_oil: float = 1.0
@export var w_explosives: float = 1.0
@export var w_points_only: float = 2.0

##cool thing I found that makes random numbers
var _rng := RandomNumberGenerator.new()

## Currently active objects
var _active: Array[Node3D] = []

## Arrays of inactive obstacles
var _pool: Dictionary = {}

## Spatial grid for spacing checks
var _grid: Dictionary = {} # key: Vector2i -> Array[Node3D]
##min spacing for obstacles
var _cell_size: float

## Things for tickrate
var _timer_accum: float = 0.0
var _tick_interval: float = 0.0

func _ready() -> void:
	if (despawn_area != null):
		despawn_area.body_exited.connect(_on_despawn_area_body_exited)
		despawn_area.area_exited.connect(_on_despawn_area_area_exited)

	_rng.randomize()
	##Initial spawn prep
	_cell_size = max(min_spacing, 0.001)
	_tick_interval = 1.0 / max(tick_rate_hz, 0.1)

	_init_pools()

	# Initial spawn burst
	_refill_to_target()

func _process(delta: float) -> void:
	if player == null:
		return

	_timer_accum += delta
	if _timer_accum < _tick_interval:
		return
	_timer_accum = 0.0

	# No distance scan anymore. Just keep population topped up.
	_refill_to_target()

func _init_pools() -> void:
	_pool.clear()

	_pool[RoadObstacle.ObstacleType.SLOWDOWN] = _build_pool(slowdown_scene, pool_slowdown, RoadObstacle.ObstacleType.SLOWDOWN)
	_pool[RoadObstacle.ObstacleType.OIL] = _build_pool(oil_scene, pool_oil, RoadObstacle.ObstacleType.OIL)
	_pool[RoadObstacle.ObstacleType.EXPLOSIVES] = _build_pool(explosives_scene, pool_explosives, RoadObstacle.ObstacleType.EXPLOSIVES)
	_pool[RoadObstacle.ObstacleType.POINTS_ONLY] = _build_pool(points_only_scene, pool_points_only, RoadObstacle.ObstacleType.POINTS_ONLY)

func _build_pool(scene: PackedScene, count: int, t: int) -> Array:
	var arr: Array = []
	if scene == null:
		push_warning("Missing PackedScene for type: " + str(t))
		return arr

	for i in range(count):
		var inst := scene.instantiate() as Node3D
		add_child(inst)
		_deactivate_obstacle(inst)
		_bind_obstacle(inst, t)
		arr.append(inst)

	return arr

func _bind_obstacle(obstacle: Node3D, t: RoadObstacle.ObstacleType) -> void:
	var ro := obstacle as RoadObstacle
	if ro == null:
		push_warning("Obstacle root is not RoadObstacle: " + obstacle.name)
		return

	ro.obstacle_type = t
	ro.hit.connect(_on_obstacle_hit)



func _refill_to_target() -> void:
	if _active.size() >= target_active_count:
		return

	var needed := target_active_count - _active.size()

	for i in range(needed):
		if not _try_spawn_one():
			break

func _try_spawn_one() -> bool:
	var t := _pick_type_by_weight()
	var obs := _take_from_pool(t)
	if obs == null:
		return false

	var placed := false

	for a in range(max_spawn_attempts_per_obstacle):
		var candidate_from_above := _random_point_in_spawn_area_above_player()
		var hit := _raycast_to_road(candidate_from_above)
		if hit.is_empty():
			continue

		var pos: Vector3 = hit.position
		pos.y += surface_offset

		if _too_close_to_existing(pos):
			continue

		_activate_obstacle(obs, pos)
		_register_active(obs)
		placed = true
		break

	if not placed:
		_return_to_pool(t, obs)

	return placed

func _pick_type_by_weight() -> int:
	var total = max(w_slowdown, 0.0) + max(w_oil, 0.0) + max(w_explosives, 0.0) + max(w_points_only, 0.0)
	if total <= 0.0:
		return RoadObstacle.ObstacleType.POINTS_ONLY

	var r = _rng.randf() * total
	r -= max(w_slowdown, 0.0)
	if r <= 0.0:
		return RoadObstacle.ObstacleType.SLOWDOWN
	r -= max(w_oil, 0.0)
	if r <= 0.0:
		return RoadObstacle.ObstacleType.OIL
	r -= max(w_explosives, 0.0)
	if r <= 0.0:
		return RoadObstacle.ObstacleType.EXPLOSIVES
	return RoadObstacle.ObstacleType.POINTS_ONLY

func _take_from_pool(t: int) -> Node3D:
	if not _pool.has(t):
		return null
	var arr: Array = _pool[t]
	if arr.is_empty():
		return null
	return arr.pop_back() as Node3D

func _return_to_pool(t: int, obs: Node3D) -> void:
	_deactivate_obstacle(obs)
	if not _pool.has(t):
		_pool[t] = []
	(_pool[t] as Array).append(obs)

func _get_spawn_cylinder_radius() -> float:
	return max(spawn_radius, safe_radius + 0.001)


func _random_point_in_spawn_area_above_player() -> Vector3:
	var spawn_r := _get_spawn_cylinder_radius()
	var r0 = max(safe_radius, 0.0)
	var r1 = max(spawn_r, r0 + 0.001)

	var angle := _rng.randf() * TAU
	var u := _rng.randf()
	var radius := sqrt(lerp(r0 * r0, r1 * r1, u))

	## Spawn area assumed centered on player (or attached to player).
	## Use player position as center.
	var offset := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
	return player.global_position + offset + Vector3.UP * spawn_height_above_player

func _raycast_to_road(from_pos: Vector3) -> Dictionary:
	var to_pos := from_pos + Vector3.DOWN * (spawn_height_above_player * 2.0 + 200.0)

	var params := PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	params.collision_mask = road_collision_mask
	params.hit_back_faces = true
	params.hit_from_inside = true

	return get_world_3d().direct_space_state.intersect_ray(params)

func _activate_obstacle(obs: Node3D, pos: Vector3) -> void:
	obs.global_position = pos
	obs.visible = true

	if obs is CollisionObject3D:
		var co := obs as CollisionObject3D
		co.set_deferred("disabled", false)

	if obs is RigidBody3D:
		var rb := obs as RigidBody3D
		rb.freeze = true
		rb.sleeping = true

	if obs.has_method("on_spawned"):
		obs.call("on_spawned")

func _deactivate_obstacle(obs: Node3D) -> void:
	if obs.has_method("on_despawned"):
		obs.call("on_despawned")

	obs.visible = false

	if obs is CollisionObject3D:
		var co := obs as CollisionObject3D
		co.set_deferred("disabled", true)

	if obs is RigidBody3D:
		var rb := obs as RigidBody3D
		rb.freeze = true
		rb.sleeping = true

func _register_active(obs: Node3D) -> void:
	_active.append(obs)
	_add_to_grid(obs)

func _unregister_active(obs: Node3D) -> void:
	var idx := _active.find(obs)
	if idx != -1:
		_active.remove_at(idx)
	_remove_from_grid(obs)

func _cell_key(pos: Vector3) -> Vector2i:
	return Vector2i(int(floor(pos.x / _cell_size)), int(floor(pos.z / _cell_size)))

func _add_to_grid(obs: Node3D) -> void:
	var key := _cell_key(obs.global_position)
	if not _grid.has(key):
		_grid[key] = []
	(_grid[key] as Array).append(obs)

func _remove_from_grid(obs: Node3D) -> void:
	var key := _cell_key(obs.global_position)
	if not _grid.has(key):
		return
	var arr: Array = _grid[key]
	var i := arr.find(obs)
	if i != -1:
		arr.remove_at(i)
	if arr.is_empty():
		_grid.erase(key)

func _too_close_to_existing(pos: Vector3) -> bool:
	var key := _cell_key(pos)
	var min_d2 := min_spacing * min_spacing

	for oy in range(-1, 2):
		for ox in range(-1, 2):
			var k := Vector2i(key.x + ox, key.y + oy)
			if not _grid.has(k):
				continue
			var arr: Array = _grid[k]
			for obs in arr:
				var o := obs as Node3D
				var op := o.global_position
				var dx := op.x - pos.x
				var dz := op.z - pos.z
				var d2 := dx * dx + dz * dz
				if d2 < min_d2:
					return true

	return false

func _on_obstacle_hit(obstacle: Node3D) -> void:
	if obstacle == null:
		return
	_despawn_obstacle(obstacle)

func _despawn_obstacle(obs: Node3D) -> void:
	_unregister_active(obs)

	var t = RoadObstacle.ObstacleType.POINTS_ONLY
	if (obs is RoadObstacle):
		t = obs.get("obstacle_type") as RoadObstacle.ObstacleType

	_return_to_pool(t, obs)

# Event driven despawn: when an obstacle leaves the outer cylinder
func _on_despawn_area_body_exited(body: Node3D) -> void:
	if body == null:
		return
	if _active.has(body):
		_despawn_obstacle(body)

func _on_despawn_area_area_exited(area: Area3D) -> void:
	if area == null:
		return
	# If your obstacle uses an Area3D child as its collider, it might be the one exiting.
	# Walk up to find a parent that is one of our active obstacles.
	var n: Node = area
	while n != null and n != self:
		if n is Node3D and _active.has(n):
			_despawn_obstacle(n as Node3D)
			return
		n = n.get_parent()
