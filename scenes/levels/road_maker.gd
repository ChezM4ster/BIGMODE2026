extends Node

@onready var road_base_preload = preload("res://assets/models/obstacles/road_piece2.tscn")
@onready var road_base_with_wall_preload = preload("res://assets/models/obstacles/road_piece_with_wall.tscn")

@export var player : Node

@export var spawn_range_z: float = 850.0
@export var spawn_range_x: float = 50.0
  
var floor_size : Vector3i
var active_pieces: Array[Node3D] = []
var floor_position: Array[Vector3i] = []

func get_collision_size(collision_node: CollisionShape3D) -> Vector3i:
	var shape : Shape3D = collision_node.shape
	if shape is BoxShape3D:
		return shape.size * collision_node.scale
	elif shape is ConcavePolygonShape3D or shape is ConvexPolygonShape3D:
		return shape.get_debug_mesh().get_aabb().size * collision_node.scale
	push_warning("collision not found : wordgen" )
	return Vector3i.ZERO

func _ready() -> void:
	var temp_piece = road_base_preload.instantiate()
	if temp_piece.find_child("CollisionShape3D") != null:
		floor_size = get_collision_size(temp_piece.find_child("CollisionShape3D"))
	temp_piece.queue_free()


func spawn_tile(pos : Vector3i):
	var new_tile = [road_base_preload ,road_base_with_wall_preload].pick_random().instantiate()
	add_child(new_tile)
	new_tile.global_position = pos
	active_pieces.append(new_tile)

func filter_unspawned(arr :Array[Vector3i]) -> Array[Vector3i]:
	return arr.filter(func(pos : Vector3i): return active_pieces.find_custom(func(obj : Node3D): return Vector3i(obj.global_position) == pos) == -1)

func filter_out_of_range(arr :Array[Vector3i] , target : Vector3i , range_x : float , range_z : float) -> Array[Vector3i]:
	return arr.filter(func(pos : Vector3i) : return abs(target.x - pos.x) < range_x  and abs(target.z - pos.z) < range_z)

func filter_in_range(arr :Array[Vector3i] , target : Vector3i , range_x : float , range_z : float) -> Array[Vector3i]:
	return arr.filter(func(pos : Vector3i) : return abs(target.x - pos.x) > range_x  and abs(target.z - pos.z) > range_z)

func filter_in_range_node(arr :Array[Node3D] , target : Vector3i , range_x : float , range_z : float) -> Array[Node3D]:
	return arr.filter(func(nod : Node3D) : return abs(target.x - nod.global_position.x) > range_x  and abs(target.z - nod.global_position.z) > range_z)

func filter_out_range_node(arr :Array[Node3D] , target : Vector3i , range_x : float , range_z : float) -> Array[Node3D]:
	return arr.filter(func(nod : Node3D) : return abs(target.x - nod.global_position.x) < range_x  and abs(target.z - nod.global_position.z) < range_z)

func cleanup_tiles(target : Vector3i, range_x : float , range_z : float) -> void:
	for piece in filter_in_range_node(active_pieces , target , range_x , range_z):
		active_pieces.erase(piece)
		piece.queue_free()

func get_grid_position(target: Vector3i) -> Vector3i:
	if floor_size == Vector3i.ZERO: return Vector3i.ZERO
	var snapped_pos = target.snapped(floor_size)
	snapped_pos.y = 0 
	return snapped_pos

func get_all_grid_positions_in_range(target: Vector3i, tile_range: int) -> Array[Vector3i]:
	var positions: Array[Vector3i] = []
	if floor_size.x == 0 or floor_size.z == 0:
		return []
	var center = get_grid_position(target)
	for z in range( -tile_range, tile_range ):
		var world_pos = center + Vector3i(0, 0, z * floor_size.z)
		positions.append(world_pos)
	return positions

func _process(_delta: float) -> void:
	update_grid()

func update_grid() -> void:
	var player_position = player.ball.global_position 
	var pos_to_spawn_grid : Array[Vector3i] = get_all_grid_positions_in_range(player_position , 10 )
	pos_to_spawn_grid = filter_unspawned(pos_to_spawn_grid)
	pos_to_spawn_grid = filter_out_of_range(pos_to_spawn_grid , player_position , spawn_range_x , spawn_range_z)
	
	for pos in pos_to_spawn_grid:
		spawn_tile(pos)
	
	cleanup_tiles(player_position , spawn_range_x ,spawn_range_z)
